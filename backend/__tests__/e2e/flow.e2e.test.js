/**
 * End-to-end scenario tests — full user flows through the HTTP API.
 * DB is mocked; tests verify the complete request → response chain
 * including auth middleware, role guards, and controller logic.
 */
jest.mock('../../src/config/db');
jest.mock('bcryptjs');
jest.mock('jsonwebtoken');

const db = require('../../src/config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const app = require('../../app');
const { invalidateEmbeddingCache } = require('../../src/controllers/absensiController');

process.env.JWT_SECRET = 'test_secret';

const unitVec = (dim) => { const v = new Array(192).fill(0); v[dim] = 1.0; return v; };

// Shared token state across scenario steps
let adminToken, guruToken, siswaToken;

// jwt.sign returns predictable tokens; jwt.verify decodes them
jwt.sign.mockImplementation((payload) => {
  if (payload.role === 'admin') return 'admin_token';
  if (payload.role === 'guru')  return 'guru_token';
  if (payload.role === 'siswa') return 'siswa_token';
});
jwt.verify.mockImplementation((token) => {
  if (token === 'admin_token') return { id: 1, role: 'admin', extraId: null };
  if (token === 'guru_token')  return { id: 2, role: 'guru',  extraId: 1 };
  if (token === 'siswa_token') return { id: 5, role: 'siswa', extraId: 3 };
  throw new Error('invalid token');
});

beforeEach(() => {
  jest.clearAllMocks();
  // clearAllMocks keeps unconsumed mockResolvedValueOnce values; reset db.query so they
  // can't leak into the next step. jwt/bcrypt keep their implementations above.
  db.query.mockReset();
  invalidateEmbeddingCache();
  adminToken = 'admin_token';
  guruToken  = 'guru_token';
  siswaToken = 'siswa_token';
});

// ─── Scenario 1: Admin login ──────────────────────────────────────────────────
describe('Scenario 1 — Admin login flow', () => {
  test('Step 1: admin logs in successfully', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_user: 1, username: 'admin', password: 'h', role: 'admin', status: 'aktif' }]])
      .mockResolvedValueOnce([[{ nama: 'Administrator' }]]);
    bcrypt.compare.mockResolvedValueOnce(true);

    const res = await request(app).post('/api/auth/login').send({ username: 'admin', password: 'admin123' });

    expect(res.status).toBe(200);
    expect(res.body.data.role).toBe('admin');
    expect(res.body.data.token).toBe('admin_token');
  });

  test('Step 2: admin can access siswa list', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Budi', NIS: '001' }]])
      .mockResolvedValueOnce([[{ total: 1 }]]);

    const res = await request(app)
      .get('/api/siswa')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
  });
});

// ─── Scenario 2: Face registration ───────────────────────────────────────────
describe('Scenario 2 — Admin registers student face', () => {
  const embedding = unitVec(0);

  test('Step 1: admin registers face for student ID 1', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1 }]])       // find siswa
      .mockResolvedValueOnce([{ affectedRows: 1 }]);    // update data_wajah

    const res = await request(app)
      .post('/api/siswa/1/wajah')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ embedding });

    expect(res.status).toBe(200);
    expect(res.body.message).toContain('berhasil');
  });

  test('Step 2: rejects invalid embedding (wrong length)', async () => {
    const res = await request(app)
      .post('/api/siswa/1/wajah')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ embedding: [1, 2, 3] });

    expect(res.status).toBe(400);
  });
});

// ─── Scenario 3: Siswa absensi flow ──────────────────────────────────────────
describe('Scenario 3 — Siswa absensi flow', () => {
  const stored = unitVec(0);
  const incomingEmbedding = unitVec(0); // identical → similarity 1.0

  test('Step 1: siswa submits face, gets recognized and marked hadir', async () => {
    db.query
      .mockResolvedValueOnce([[]])                     // geofence not configured
      .mockResolvedValueOnce([[{ id_siswa: 3, nama_siswa: 'Budi', NIS: '001', kelas: 'XI', jurusan: 'TKJ', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[{ id_jadwal: 1, mata_pelajaran: 'Matematika', jam_mulai: '00:00:00' }]])
      .mockResolvedValueOnce([{ affectedRows: 1, insertId: 15 }]); // INSERT IGNORE succeeded

    const res = await request(app)
      .post('/api/absensi/recognize')
      .set('Authorization', `Bearer ${siswaToken}`)
      .send({ embedding: incomingEmbedding });

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({ nama_siswa: 'Budi', status: 'hadir' });
  });

  test('Step 2: siswa cannot absen twice on the same day', async () => {
    db.query
      .mockResolvedValueOnce([[]])                     // geofence not configured
      .mockResolvedValueOnce([[{ id_siswa: 3, nama_siswa: 'Budi', NIS: '001', kelas: 'XI', jurusan: 'TKJ', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[{ id_jadwal: 1, mata_pelajaran: 'Matematika', jam_mulai: '00:00:00' }]])
      .mockResolvedValueOnce([{ affectedRows: 0 }]);   // INSERT IGNORE skipped → already recorded

    const res = await request(app)
      .post('/api/absensi/recognize')
      .set('Authorization', `Bearer ${siswaToken}`)
      .send({ embedding: incomingEmbedding });

    expect(res.status).toBe(409);
  });

  test('Step 3: siswa views their own riwayat', async () => {
    db.query.mockResolvedValueOnce([[
      { id_absensi: 15, nama_siswa: 'Budi', NIS: '001', tanggal: '2026-07-09', waktu: '07:30:00', status: 'hadir' },
    ]]);

    const res = await request(app)
      .get('/api/absensi/siswa/3')
      .set('Authorization', `Bearer ${siswaToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].status).toBe('hadir');
  });
});

// ─── Scenario 4: Guru approves izin ──────────────────────────────────────────
describe('Scenario 4 — Guru views absensi and manages izin', () => {
  test('Step 1: guru views absensi for today', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_absensi: 1, nama_siswa: 'Budi', status: 'hadir', waktu: '07:30:00' }]])
      .mockResolvedValueOnce([[{ total: 1 }]])
      .mockResolvedValueOnce([[{ hadir: 1, izin: 0, tidak_hadir: 0 }]]);

    const res = await request(app)
      .get('/api/absensi?tanggal=2026-07-09')
      .set('Authorization', `Bearer ${guruToken}`);

    expect(res.status).toBe(200);
    expect(res.body.hadir).toBe(1);
  });

  test('Step 2: guru views pending izin list', async () => {
    db.query.mockResolvedValueOnce([[{ id_izin: 1, nama_siswa: 'Andi', jenis: 'sakit', status: 'pending' }]]);

    const res = await request(app)
      .get('/api/izin')
      .set('Authorization', `Bearer ${guruToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].status).toBe('pending');
  });

  test('Step 3: guru approves izin → absensi status updated to izin', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 2, tanggal: '2026-07-10' }]])  // find izin
      .mockResolvedValueOnce([{ affectedRows: 1 }])                        // update izin status
      .mockResolvedValueOnce([[{ id_absensi: 20 }]])                       // existing absensi
      .mockResolvedValueOnce([{ affectedRows: 1 }]);                       // update absensi to izin

    const res = await request(app)
      .put('/api/izin/1/status')
      .set('Authorization', `Bearer ${guruToken}`)
      .send({ status: 'approved' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('Step 4: guru downloads PDF report', async () => {
    db.query.mockResolvedValueOnce([[
      { nama_siswa: 'Budi', NIS: '001', kelas: 'XI TJKT', waktu: '07:30:00', status: 'hadir' },
      { nama_siswa: 'Andi', NIS: '002', kelas: 'XI TJKT', waktu: '-', status: 'izin' },
    ]]);

    const res = await request(app)
      .get('/api/absensi/laporan/pdf?tanggal=2026-07-09')
      .set('Authorization', `Bearer ${guruToken}`);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.headers['content-disposition']).toContain('laporan_absensi_2026-07-09.pdf');
  });
});

// ─── Scenario 5: Role guard enforcement ──────────────────────────────────────
describe('Scenario 5 — Role guard enforcement', () => {
  test('siswa cannot access GET /api/absensi (guru/admin only)', async () => {
    const res = await request(app)
      .get('/api/absensi')
      .set('Authorization', `Bearer ${siswaToken}`);
    expect(res.status).toBe(403);
  });

  test('guru cannot register siswa face (admin only)', async () => {
    const res = await request(app)
      .post('/api/siswa/1/wajah')
      .set('Authorization', `Bearer ${guruToken}`)
      .send({ embedding: unitVec(0) });
    expect(res.status).toBe(403);
  });

  test('unauthenticated request returns 401', async () => {
    const res = await request(app).get('/api/siswa');
    expect(res.status).toBe(401);
  });
});

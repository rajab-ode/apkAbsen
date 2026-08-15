jest.mock('../../src/config/db');
jest.mock('jsonwebtoken');

const db = require('../../src/config/db');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const app = require('../../app');

process.env.JWT_SECRET = 'test_secret';

const unitVec = (dim) => { const v = new Array(128).fill(0); v[dim] = 1.0; return v; };

// JWT verify mock: return payload matching the Authorization header value
jwt.verify.mockImplementation((token) => {
  if (token === 'siswa_token') return { id: 5, role: 'siswa', extraId: 3 };
  if (token === 'guru_token')  return { id: 2, role: 'guru',  extraId: 1 };
  if (token === 'admin_token') return { id: 1, role: 'admin', extraId: null };
  throw new Error('invalid');
});

beforeEach(() => jest.clearAllMocks());

const authHeader = (token) => ({ Authorization: `Bearer ${token}` });

describe('POST /api/absensi/recognize', () => {
  test('returns 401 without auth header', async () => {
    const res = await request(app).post('/api/absensi/recognize').send({ embedding: unitVec(0) });
    expect(res.status).toBe(401);
  });

  test('returns 403 when role is not siswa', async () => {
    const res = await request(app)
      .post('/api/absensi/recognize')
      .set(authHeader('guru_token'))
      .send({ embedding: unitVec(0) });
    expect(res.status).toBe(403);
  });

  test('returns 400 when embedding missing', async () => {
    const res = await request(app)
      .post('/api/absensi/recognize')
      .set(authHeader('siswa_token'))
      .send({});
    expect(res.status).toBe(400);
  });

  test('returns 201 on successful recognition', async () => {
    const stored = unitVec(0);
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 3, nama_siswa: 'Andi', NIS: '001', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[]])
      .mockResolvedValueOnce([{ insertId: 10 }]);

    const res = await request(app)
      .post('/api/absensi/recognize')
      .set(authHeader('siswa_token'))
      .send({ embedding: unitVec(0) });

    expect(res.status).toBe(201);
    expect(res.body.data.nama_siswa).toBe('Andi');
  });
});

describe('GET /api/absensi', () => {
  test('returns 403 when role is siswa', async () => {
    const res = await request(app)
      .get('/api/absensi')
      .set(authHeader('siswa_token'));
    expect(res.status).toBe(403);
  });

  test('returns 200 with absensi list for guru', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_absensi: 1, nama_siswa: 'Andi', status: 'hadir', waktu: '07:30:00' }]])
      .mockResolvedValueOnce([[{ total: 1 }]])
      .mockResolvedValueOnce([[{ hadir: 1, izin: 0, tidak_hadir: 0 }]]);

    const res = await request(app)
      .get('/api/absensi?tanggal=2026-07-09')
      .set(authHeader('guru_token'));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.hadir).toBe(1);
  });
});

describe('GET /api/absensi/laporan/pdf', () => {
  test('returns 400 without tanggal param', async () => {
    const res = await request(app)
      .get('/api/absensi/laporan/pdf')
      .set(authHeader('guru_token'));
    expect(res.status).toBe(400);
  });

  test('returns PDF content for valid request', async () => {
    db.query.mockResolvedValueOnce([[
      { nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', waktu: '07:30:00', status: 'hadir' },
    ]]);
    const res = await request(app)
      .get('/api/absensi/laporan/pdf?tanggal=2026-07-09')
      .set(authHeader('guru_token'));
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('application/pdf');
  });
});

describe('GET /api/absensi/laporan/excel', () => {
  test('returns 400 without tanggal param', async () => {
    const res = await request(app)
      .get('/api/absensi/laporan/excel')
      .set(authHeader('guru_token'));
    expect(res.status).toBe(400);
  });

  test('returns Excel content for valid request', async () => {
    db.query.mockResolvedValueOnce([[
      { nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', jurusan: 'TKJ', waktu: '07:30:00', status: 'hadir' },
    ]]);
    const res = await request(app)
      .get('/api/absensi/laporan/excel?tanggal=2026-07-09')
      .set(authHeader('guru_token'));
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('spreadsheetml');
  });
});

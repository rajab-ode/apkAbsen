jest.mock('../../src/config/db');
jest.mock('jsonwebtoken');

const db = require('../../src/config/db');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const path = require('path');
const fs = require('fs');
const app = require('../../app');

process.env.JWT_SECRET = 'test_secret';

jwt.verify.mockImplementation((token) => {
  if (token === 'siswa_token') return { id: 5, role: 'siswa', extraId: 3 };
  if (token === 'guru_token')  return { id: 2, role: 'guru',  extraId: 1 };
  throw new Error('invalid');
});

beforeEach(() => jest.clearAllMocks());

const authHeader = (token) => ({ Authorization: `Bearer ${token}` });

// Create a minimal valid PDF buffer for upload tests
const minimalPdf = Buffer.from('%PDF-1.0\n1 0 obj<</Type/Catalog>>endobj\nxref\n0 0\ntrailer<</Root 1 0 R>>\nstartxref\n9\n%%EOF');

describe('POST /api/izin', () => {
  test('returns 401 without auth', async () => {
    const res = await request(app).post('/api/izin').send({});
    expect(res.status).toBe(401);
  });

  test('returns 403 when role is guru', async () => {
    const res = await request(app)
      .post('/api/izin')
      .set(authHeader('guru_token'))
      .send({});
    expect(res.status).toBe(403);
  });

  test('returns 400 when no file attached', async () => {
    const res = await request(app)
      .post('/api/izin')
      .set(authHeader('siswa_token'))
      .field('tanggal', '2026-07-09')
      .field('jenis', 'sakit');
    expect(res.status).toBe(400);
  });

  test('returns 201 on valid izin submission', async () => {
    db.query
      .mockResolvedValueOnce([[]])                    // no duplicate
      .mockResolvedValueOnce([{ insertId: 7 }])       // INSERT izin
      .mockResolvedValueOnce([{ affectedRows: 0 }]);  // UPDATE absensi

    // Write temp PDF for upload
    const tmpPdf = path.join(require('os').tmpdir(), 'test_surat.pdf');
    fs.writeFileSync(tmpPdf, minimalPdf);

    const res = await request(app)
      .post('/api/izin')
      .set(authHeader('siswa_token'))
      .field('tanggal', '2026-07-09')
      .field('jenis', 'sakit')
      .attach('file_surat', tmpPdf);

    fs.unlinkSync(tmpPdf);
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });
});

describe('GET /api/izin', () => {
  test('returns 403 for siswa', async () => {
    const res = await request(app).get('/api/izin').set(authHeader('siswa_token'));
    expect(res.status).toBe(403);
  });

  test('returns list for guru', async () => {
    db.query.mockResolvedValueOnce([[{ id_izin: 1, nama_siswa: 'Andi', status: 'pending' }]]);
    const res = await request(app).get('/api/izin').set(authHeader('guru_token'));
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
  });
});

describe('PUT /api/izin/:id/status', () => {
  test('returns 400 for invalid status value', async () => {
    const res = await request(app)
      .put('/api/izin/1/status')
      .set(authHeader('guru_token'))
      .send({ status: 'unknown' });
    expect(res.status).toBe(400);
  });

  test('returns 200 on approve', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, tanggal: '2026-07-09' }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }])
      .mockResolvedValueOnce([[]])
      .mockResolvedValueOnce([{ insertId: 20 }]);

    const res = await request(app)
      .put('/api/izin/1/status')
      .set(authHeader('guru_token'))
      .send({ status: 'approved' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

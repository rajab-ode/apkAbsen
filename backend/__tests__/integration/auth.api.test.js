jest.mock('../../src/config/db');
jest.mock('bcryptjs');
jest.mock('jsonwebtoken');

const db = require('../../src/config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const app = require('../../app');

process.env.JWT_SECRET = 'test_secret';

beforeEach(() => jest.clearAllMocks());

describe('POST /api/auth/login', () => {
  test('returns 400 for empty body', async () => {
    const res = await request(app).post('/api/auth/login').send({});
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('returns 401 for unknown username', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'ghost', password: 'x' });
    expect(res.status).toBe(401);
  });

  test('returns 401 for wrong password', async () => {
    db.query.mockResolvedValueOnce([[{
      id_user: 1, username: 'admin', password: 'hashed', role: 'admin', status: 'aktif',
    }]]);
    bcrypt.compare.mockResolvedValueOnce(false);
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'wrong' });
    expect(res.status).toBe(401);
  });

  test('returns 200 with token and role on successful login', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_user: 1, username: 'admin', password: 'h', role: 'admin', status: 'aktif' }]])
      .mockResolvedValueOnce([[{ nama: 'Administrator' }]]);
    bcrypt.compare.mockResolvedValueOnce(true);
    jwt.sign.mockReturnValueOnce('api_token');

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'admin123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({ role: 'admin', token: 'api_token' });
  });
});

describe('GET /api/health', () => {
  test('returns status ok', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('Unknown routes', () => {
  test('returns 404 for undefined route', async () => {
    const res = await request(app).get('/api/undefined-route');
    expect(res.status).toBe(404);
  });
});

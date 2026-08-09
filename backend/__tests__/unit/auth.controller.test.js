jest.mock('../../src/config/db');
jest.mock('bcryptjs');
jest.mock('jsonwebtoken');

const db = require('../../src/config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { login } = require('../../src/controllers/authController');

process.env.JWT_SECRET = 'test_secret';

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe('authController.login', () => {
  beforeEach(() => jest.clearAllMocks());

  test('returns 400 when username missing', async () => {
    const res = mockRes();
    await login({ body: { password: 'x' } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when password missing', async () => {
    const res = mockRes();
    await login({ body: { username: 'x' } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 401 when user not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await login({ body: { username: 'ghost', password: 'x' } }, res);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('returns 401 when password is wrong', async () => {
    db.query.mockResolvedValueOnce([[{
      id_user: 1, username: 'admin', password: 'hashed', role: 'admin', status: 'aktif',
    }]]);
    bcrypt.compare.mockResolvedValueOnce(false);
    const res = mockRes();
    await login({ body: { username: 'admin', password: 'wrong' } }, res);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('returns 200 with token on valid admin login', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_user: 1, username: 'admin', password: 'hashed', role: 'admin', status: 'aktif' }]])
      .mockResolvedValueOnce([[{ nama: 'Administrator' }]]);
    bcrypt.compare.mockResolvedValueOnce(true);
    jwt.sign.mockReturnValueOnce('mock_jwt_token');

    const res = mockRes();
    await login({ body: { username: 'admin', password: 'admin123' } }, res);

    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true,
      data: expect.objectContaining({ role: 'admin', token: 'mock_jwt_token' }),
    }));
  });

  test('returns 200 with extraId on valid siswa login', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_user: 5, username: 'siswa01', password: 'hashed', role: 'siswa', status: 'aktif' }]])
      .mockResolvedValueOnce([[{ id_siswa: 3, nama_siswa: 'Budi Santoso' }]]);
    bcrypt.compare.mockResolvedValueOnce(true);
    jwt.sign.mockReturnValueOnce('siswa_token');

    const res = mockRes();
    await login({ body: { username: 'siswa01', password: 'pass' } }, res);

    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true,
      data: expect.objectContaining({ role: 'siswa', extraId: 3, nama: 'Budi Santoso' }),
    }));
  });

  test('returns 500 on db error', async () => {
    db.query.mockRejectedValueOnce(new Error('DB error'));
    const res = mockRes();
    await login({ body: { username: 'admin', password: 'x' } }, res);
    expect(res.status).toHaveBeenCalledWith(500);
  });
});

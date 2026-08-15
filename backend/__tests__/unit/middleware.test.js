const jwt = require('jsonwebtoken');
const { authMiddleware, requireRole } = require('../../src/middleware/auth');

process.env.JWT_SECRET = 'test_secret';

const mockNext = jest.fn();
const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

beforeEach(() => mockNext.mockClear());

describe('authMiddleware', () => {
  test('returns 401 when no Authorization header', () => {
    const req = { headers: {} };
    const res = mockRes();
    authMiddleware(req, res, mockNext);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(mockNext).not.toHaveBeenCalled();
  });

  test('returns 401 when header does not start with Bearer', () => {
    const req = { headers: { authorization: 'Token abc123' } };
    const res = mockRes();
    authMiddleware(req, res, mockNext);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('returns 401 when token is invalid', () => {
    const req = { headers: { authorization: 'Bearer invalid.token.here' } };
    const res = mockRes();
    authMiddleware(req, res, mockNext);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('returns 401 when token is expired', () => {
    const token = jwt.sign({ id: 1, role: 'admin' }, 'test_secret', { expiresIn: -1 });
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    authMiddleware(req, res, mockNext);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('calls next() and sets req.user on valid token', () => {
    const payload = { id: 1, role: 'admin', extraId: null };
    const token = jwt.sign(payload, 'test_secret');
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    authMiddleware(req, res, mockNext);
    expect(mockNext).toHaveBeenCalled();
    expect(req.user).toMatchObject({ id: 1, role: 'admin' });
  });
});

describe('requireRole', () => {
  const makeReq = (role) => ({ user: { role } });

  test('returns 403 when role does not match', () => {
    const middleware = requireRole('admin');
    const res = mockRes();
    middleware(makeReq('siswa'), res, mockNext);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(mockNext).not.toHaveBeenCalled();
  });

  test('calls next() when role matches', () => {
    const middleware = requireRole('guru', 'admin');
    const res = mockRes();
    middleware(makeReq('guru'), res, mockNext);
    expect(mockNext).toHaveBeenCalled();
  });

  test('calls next() when any of multiple roles match', () => {
    const middleware = requireRole('guru', 'admin');
    const res = mockRes();
    middleware(makeReq('admin'), res, mockNext);
    expect(mockNext).toHaveBeenCalled();
  });
});

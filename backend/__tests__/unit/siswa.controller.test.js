jest.mock('../../src/config/db');

const db = require('../../src/config/db');
const ctrl = require('../../src/controllers/siswaController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

beforeEach(() => jest.clearAllMocks());

describe('siswaController.getAll', () => {
  test('returns paginated list', async () => {
    const rows = [{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001' }];
    db.query
      .mockResolvedValueOnce([rows])
      .mockResolvedValueOnce([[{ total: 1 }]]);

    const res = mockRes();
    await ctrl.getAll({ query: { page: 1, limit: 9, search: '' } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, data: rows, total: 1 }));
  });
});

describe('siswaController.getById', () => {
  test('returns 404 when not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.getById({ params: { id: 999 } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('returns siswa data when found', async () => {
    const siswa = { id_siswa: 1, nama_siswa: 'Andi', NIS: '001' };
    db.query.mockResolvedValueOnce([[siswa]]);
    const res = mockRes();
    await ctrl.getById({ params: { id: 1 } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, data: siswa }));
  });
});

describe('siswaController.create', () => {
  const baseReq = {
    body: { nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', jurusan: 'TKJ' },
    file: null,
  };

  test('returns 400 when nama_siswa missing', async () => {
    const res = mockRes();
    await ctrl.create({ body: { NIS: '001' }, file: null }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 409 when NIS already exists', async () => {
    db.query.mockResolvedValueOnce([[{ id_siswa: 1 }]]);
    const res = mockRes();
    await ctrl.create(baseReq, res);
    expect(res.status).toHaveBeenCalledWith(409);
  });

  test('returns 201 on successful create', async () => {
    db.query
      .mockResolvedValueOnce([[]])                     // NIS duplicate check → not found
      .mockResolvedValueOnce([{ insertId: 5 }]);       // INSERT
    const res = mockRes();
    await ctrl.create(baseReq, res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

describe('siswaController.remove', () => {
  test('returns 404 when siswa not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.remove({ params: { id: 99 } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('returns 200 on successful delete', async () => {
    db.query
      .mockResolvedValueOnce([[{ foto: null }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }]);
    const res = mockRes();
    await ctrl.remove({ params: { id: 1 } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

describe('siswaController.registerFace', () => {
  const validEmbedding = new Array(192).fill(0.1);

  test('returns 400 when embedding is not 192-dim', async () => {
    const res = mockRes();
    await ctrl.registerFace({ params: { id: 1 }, body: { embedding: [1, 2, 3] } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when embedding is not an array', async () => {
    const res = mockRes();
    await ctrl.registerFace({ params: { id: 1 }, body: { embedding: 'invalid' } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 404 when siswa not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.registerFace({ params: { id: 99 }, body: { embedding: validEmbedding }, user: { role: 'admin' } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('returns 200 on successful face registration', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1 }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }]);
    const res = mockRes();
    await ctrl.registerFace({ params: { id: 1 }, body: { embedding: validEmbedding }, user: { role: 'admin' } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

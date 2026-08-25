jest.mock('../../src/config/db');

const db = require('../../src/config/db');
const ctrl = require('../../src/controllers/kelasController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

beforeEach(() => jest.resetAllMocks());

describe('kelasController.getAll', () => {
  test('returns list of kelas', async () => {
    const rows = [{ id_kelas: 1, nama_kelas: 'XI TJKT' }];
    db.query.mockResolvedValueOnce([rows]);
    const res = mockRes();
    await ctrl.getAll({}, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, data: rows }));
  });
});

describe('kelasController.create', () => {
  test('returns 400 when nama_kelas missing', async () => {
    const res = mockRes();
    await ctrl.create({ body: {} }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 201 on successful create', async () => {
    db.query.mockResolvedValueOnce([{ insertId: 5 }]);
    const res = mockRes();
    await ctrl.create({ body: { nama_kelas: 'XI A' } }, res);
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test('returns 409 on duplicate kelas', async () => {
    const err = new Error('dup'); err.code = 'ER_DUP_ENTRY';
    db.query.mockRejectedValueOnce(err);
    const res = mockRes();
    await ctrl.create({ body: { nama_kelas: 'XI TJKT' } }, res);
    expect(res.status).toHaveBeenCalledWith(409);
  });
});

describe('kelasController.remove', () => {
  test('returns 404 when kelas not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.remove({ params: { id: 99 } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('returns 409 when kelas still in use by siswa or jadwal', async () => {
    db.query
      .mockResolvedValueOnce([[{ nama_kelas: 'XI TJKT' }]])
      .mockResolvedValueOnce([[{ jumlahSiswa: 3 }]])
      .mockResolvedValueOnce([[{ jumlahJadwal: 0 }]]);
    const res = mockRes();
    await ctrl.remove({ params: { id: 1 } }, res);
    expect(res.status).toHaveBeenCalledWith(409);
  });

  test('returns 200 when kelas is unused and deleted', async () => {
    db.query
      .mockResolvedValueOnce([[{ nama_kelas: 'XI KOSONG' }]])
      .mockResolvedValueOnce([[{ jumlahSiswa: 0 }]])
      .mockResolvedValueOnce([[{ jumlahJadwal: 0 }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }]);
    const res = mockRes();
    await ctrl.remove({ params: { id: 1 } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

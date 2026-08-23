jest.mock('../../src/config/db');

const db = require('../../src/config/db');
const ctrl = require('../../src/controllers/jadwalController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const guruReq = (overrides = {}) => ({
  user: { extraId: 5 },
  body: {},
  params: {},
  ...overrides,
});

beforeEach(() => jest.resetAllMocks());

describe('jadwalController.getMine', () => {
  test('returns own jadwal list ordered by hari/jam', async () => {
    const rows = [{ id_jadwal: 1, kelas: 'XI TJKT', hari: 'Senin', jam_mulai: '07:00:00' }];
    db.query.mockResolvedValueOnce([rows]);
    const res = mockRes();
    await ctrl.getMine(guruReq(), res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, data: rows }));
  });
});

describe('jadwalController.create', () => {
  const validBody = {
    kelas: 'XI TJKT', hari: 'Senin', jam_mulai: '07:00', jam_selesai: '08:30', mata_pelajaran: 'Matematika',
  };

  test('returns 400 when a field is missing', async () => {
    const res = mockRes();
    await ctrl.create(guruReq({ body: { ...validBody, mata_pelajaran: undefined } }), res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when hari is invalid', async () => {
    const res = mockRes();
    await ctrl.create(guruReq({ body: { ...validBody, hari: 'Minggu' } }), res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when jam_selesai is not after jam_mulai', async () => {
    const res = mockRes();
    await ctrl.create(guruReq({ body: { ...validBody, jam_mulai: '08:30', jam_selesai: '07:00' } }), res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 201 on successful create', async () => {
    db.query.mockResolvedValueOnce([{ insertId: 10 }]);
    const res = mockRes();
    await ctrl.create(guruReq({ body: validBody }), res);
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test('returns 409 when jadwal already exists (duplicate key)', async () => {
    const err = new Error('dup'); err.code = 'ER_DUP_ENTRY';
    db.query.mockRejectedValueOnce(err);
    const res = mockRes();
    await ctrl.create(guruReq({ body: validBody }), res);
    expect(res.status).toHaveBeenCalledWith(409);
  });
});

describe('jadwalController.remove', () => {
  test('returns 404 when jadwal not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.remove(guruReq({ params: { id: 99 } }), res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('returns 403 when jadwal belongs to another guru', async () => {
    db.query.mockResolvedValueOnce([[{ id_guru: 999 }]]);
    const res = mockRes();
    await ctrl.remove(guruReq({ params: { id: 1 } }), res);
    expect(res.status).toHaveBeenCalledWith(403);
  });

  test('returns 200 on successful delete', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_guru: 5 }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }]);
    const res = mockRes();
    await ctrl.remove(guruReq({ params: { id: 1 } }), res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

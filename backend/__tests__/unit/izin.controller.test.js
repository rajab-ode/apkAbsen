jest.mock('../../src/config/db');

const db = require('../../src/config/db');
const ctrl = require('../../src/controllers/izinController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

beforeEach(() => jest.resetAllMocks());

describe('izinController.ajukan', () => {
  const siswaReq = (overrides = {}) => ({
    user: { extraId: 1 },
    body: { tanggal: '2026-07-09', jenis: 'sakit' },
    file: { filename: 'surat123.pdf' },
    ...overrides,
  });

  test('returns 403 when user is not siswa (no extraId)', async () => {
    const res = mockRes();
    await ctrl.ajukan({ user: { extraId: null }, body: {}, file: null }, res);
    expect(res.status).toHaveBeenCalledWith(403);
  });

  test('returns 400 when tanggal missing', async () => {
    const res = mockRes();
    await ctrl.ajukan(siswaReq({ body: { jenis: 'sakit' } }), res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when jenis is invalid', async () => {
    const res = mockRes();
    await ctrl.ajukan(siswaReq({ body: { tanggal: '2026-07-09', jenis: 'cuti' } }), res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when file is missing', async () => {
    const res = mockRes();
    await ctrl.ajukan(siswaReq({ file: null }), res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 409 when izin for same date already exists', async () => {
    db.query.mockResolvedValueOnce([[{ id_izin: 1 }]]);
    const res = mockRes();
    await ctrl.ajukan(siswaReq(), res);
    expect(res.status).toHaveBeenCalledWith(409);
  });

  test('returns 201 on successful submission', async () => {
    db.query
      .mockResolvedValueOnce([[]])                   // no duplicate
      .mockResolvedValueOnce([{ insertId: 7 }])      // INSERT izin
      .mockResolvedValueOnce([{ affectedRows: 0 }]); // UPDATE absensi (none to update)

    const res = mockRes();
    await ctrl.ajukan(siswaReq(), res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

describe('izinController.getAll', () => {
  test('returns list of all izin', async () => {
    const rows = [{ id_izin: 1, nama_siswa: 'Andi', status: 'pending' }];
    db.query.mockResolvedValueOnce([rows]);
    const res = mockRes();
    await ctrl.getAll({}, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true, data: rows }));
  });
});

describe('izinController.getMySiswa', () => {
  test('returns izin list for a student', async () => {
    db.query.mockResolvedValueOnce([[{ id_izin: 1 }]]);
    const res = mockRes();
    await ctrl.getMySiswa({ user: { role: 'siswa', extraId: 1 }, params: { idSiswa: '1' } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });

  test('returns 403 when a siswa requests another siswa\'s izin', async () => {
    const res = mockRes();
    await ctrl.getMySiswa({ user: { role: 'siswa', extraId: 1 }, params: { idSiswa: '2' } }, res);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(db.query).not.toHaveBeenCalled();
  });
});

describe('izinController.updateStatus', () => {
  test('returns 400 when status is not approved or rejected', async () => {
    const res = mockRes();
    await ctrl.updateStatus({ params: { id: 1 }, body: { status: 'pending' } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 404 when izin not found', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.updateStatus({ params: { id: 99 }, body: { status: 'approved' } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('returns 200 and creates absensi row on approved (no existing absensi)', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, tanggal: '2026-07-09' }]]) // find izin
      .mockResolvedValueOnce([{ affectedRows: 1 }])                       // update izin status
      .mockResolvedValueOnce([[]])                                         // no existing absensi
      .mockResolvedValueOnce([{ insertId: 20 }]);                         // insert absensi

    const res = mockRes();
    await ctrl.updateStatus({ params: { id: 1 }, body: { status: 'approved' } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    expect(db.query).toHaveBeenCalledTimes(4);
  });

  test('returns 200 and updates existing absensi on approved', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, tanggal: '2026-07-09' }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }])
      .mockResolvedValueOnce([[{ id_absensi: 5 }]])   // existing absensi found
      .mockResolvedValueOnce([{ affectedRows: 1 }]);   // update absensi status

    const res = mockRes();
    await ctrl.updateStatus({ params: { id: 1 }, body: { status: 'approved' } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });

  test('returns 200 on rejected (no absensi change)', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, tanggal: '2026-07-09' }]])
      .mockResolvedValueOnce([{ affectedRows: 1 }]);

    const res = mockRes();
    await ctrl.updateStatus({ params: { id: 1 }, body: { status: 'rejected' } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

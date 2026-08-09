jest.mock('../../src/config/db');

const db = require('../../src/config/db');
const ctrl = require('../../src/controllers/absensiController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.setHeader = jest.fn();
  return res;
};

// 128-dim unit vector helpers
const unitVec = (dim) => { const v = new Array(128).fill(0); v[dim] = 1.0; return v; };
const embedding = unitVec(0);

beforeEach(() => jest.clearAllMocks());

describe('absensiController.recognize', () => {
  test('returns 400 when embedding is missing', async () => {
    const res = mockRes();
    await ctrl.recognize({ body: {} }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when embedding is not 128-dim', async () => {
    const res = mockRes();
    await ctrl.recognize({ body: { embedding: [1, 2, 3] } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 404 when no students have registered faces', async () => {
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('Belum ada wajah') }));
  });

  test('returns 404 when best match is below threshold (0.80)', async () => {
    // Orthogonal vector → similarity = 0.0
    const stored = unitVec(1);
    db.query.mockResolvedValueOnce([[{
      id_siswa: 1, nama_siswa: 'Andi', NIS: '001', foto: null,
      data_wajah: JSON.stringify(stored),
    }]]);
    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('tidak dikenali') }));
  });

  test('returns 409 when student already absent today', async () => {
    const stored = unitVec(0); // identical → similarity = 1.0
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[{ id_absensi: 5 }]]); // already exists today

    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(409);
  });

  test('returns 201 and inserts absensi on successful recognition', async () => {
    const stored = unitVec(0);
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001', foto: 'foto/andi.jpg', data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[]])                    // no existing absensi today
      .mockResolvedValueOnce([{ insertId: 10 }]);     // INSERT absensi

    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true,
      data: expect.objectContaining({ nama_siswa: 'Andi', status: 'hadir' }),
    }));
  });

  test('picks the highest similarity match from multiple students', async () => {
    const targetEmbedding = embedding;
    const matchStored = unitVec(0);    // similarity = 1.0 → match
    const otherStored  = unitVec(1);   // similarity = 0.0 → no match

    db.query
      .mockResolvedValueOnce([[
        { id_siswa: 1, nama_siswa: 'Andi', NIS: '001', foto: null, data_wajah: JSON.stringify(matchStored) },
        { id_siswa: 2, nama_siswa: 'Budi', NIS: '002', foto: null, data_wajah: JSON.stringify(otherStored) },
      ]])
      .mockResolvedValueOnce([[]])
      .mockResolvedValueOnce([{ insertId: 11 }]);

    const res = mockRes();
    await ctrl.recognize({ body: { embedding: targetEmbedding } }, res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ nama_siswa: 'Andi' }),
    }));
  });
});

describe('absensiController.getAll', () => {
  test('returns data with stats', async () => {
    db.query
      .mockResolvedValueOnce([[{ id_absensi: 1, nama_siswa: 'Andi', status: 'hadir', waktu: '07:30:00' }]])
      .mockResolvedValueOnce([[{ total: 1 }]])
      .mockResolvedValueOnce([[{ hadir: 1, izin: 0, tidak_hadir: 0 }]]);

    const res = mockRes();
    await ctrl.getAll({ query: { tanggal: '2026-07-09', search: '', page: 1, limit: 10 } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true, hadir: 1, izin: 0, tidakHadir: 0,
    }));
  });
});

describe('absensiController.getMySiswa', () => {
  test('returns absensi list for a student', async () => {
    db.query.mockResolvedValueOnce([[{ id_absensi: 1, status: 'hadir' }]]);
    const res = mockRes();
    await ctrl.getMySiswa({ params: { idSiswa: 1 } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

describe('absensiController.downloadPdf', () => {
  test('returns 400 when tanggal missing', async () => {
    const res = mockRes();
    await ctrl.downloadPdf({ query: {} }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });
});

describe('absensiController.downloadExcel', () => {
  test('returns 400 when tanggal missing', async () => {
    const res = mockRes();
    await ctrl.downloadExcel({ query: {} }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });
});

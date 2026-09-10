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

// 192-dim unit vector helpers (matches MobileFaceNet embedding size used by the app)
const unitVec = (dim) => { const v = new Array(192).fill(0); v[dim] = 1.0; return v; };
const embedding = unitVec(0);

beforeEach(() => {
  jest.resetAllMocks(); // clearAllMocks leaves unconsumed mockResolvedValueOnce queued, leaking into the next test
  ctrl.invalidateEmbeddingCache(); // recognize() caches student embeddings in-memory; reset between tests
});

describe('absensiController.recognize', () => {
  // Semua test di bawah ini mock query geofence (panggilan db.query pertama)
  // sebagai "belum diisi admin" ([[]]) supaya perilaku lama tetap terverifikasi
  // tanpa perlu peduli geofence — kasus geofence sendiri diuji terpisah di bawah.
  const noGeofence = () => db.query.mockResolvedValueOnce([[]]);

  test('returns 400 when embedding is missing', async () => {
    const res = mockRes();
    await ctrl.recognize({ body: {} }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 400 when embedding is not 192-dim', async () => {
    const res = mockRes();
    await ctrl.recognize({ body: { embedding: [1, 2, 3] } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('returns 404 when no students have registered faces', async () => {
    noGeofence();
    db.query.mockResolvedValueOnce([[]]);
    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('Belum ada wajah') }));
  });

  test('returns 404 when best match is below threshold (0.80)', async () => {
    // Orthogonal vector → similarity = 0.0
    const stored = unitVec(1);
    noGeofence();
    db.query.mockResolvedValueOnce([[{
      id_siswa: 1, nama_siswa: 'Andi', NIS: '001', foto: null,
      data_wajah: JSON.stringify(stored),
    }]]);
    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('tidak dikenali') }));
  });

  test('returns 404 when no jadwal matches the current day/time', async () => {
    const stored = unitVec(0);
    noGeofence();
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[]]); // no jadwal_pelajaran row matches kelas+hari+jam

    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('jadwal pelajaran') }));
  });

  test('returns 409 when student already absent for this jadwal today', async () => {
    const stored = unitVec(0); // identical → similarity = 1.0
    noGeofence();
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[{ id_jadwal: 1, mata_pelajaran: 'Matematika', jam_mulai: '00:00:00' }]])
      .mockResolvedValueOnce([{ affectedRows: 0 }]); // INSERT IGNORE skipped → already exists today

    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(409);
  });

  test('returns 201, inserts absensi, and marks telat when absen after jam_mulai', async () => {
    const stored = unitVec(0);
    noGeofence();
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', foto: 'foto/andi.jpg', data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[{ id_jadwal: 1, mata_pelajaran: 'Matematika', jam_mulai: '00:00:00' }]]) // always in the past → telat
      .mockResolvedValueOnce([{ affectedRows: 1, insertId: 10 }]); // INSERT IGNORE succeeded

    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      success: true,
      data: expect.objectContaining({ nama_siswa: 'Andi', status: 'hadir', mata_pelajaran: 'Matematika', status_waktu: 'telat' }),
    }));
  });

  test('marks tepat_waktu when absen before jam_mulai', async () => {
    const stored = unitVec(0);
    noGeofence();
    db.query
      .mockResolvedValueOnce([[{ id_siswa: 1, nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', foto: null, data_wajah: JSON.stringify(stored) }]])
      .mockResolvedValueOnce([[{ id_jadwal: 1, mata_pelajaran: 'Matematika', jam_mulai: '23:59:59' }]]) // always in the future → tepat waktu
      .mockResolvedValueOnce([{ affectedRows: 1, insertId: 10 }]);

    const res = mockRes();
    await ctrl.recognize({ body: { embedding } }, res);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status_waktu: 'tepat_waktu' }),
    }));
  });

  test('picks the highest similarity match from multiple students', async () => {
    const targetEmbedding = embedding;
    const matchStored = unitVec(0);    // similarity = 1.0 → match
    const otherStored  = unitVec(1);   // similarity = 0.0 → no match

    noGeofence();
    db.query
      .mockResolvedValueOnce([[
        { id_siswa: 1, nama_siswa: 'Andi', NIS: '001', kelas: 'XI TJKT', foto: null, data_wajah: JSON.stringify(matchStored) },
        { id_siswa: 2, nama_siswa: 'Budi', NIS: '002', kelas: 'XI TJKT', foto: null, data_wajah: JSON.stringify(otherStored) },
      ]])
      .mockResolvedValueOnce([[{ id_jadwal: 1, mata_pelajaran: 'Matematika', jam_mulai: '00:00:00' }]])
      .mockResolvedValueOnce([{ affectedRows: 1, insertId: 11 }]); // INSERT IGNORE succeeded

    const res = mockRes();
    await ctrl.recognize({ body: { embedding: targetEmbedding } }, res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ nama_siswa: 'Andi' }),
    }));
  });

  describe('geofencing', () => {
    const gf = { id: 1, latitude: '-3.9778000', longitude: '122.5194000', radius_meter: 100 };

    test('allows through when geofence is not configured (fail-open)', async () => {
      noGeofence();
      db.query.mockResolvedValueOnce([[]]); // no students, just proving we got past the geofence step
      const res = mockRes();
      await ctrl.recognize({ body: { embedding, latitude: -8, longitude: 140 } }, res);
      // reaches the "no students" check, not blocked by geofence
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('Belum ada wajah') }));
    });

    test('returns 400 when geofence configured but location missing from request', async () => {
      db.query.mockResolvedValueOnce([[gf]]);
      const res = mockRes();
      await ctrl.recognize({ body: { embedding } }, res);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('Lokasi tidak terdeteksi') }));
    });

    test('returns 403 when outside the configured radius', async () => {
      db.query.mockResolvedValueOnce([[gf]]);
      const res = mockRes();
      // Jakarta-ish coords, hundreds of km from the school's Kendari coords
      await ctrl.recognize({ body: { embedding, latitude: -6.2, longitude: 106.8 } }, res);
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('luar area sekolah') }));
    });

    test('proceeds when inside the configured radius', async () => {
      db.query.mockResolvedValueOnce([[gf]]);
      db.query.mockResolvedValueOnce([[]]); // no students registered — proves geofence passed
      const res = mockRes();
      await ctrl.recognize({ body: { embedding, latitude: -3.9778, longitude: 122.5194 } }, res);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.stringContaining('Belum ada wajah') }));
    });
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

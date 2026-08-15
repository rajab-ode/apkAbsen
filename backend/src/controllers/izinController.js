const db = require('../config/db');

async function ajukan(req, res) {
  const { tanggal, jenis } = req.body;
  const idSiswa = req.user.extraId;

  if (!idSiswa) return res.status(403).json({ success: false, message: 'Hanya siswa yang dapat mengajukan izin' });
  if (!tanggal || !jenis) return res.status(400).json({ success: false, message: 'Tanggal dan jenis wajib diisi' });
  if (!['sakit', 'izin'].includes(jenis)) return res.status(400).json({ success: false, message: 'Jenis harus sakit atau izin' });
  if (!req.file) return res.status(400).json({ success: false, message: 'File surat izin wajib diupload' });

  const fileSurat = 'surat/' + req.file.filename;

  try {
    const [dup] = await db.query(
      'SELECT id_izin FROM izin WHERE id_siswa = ? AND tanggal = ?',
      [idSiswa, tanggal]
    );
    if (dup.length) return res.status(409).json({ success: false, message: 'Izin untuk tanggal ini sudah diajukan' });

    const [result] = await db.query(
      'INSERT INTO izin (id_siswa, tanggal, jenis, file_surat, status) VALUES (?,?,?,?,"pending")',
      [idSiswa, tanggal, jenis, fileSurat]
    );

    // Update absensi status if exists
    await db.query(
      'UPDATE absensi SET status = "izin" WHERE id_siswa = ? AND tanggal = ?',
      [idSiswa, tanggal]
    );

    res.status(201).json({ success: true, message: 'Izin berhasil diajukan', data: { id_izin: result.insertId } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengajukan izin' });
  }
}

async function getAll(req, res) {
  try {
    const [rows] = await db.query(
      `SELECT i.id_izin, s.nama_siswa, s.NIS, i.tanggal, i.jenis, i.file_surat, i.status
       FROM izin i JOIN siswa s ON i.id_siswa = s.id_siswa
       ORDER BY i.tanggal DESC, i.id_izin DESC`
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data izin' });
  }
}

async function getMySiswa(req, res) {
  const idSiswa = req.params.idSiswa;
  try {
    const [rows] = await db.query(
      `SELECT i.id_izin, s.nama_siswa, s.NIS, i.tanggal, i.jenis, i.file_surat, i.status
       FROM izin i JOIN siswa s ON i.id_siswa = s.id_siswa
       WHERE i.id_siswa = ? ORDER BY i.tanggal DESC`,
      [idSiswa]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data izin' });
  }
}

async function updateStatus(req, res) {
  const { status } = req.body;
  const id = req.params.id;

  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ success: false, message: 'Status harus approved atau rejected' });
  }

  try {
    const [existing] = await db.query(
      'SELECT i.id_siswa, i.tanggal FROM izin i WHERE i.id_izin = ?',
      [id]
    );
    if (!existing.length) return res.status(404).json({ success: false, message: 'Data izin tidak ditemukan' });

    await db.query('UPDATE izin SET status = ? WHERE id_izin = ?', [status, id]);

    if (status === 'approved') {
      const { id_siswa, tanggal } = existing[0];
      const [abs] = await db.query(
        'SELECT id_absensi FROM absensi WHERE id_siswa = ? AND tanggal = ?',
        [id_siswa, tanggal]
      );
      if (abs.length) {
        await db.query('UPDATE absensi SET status = "izin" WHERE id_absensi = ?', [abs[0].id_absensi]);
      } else {
        const waktu = new Date().toTimeString().slice(0, 8);
        await db.query(
          'INSERT INTO absensi (id_siswa, tanggal, waktu, status) VALUES (?,?,?,"izin")',
          [id_siswa, tanggal, waktu]
        );
      }
    }

    res.json({ success: true, message: `Izin berhasil ${status === 'approved' ? 'disetujui' : 'ditolak'}` });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal memperbarui status izin' });
  }
}

module.exports = { ajukan, getAll, getMySiswa, updateStatus };

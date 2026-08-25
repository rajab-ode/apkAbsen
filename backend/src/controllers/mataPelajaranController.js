const db = require('../config/db');

async function getAll(req, res) {
  try {
    const [rows] = await db.query('SELECT * FROM mata_pelajaran ORDER BY nama_mapel');
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data mata pelajaran' });
  }
}

async function create(req, res) {
  const { nama_mapel } = req.body;
  if (!nama_mapel || !nama_mapel.trim()) {
    return res.status(400).json({ success: false, message: 'Nama mata pelajaran wajib diisi' });
  }

  try {
    const [result] = await db.query('INSERT INTO mata_pelajaran (nama_mapel) VALUES (?)', [nama_mapel.trim()]);
    res.status(201).json({ success: true, message: 'Mata pelajaran berhasil ditambahkan', data: { id_mapel: result.insertId } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'Mata pelajaran ini sudah ada' });
    }
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menambahkan mata pelajaran' });
  }
}

async function remove(req, res) {
  const id = req.params.id;

  try {
    const [existing] = await db.query('SELECT nama_mapel FROM mata_pelajaran WHERE id_mapel = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Mata pelajaran tidak ditemukan' });
    const nama = existing[0].nama_mapel;

    const [[{ jumlahGuru }]] = await db.query('SELECT COUNT(*) AS jumlahGuru FROM guru WHERE mata_pelajaran = ?', [nama]);
    const [[{ jumlahJadwal }]] = await db.query('SELECT COUNT(*) AS jumlahJadwal FROM jadwal_pelajaran WHERE mata_pelajaran = ?', [nama]);
    if (jumlahGuru > 0 || jumlahJadwal > 0) {
      return res.status(409).json({
        success: false,
        message: `Mata pelajaran ini masih dipakai oleh ${jumlahGuru} akun guru dan ${jumlahJadwal} jadwal — pindahkan dulu sebelum menghapus`,
      });
    }

    await db.query('DELETE FROM mata_pelajaran WHERE id_mapel = ?', [id]);
    res.json({ success: true, message: 'Mata pelajaran berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menghapus mata pelajaran' });
  }
}

module.exports = { getAll, create, remove };

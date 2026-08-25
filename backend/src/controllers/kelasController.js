const db = require('../config/db');

async function getAll(req, res) {
  try {
    const [rows] = await db.query('SELECT * FROM kelas ORDER BY nama_kelas');
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data kelas' });
  }
}

async function create(req, res) {
  const { nama_kelas } = req.body;
  if (!nama_kelas || !nama_kelas.trim()) {
    return res.status(400).json({ success: false, message: 'Nama kelas wajib diisi' });
  }

  try {
    const [result] = await db.query('INSERT INTO kelas (nama_kelas) VALUES (?)', [nama_kelas.trim()]);
    res.status(201).json({ success: true, message: 'Kelas berhasil ditambahkan', data: { id_kelas: result.insertId } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'Kelas ini sudah ada' });
    }
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menambahkan kelas' });
  }
}

async function remove(req, res) {
  const id = req.params.id;

  try {
    const [existing] = await db.query('SELECT nama_kelas FROM kelas WHERE id_kelas = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Kelas tidak ditemukan' });
    const nama = existing[0].nama_kelas;

    const [[{ jumlahSiswa }]] = await db.query('SELECT COUNT(*) AS jumlahSiswa FROM siswa WHERE kelas = ?', [nama]);
    const [[{ jumlahJadwal }]] = await db.query('SELECT COUNT(*) AS jumlahJadwal FROM jadwal_pelajaran WHERE kelas = ?', [nama]);
    if (jumlahSiswa > 0 || jumlahJadwal > 0) {
      return res.status(409).json({
        success: false,
        message: `Kelas ini masih dipakai oleh ${jumlahSiswa} siswa dan ${jumlahJadwal} jadwal — pindahkan dulu sebelum menghapus`,
      });
    }

    await db.query('DELETE FROM kelas WHERE id_kelas = ?', [id]);
    res.json({ success: true, message: 'Kelas berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menghapus kelas' });
  }
}

module.exports = { getAll, create, remove };

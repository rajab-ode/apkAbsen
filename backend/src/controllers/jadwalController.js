const db = require('../config/db');

const HARI_VALID = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

async function getMine(req, res) {
  const idGuru = req.user.extraId;
  try {
    const [rows] = await db.query(
      `SELECT * FROM jadwal_pelajaran WHERE id_guru = ?
       ORDER BY FIELD(hari,'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'), jam_mulai`,
      [idGuru]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil jadwal' });
  }
}

async function create(req, res) {
  const { kelas, hari, jam_mulai, jam_selesai, mata_pelajaran } = req.body;
  const idGuru = req.user.extraId;

  if (!kelas || !hari || !jam_mulai || !jam_selesai || !mata_pelajaran) {
    return res.status(400).json({ success: false, message: 'Semua field wajib diisi' });
  }
  if (!HARI_VALID.includes(hari)) {
    return res.status(400).json({ success: false, message: 'Hari tidak valid' });
  }
  if (jam_selesai <= jam_mulai) {
    return res.status(400).json({ success: false, message: 'Jam selesai harus setelah jam mulai' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO jadwal_pelajaran (id_guru, kelas, hari, jam_mulai, jam_selesai, mata_pelajaran) VALUES (?,?,?,?,?,?)',
      [idGuru, kelas, hari, jam_mulai, jam_selesai, mata_pelajaran]
    );
    res.status(201).json({ success: true, message: 'Jadwal berhasil ditambahkan', data: { id_jadwal: result.insertId } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'Jadwal ini sudah ada' });
    }
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menambahkan jadwal' });
  }
}

async function remove(req, res) {
  const id = req.params.id;
  const idGuru = req.user.extraId;

  try {
    const [existing] = await db.query('SELECT id_guru FROM jadwal_pelajaran WHERE id_jadwal = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Jadwal tidak ditemukan' });
    if (existing[0].id_guru !== idGuru) {
      return res.status(403).json({ success: false, message: 'Anda hanya bisa menghapus jadwal sendiri' });
    }

    await db.query('DELETE FROM jadwal_pelajaran WHERE id_jadwal = ?', [id]);
    res.json({ success: true, message: 'Jadwal berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menghapus jadwal' });
  }
}

module.exports = { getMine, create, remove };

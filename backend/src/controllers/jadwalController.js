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

async function getForSiswa(req, res) {
  const idSiswa = req.user.extraId;
  try {
    const [siswaRows] = await db.query('SELECT kelas, jurusan FROM siswa WHERE id_siswa = ?', [idSiswa]);
    if (!siswaRows.length || !siswaRows[0].kelas) {
      return res.json({ success: true, data: [] });
    }
    const [rows] = await db.query(
      `SELECT j.id_jadwal, j.kelas, j.jurusan, j.hari, j.jam_mulai, j.jam_selesai, j.mata_pelajaran, g.nama AS nama_guru
       FROM jadwal_pelajaran j
       JOIN guru g ON j.id_guru = g.id_guru
       WHERE j.kelas = ? AND j.jurusan = ?
       ORDER BY FIELD(j.hari,'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'), j.jam_mulai`,
      [siswaRows[0].kelas, siswaRows[0].jurusan]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil jadwal' });
  }
}

async function create(req, res) {
  const { kelas, jurusan, hari, jam_mulai, jam_selesai, mata_pelajaran } = req.body;
  const idGuru = req.user.extraId;

  const hariList = Array.isArray(hari) ? hari : [hari];

  if (!kelas || !jurusan || !hari || hariList.length === 0 || !jam_mulai || !jam_selesai || !mata_pelajaran) {
    return res.status(400).json({ success: false, message: 'Semua field wajib diisi' });
  }
  if (!hariList.every((h) => HARI_VALID.includes(h))) {
    return res.status(400).json({ success: false, message: 'Hari tidak valid' });
  }
  if (jam_selesai <= jam_mulai) {
    return res.status(400).json({ success: false, message: 'Jam selesai harus setelah jam mulai' });
  }

  const berhasil = [];
  const duplikat = [];

  try {
    for (const h of hariList) {
      try {
        await db.query(
          'INSERT INTO jadwal_pelajaran (id_guru, kelas, jurusan, hari, jam_mulai, jam_selesai, mata_pelajaran) VALUES (?,?,?,?,?,?,?)',
          [idGuru, kelas, jurusan, h, jam_mulai, jam_selesai, mata_pelajaran]
        );
        berhasil.push(h);
      } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') {
          duplikat.push(h);
        } else {
          throw err;
        }
      }
    }

    if (berhasil.length === 0) {
      return res.status(409).json({ success: false, message: 'Jadwal ini sudah ada di semua hari yang dipilih', data: { berhasil, duplikat } });
    }

    const message = duplikat.length
      ? `Jadwal ditambahkan untuk ${berhasil.join(', ')} — ${duplikat.join(', ')} sudah ada sebelumnya`
      : 'Jadwal berhasil ditambahkan';
    res.status(201).json({ success: true, message, data: { berhasil, duplikat } });
  } catch (err) {
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

module.exports = { getMine, getForSiswa, create, remove };

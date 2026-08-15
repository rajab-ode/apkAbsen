const db = require('../config/db');
const path = require('path');
const fs = require('fs');
const { invalidateEmbeddingCache } = require('./absensiController');

async function getAll(req, res) {
  const { page = 1, limit = 9, search = '', no_account = '' } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  const like = `%${search}%`;
  const noAccountClause = no_account === 'true' ? 'AND s.id_user IS NULL' : '';

  try {
    const [rows] = await db.query(
      `SELECT s.id_siswa, s.id_user, s.nama_siswa, s.NIS, s.kelas, s.jurusan,
              s.jenis_kelamin, s.alamat, s.no_telepon, s.foto, s.created_at,
              (s.data_wajah IS NOT NULL) AS wajah_terdaftar
       FROM siswa s
       WHERE (s.nama_siswa LIKE ? OR s.NIS LIKE ? OR s.kelas LIKE ?) ${noAccountClause}
       ORDER BY s.nama_siswa
       LIMIT ? OFFSET ?`,
      [like, like, like, parseInt(limit), offset]
    );
    const [[{ total }]] = await db.query(
      `SELECT COUNT(*) AS total FROM siswa s WHERE (s.nama_siswa LIKE ? OR s.NIS LIKE ? OR s.kelas LIKE ?) ${noAccountClause}`,
      [like, like, like]
    );
    res.json({ success: true, data: rows, total, page: parseInt(page) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data siswa' });
  }
}

async function getById(req, res) {
  try {
    const [rows] = await db.query(
      'SELECT *, (data_wajah IS NOT NULL) AS wajah_terdaftar FROM siswa WHERE id_siswa = ?',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ success: false, message: 'Siswa tidak ditemukan' });
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data siswa' });
  }
}

async function create(req, res) {
  const { nama_siswa, NIS, kelas, jurusan, jenis_kelamin, alamat, no_telepon } = req.body;
  if (!nama_siswa || !NIS) {
    return res.status(400).json({ success: false, message: 'Nama dan NIS wajib diisi' });
  }
  const foto = req.file ? 'foto/' + req.file.filename : null;

  try {
    const [dup] = await db.query('SELECT id_siswa FROM siswa WHERE NIS = ?', [NIS]);
    if (dup.length) return res.status(409).json({ success: false, message: 'NIS sudah terdaftar' });

    const [result] = await db.query(
      'INSERT INTO siswa (nama_siswa, NIS, kelas, jurusan, jenis_kelamin, alamat, no_telepon, foto) VALUES (?,?,?,?,?,?,?,?)',
      [nama_siswa, NIS, kelas, jurusan, jenis_kelamin, alamat, no_telepon, foto]
    );
    res.status(201).json({ success: true, message: 'Siswa berhasil ditambahkan', data: { id_siswa: result.insertId } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menambahkan siswa' });
  }
}

async function update(req, res) {
  const { nama_siswa, NIS, kelas, jurusan, jenis_kelamin, alamat, no_telepon } = req.body;
  const id = req.params.id;

  try {
    const [existing] = await db.query('SELECT * FROM siswa WHERE id_siswa = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Siswa tidak ditemukan' });

    let foto = existing[0].foto;
    if (req.file) {
      if (foto) {
        const old = path.join(__dirname, '../../uploads', foto);
        if (fs.existsSync(old)) fs.unlinkSync(old);
      }
      foto = 'foto/' + req.file.filename;
    }

    await db.query(
      'UPDATE siswa SET nama_siswa=?, NIS=?, kelas=?, jurusan=?, jenis_kelamin=?, alamat=?, no_telepon=?, foto=? WHERE id_siswa=?',
      [nama_siswa, NIS, kelas, jurusan, jenis_kelamin, alamat, no_telepon, foto, id]
    );
    res.json({ success: true, message: 'Data siswa berhasil diperbarui' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal memperbarui data siswa' });
  }
}

async function remove(req, res) {
  const id = req.params.id;
  try {
    const [existing] = await db.query('SELECT foto FROM siswa WHERE id_siswa = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Siswa tidak ditemukan' });

    if (existing[0].foto) {
      const file = path.join(__dirname, '../../uploads', existing[0].foto);
      if (fs.existsSync(file)) fs.unlinkSync(file);
    }
    await db.query('DELETE FROM siswa WHERE id_siswa = ?', [id]);
    res.json({ success: true, message: 'Siswa berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menghapus siswa' });
  }
}

async function registerFace(req, res) {
  const { embedding } = req.body;
  const id = parseInt(req.params.id);

  if (!embedding || !Array.isArray(embedding) || embedding.length !== 192) {
    return res.status(400).json({ success: false, message: 'Embedding tidak valid (harus array 192 float)' });
  }

  // Siswa hanya boleh daftar wajah sendiri
  if (req.user.role === 'siswa' && req.user.extraId !== id) {
    return res.status(403).json({ success: false, message: 'Anda hanya bisa mendaftarkan wajah sendiri' });
  }

  try {
    const [existing] = await db.query('SELECT id_siswa FROM siswa WHERE id_siswa = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Siswa tidak ditemukan' });

    await db.query('UPDATE siswa SET data_wajah = ? WHERE id_siswa = ?', [JSON.stringify(embedding), id]);
    invalidateEmbeddingCache(); // hapus cache agar recognition pakai data terbaru
    res.json({ success: true, message: 'Wajah berhasil didaftarkan' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mendaftarkan wajah' });
  }
}

module.exports = { getAll, getById, create, update, remove, registerFace };

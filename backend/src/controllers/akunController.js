const bcrypt = require('bcryptjs');
const db = require('../config/db');

async function getPaginated(req, res) {
  const { page = 1, limit = 10, role = '', search = '' } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  const like = `%${search}%`;

  const conditions = [];
  const baseParams = [];
  if (role) { conditions.push('u.role = ?'); baseParams.push(role); }
  if (search) {
    conditions.push('(COALESCE(g.nama, a.nama, s.nama_siswa) LIKE ? OR u.username LIKE ?)');
    baseParams.push(like, like);
  }
  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  try {
    const [rows] = await db.query(
      `SELECT u.id_user, u.username, u.role, u.status,
         COALESCE(g.nama, a.nama, s.nama_siswa) AS nama,
         COALESCE(g.NIP, s.NIS) AS nis_nip,
         COALESCE(g.email, '') AS email,
         COALESCE(g.no_telepon, s.no_telepon, '') AS no_telepon,
         COALESCE(g.mata_pelajaran, '') AS mata_pelajaran,
         COALESCE(s.kelas, '') AS kelas
       FROM users u
       LEFT JOIN guru g ON u.id_user = g.id_user AND u.role = 'guru'
       LEFT JOIN admin a ON u.id_user = a.id_user AND u.role = 'admin'
       LEFT JOIN siswa s ON u.id_user = s.id_user AND u.role = 'siswa'
       ${whereClause}
       ORDER BY u.role, nama
       LIMIT ? OFFSET ?`,
      [...baseParams, parseInt(limit), offset]
    );

    const [[{ total }]] = await db.query(
      `SELECT COUNT(*) AS total
       FROM users u
       LEFT JOIN guru g ON u.id_user = g.id_user AND u.role = 'guru'
       LEFT JOIN admin a ON u.id_user = a.id_user AND u.role = 'admin'
       LEFT JOIN siswa s ON u.id_user = s.id_user AND u.role = 'siswa'
       ${whereClause}`,
      baseParams
    );

    const [[{ guru }]] = await db.query("SELECT COUNT(*) AS guru FROM users WHERE role = 'guru'");
    const [[{ siswa }]] = await db.query("SELECT COUNT(*) AS siswa FROM users WHERE role = 'siswa'");

    const totalPages = Math.ceil(total / parseInt(limit));
    res.json({ success: true, data: rows, total, page: parseInt(page), totalPages, stats: { guru, siswa } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data akun' });
  }
}

async function create(req, res) {
  const { username, password, role, nama, nis_nip, email, no_telepon, kelas, mata_pelajaran } = req.body;
  if (!username || !password || !role || !nama) {
    return res.status(400).json({ success: false, message: 'Username, password, role, dan nama wajib diisi' });
  }
  if (!['guru', 'siswa', 'admin'].includes(role)) {
    return res.status(400).json({ success: false, message: 'Role tidak valid' });
  }

  try {
    const [dup] = await db.query('SELECT id_user FROM users WHERE username = ?', [username]);
    if (dup.length) return res.status(409).json({ success: false, message: 'Username sudah digunakan' });

    const hashed = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      'INSERT INTO users (username, password, role, status) VALUES (?,?,?,"aktif")',
      [username, hashed, role]
    );
    const idUser = result.insertId;

    if (role === 'guru') {
      await db.query(
        'INSERT INTO guru (id_user, nama, NIP, email, no_telepon, mata_pelajaran) VALUES (?,?,?,?,?,?)',
        [idUser, nama, nis_nip || null, email || null, no_telepon || null, mata_pelajaran || null]
      );
    } else if (role === 'siswa') {
      const [siswaCek] = await db.query('SELECT id_siswa FROM siswa WHERE NIS = ?', [nis_nip]);
      if (!siswaCek.length) {
        await db.query('DELETE FROM users WHERE id_user = ?', [idUser]);
        return res.status(404).json({ success: false, message: `NIS ${nis_nip} tidak ditemukan di data siswa` });
      }
      await db.query('UPDATE siswa SET id_user = ? WHERE NIS = ?', [idUser, nis_nip]);
    } else if (role === 'admin') {
      await db.query('INSERT INTO admin (id_user, nama) VALUES (?,?)', [idUser, nama]);
    }

    res.status(201).json({ success: true, message: 'Akun berhasil dibuat', data: { id_user: idUser } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal membuat akun' });
  }
}

async function update(req, res) {
  const id = req.params.id;
  const { nama, email, no_telepon, kelas, mata_pelajaran, status, password } = req.body;

  try {
    const [existing] = await db.query('SELECT role FROM users WHERE id_user = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Akun tidak ditemukan' });
    const { role } = existing[0];

    if (status) await db.query('UPDATE users SET status = ? WHERE id_user = ?', [status, id]);
    if (password) {
      const hashed = await bcrypt.hash(password, 10);
      await db.query('UPDATE users SET password = ? WHERE id_user = ?', [hashed, id]);
    }

    if (role === 'guru') {
      await db.query(
        'UPDATE guru SET nama=?, email=?, no_telepon=?, mata_pelajaran=? WHERE id_user=?',
        [nama, email, no_telepon, mata_pelajaran, id]
      );
    } else if (role === 'siswa') {
      if (nama) await db.query('UPDATE siswa SET nama_siswa=? WHERE id_user=?', [nama, id]);
    } else if (role === 'admin') {
      await db.query('UPDATE admin SET nama=? WHERE id_user=?', [nama, id]);
    }

    res.json({ success: true, message: 'Akun berhasil diperbarui' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal memperbarui akun' });
  }
}

async function remove(req, res) {
  const id = req.params.id;
  try {
    const [existing] = await db.query('SELECT id_user FROM users WHERE id_user = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Akun tidak ditemukan' });

    await db.query('DELETE FROM users WHERE id_user = ?', [id]);
    res.json({ success: true, message: 'Akun berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menghapus akun' });
  }
}

module.exports = { getPaginated, create, update, remove };

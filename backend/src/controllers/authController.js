const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

async function login(req, res) {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ success: false, message: 'Username dan password wajib diisi' });
  }

  try {
    const [rows] = await db.query(
      'SELECT * FROM users WHERE username = ? AND status = "aktif" LIMIT 1',
      [username]
    );
    if (rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Username atau password salah' });
    }
    const user = rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ success: false, message: 'Username atau password salah' });
    }

    // Fetch role-specific data for nama
    let nama = user.username;
    let extraId = null;

    if (user.role === 'admin') {
      const [a] = await db.query('SELECT nama FROM admin WHERE id_user = ? LIMIT 1', [user.id_user]);
      if (a.length) nama = a[0].nama;
    } else if (user.role === 'guru') {
      const [g] = await db.query('SELECT id_guru, nama FROM guru WHERE id_user = ? LIMIT 1', [user.id_user]);
      if (g.length) { nama = g[0].nama; extraId = g[0].id_guru; }
    } else if (user.role === 'siswa') {
      const [s] = await db.query('SELECT id_siswa, nama_siswa FROM siswa WHERE id_user = ? LIMIT 1', [user.id_user]);
      if (s.length) { nama = s[0].nama_siswa; extraId = s[0].id_siswa; }
    }

    const payload = { id: user.id_user, role: user.role, extraId };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });

    res.json({
      success: true,
      message: 'Login berhasil',
      data: { id: user.id_user, role: user.role, nama, username: user.username, extraId, token },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
}

module.exports = { login };

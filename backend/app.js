const path = require('path');
// Path eksplisit: tanpa ini .env hanya terbaca kalau node dijalankan dari folder backend
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files (foto siswa, surat izin)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Serve APK download
app.use('/download', express.static(path.join(__dirname, 'downloads')));

// Routes
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/siswa', require('./src/routes/siswa'));
app.use('/api/absensi', require('./src/routes/absensi'));
app.use('/api/izin', require('./src/routes/izin'));
app.use('/api/akun', require('./src/routes/akun'));
app.use('/api/jadwal', require('./src/routes/jadwal'));
app.use('/api/kelas', require('./src/routes/kelas'));
app.use('/api/mata-pelajaran', require('./src/routes/mataPelajaran'));
app.use('/api/geofence', require('./src/routes/geofence'));

// Health check
app.get('/api/health', (_, res) => res.json({ status: 'ok', time: new Date() }));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.path} tidak ditemukan` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err);
  const status = err.status || 500;
  res.status(status).json({ success: false, message: err.message || 'Terjadi kesalahan server' });
});

// Only bind port when run directly (node app.js / nodemon).
// When required by tests or Phusion Passenger, skip listen().
if (require.main === module) {
  if (!process.env.JWT_SECRET) {
    console.error('[PERINGATAN] JWT_SECRET kosong: login akan gagal. Isi JWT_SECRET di backend/.env');
  }
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`Server berjalan di port ${PORT}`));
}

module.exports = app;

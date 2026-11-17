-- =============================================
-- SEED DATA UJI — KHUSUS DEVELOPMENT LOKAL
-- JANGAN dijalankan di database produksi (apismk.codingrame.com).
--
-- Dijalankan SETELAH database.sql. Aman di-run berulang kali: semua
-- INSERT memakai IGNORE dan bersandar pada UNIQUE KEY yang sudah ada,
-- jadi tidak akan menggandakan baris.
--
--   /d/xampp/mysql/bin/mysql.exe -u root absensi_smkn5 < seed_local.sql
--
-- Akun yang dihasilkan:
--   guru1  / guru123
--   siswa1 / siswa123   (terhubung ke siswa NIS 2024001)
--   admin  / admin123   (sudah dari database.sql)
-- =============================================

-- ============ AKUN GURU ============
INSERT IGNORE INTO users (username, password, role, status) VALUES
('guru1', '$2a$10$5/YeP35qgDW6jAi14NXdw.c1bbUOhPOlaverU2VjFRH/kIh.NuMaW', 'guru', 'aktif');

INSERT IGNORE INTO guru (id_user, nama, NIP, email, no_telepon, mata_pelajaran)
SELECT id_user, 'Budi Santoso', '198001012005011001', 'budi@smkn5.sch.id',
       '081200000001', 'Jaringan Komputer'
FROM users WHERE username = 'guru1';

-- ============ DATA SISWA ============
-- Dua siswa: satu nanti dipasangkan akun, satu sengaja dibiarkan tanpa akun
-- supaya filter "no_account=true" di Kelola Akun ada isinya saat diuji.
INSERT IGNORE INTO siswa (nama_siswa, NIS, kelas, jurusan, jenis_kelamin, alamat, no_telepon) VALUES
('Ahmad Fauzi',  '2024001', 'XI', 'TJKT', 'L', 'Jl. Kendari No. 1', '081200000011'),
('Siti Aminah',  '2024002', 'XI', 'TJKT', 'P', 'Jl. Kendari No. 2', '081200000012');

-- ============ AKUN SISWA ============
INSERT IGNORE INTO users (username, password, role, status) VALUES
('siswa1', '$2a$10$D.wAzLWY7qJsnmA1gqOEEeFUsuNIRn/oadru5e0d09WlS9sdWrQ2m', 'siswa', 'aktif');

UPDATE siswa
SET id_user = (SELECT id_user FROM users WHERE username = 'siswa1')
WHERE NIS = '2024001';

-- ============ JADWAL PELAJARAN ============
-- kelas & jurusan WAJIB sama persis dengan data siswa di atas — recognize()
-- mencocokkan kedua kolom itu sekaligus, salah satu beda = absen ditolak.
--
-- Rentang 06:00–17:00 untuk semua hari supaya absen bisa diuji kapan saja
-- selama jam kerja. Konsekuensinya status_waktu akan selalu terbaca 'telat'
-- (jam_mulai sudah lewat). Untuk menguji 'tepat_waktu', ubah jam_mulai salah
-- satu baris ke beberapa menit DI DEPAN waktu WITA sekarang.
INSERT IGNORE INTO jadwal_pelajaran (id_guru, kelas, jurusan, hari, jam_mulai, jam_selesai, mata_pelajaran)
SELECT g.id_guru, 'XI', 'TJKT', h.hari, '06:00:00', '17:00:00', 'Jaringan Komputer'
FROM guru g
CROSS JOIN (
  SELECT 'Senin' AS hari UNION ALL SELECT 'Selasa' UNION ALL SELECT 'Rabu'
  UNION ALL SELECT 'Kamis' UNION ALL SELECT 'Jumat' UNION ALL SELECT 'Sabtu'
) h
WHERE g.id_user = (SELECT id_user FROM users WHERE username = 'guru1');

-- ============ GEOFENCE: SENGAJA DIBIARKAN KOSONG ============
-- Tabel geofence kosong = absen tidak dibatasi lokasi (fail-open), jadi
-- pengujian di luar area sekolah tidak terblokir. Untuk menguji penolakan
-- geofence, isi lewat Admin > Pengaturan Geofencing di aplikasi.

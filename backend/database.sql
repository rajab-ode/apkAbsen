-- =============================================
-- SMK Negeri 5 Kendari — Absensi Face Recognition
-- Safe to re-run: drops and recreates all tables, so re-importing
-- into an already-provisioned database won't error out.
--
-- No CREATE DATABASE / USE here on purpose: shared cPanel hosting only
-- grants access to already-prefixed databases (e.g. lpka1362_absensi_smkn5),
-- so this file assumes a database is already selected — either via
-- phpMyAdmin (pick the DB before Import) or Docker's MYSQL_DATABASE env var.
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS geofence;
DROP TABLE IF EXISTS izin;
DROP TABLE IF EXISTS absensi;
DROP TABLE IF EXISTS jadwal_pelajaran;
DROP TABLE IF EXISTS siswa;
DROP TABLE IF EXISTS kelas;
DROP TABLE IF EXISTS mata_pelajaran;
DROP TABLE IF EXISTS guru;
DROP TABLE IF EXISTS admin;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- ============ USERS ============
CREATE TABLE users (
  id_user   INT AUTO_INCREMENT PRIMARY KEY,
  username  VARCHAR(50)  NOT NULL UNIQUE,
  password  VARCHAR(255) NOT NULL,
  role      ENUM('admin','guru','siswa') NOT NULL,
  status    ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============ ADMIN ============
CREATE TABLE admin (
  id_admin  INT AUTO_INCREMENT PRIMARY KEY,
  id_user   INT NOT NULL UNIQUE,
  nama      VARCHAR(100) NOT NULL,
  FOREIGN KEY (id_user) REFERENCES users(id_user) ON DELETE CASCADE
);

-- ============ KELAS (data master, dikelola admin) ============
CREATE TABLE kelas (
  id_kelas   INT AUTO_INCREMENT PRIMARY KEY,
  nama_kelas VARCHAR(30) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============ MATA PELAJARAN (data master, dikelola admin) ============
CREATE TABLE mata_pelajaran (
  id_mapel   INT AUTO_INCREMENT PRIMARY KEY,
  nama_mapel VARCHAR(100) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============ GURU ============
CREATE TABLE guru (
  id_guru        INT AUTO_INCREMENT PRIMARY KEY,
  id_user        INT NOT NULL UNIQUE,
  nama           VARCHAR(100) NOT NULL,
  NIP            VARCHAR(20),
  email          VARCHAR(100),
  no_telepon     VARCHAR(20),
  mata_pelajaran VARCHAR(100),
  FOREIGN KEY (id_user) REFERENCES users(id_user) ON DELETE CASCADE
);

-- ============ JADWAL PELAJARAN ============
CREATE TABLE jadwal_pelajaran (
  id_jadwal      INT AUTO_INCREMENT PRIMARY KEY,
  id_guru        INT NOT NULL,
  kelas          VARCHAR(20) NOT NULL,
  jurusan        VARCHAR(50) NOT NULL,
  hari           ENUM('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu') NOT NULL,
  jam_mulai      TIME NOT NULL,
  jam_selesai    TIME NOT NULL,
  mata_pelajaran VARCHAR(100) NOT NULL,
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_guru_kelas_jurusan_hari_jam (id_guru, kelas, jurusan, hari, jam_mulai),
  FOREIGN KEY (id_guru) REFERENCES guru(id_guru) ON DELETE CASCADE
);

-- ============ SISWA ============
CREATE TABLE siswa (
  id_siswa     INT AUTO_INCREMENT PRIMARY KEY,
  id_user      INT UNIQUE,
  nama_siswa   VARCHAR(100) NOT NULL,
  NIS          VARCHAR(20)  NOT NULL UNIQUE,
  kelas        VARCHAR(20),
  jurusan      VARCHAR(50),
  jenis_kelamin ENUM('L','P'),
  alamat       TEXT,
  no_telepon   VARCHAR(20),
  foto         VARCHAR(255),
  data_wajah   LONGTEXT,           -- JSON array 192 floats
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_user) REFERENCES users(id_user) ON DELETE SET NULL
);

-- ============ ABSENSI ============
CREATE TABLE absensi (
  id_absensi     INT AUTO_INCREMENT PRIMARY KEY,
  id_siswa       INT NOT NULL,
  tanggal        DATE NOT NULL,
  waktu          TIME NOT NULL,
  status         ENUM('hadir','izin','tidak_hadir') NOT NULL DEFAULT 'hadir',
  id_jadwal      INT,
  mata_pelajaran VARCHAR(100),
  status_waktu   ENUM('tepat_waktu','telat'),
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_siswa_tanggal_jadwal (id_siswa, tanggal, id_jadwal),
  FOREIGN KEY (id_siswa) REFERENCES siswa(id_siswa) ON DELETE CASCADE,
  FOREIGN KEY (id_jadwal) REFERENCES jadwal_pelajaran(id_jadwal) ON DELETE SET NULL
);

-- ============ IZIN ============
CREATE TABLE izin (
  id_izin    INT AUTO_INCREMENT PRIMARY KEY,
  id_siswa   INT NOT NULL,
  tanggal    DATE NOT NULL,
  jenis      ENUM('sakit','izin') NOT NULL,
  file_surat VARCHAR(255),
  status     ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_izin_siswa_tanggal (id_siswa, tanggal),
  FOREIGN KEY (id_siswa) REFERENCES siswa(id_siswa) ON DELETE CASCADE
);

-- ============ GEOFENCE (satu baris tetap, dikelola admin) ============
-- Sengaja tidak di-seed — kosong sampai admin mengisi. Selama kosong, absen
-- tidak dibatasi lokasi (fail-open), lihat absensiController.recognize().
CREATE TABLE geofence (
  id           INT PRIMARY KEY DEFAULT 1,
  latitude     DECIMAL(10,7) NOT NULL,
  longitude    DECIMAL(10,7) NOT NULL,
  radius_meter INT NOT NULL,
  updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_geofence_single_row CHECK (id = 1)
);

-- ============ SEED: Kelas ============
-- Kelas itu sendiri (tanpa jurusan — jurusan tersimpan terpisah di data siswa
-- & jadwal). Titik awal, admin bebas menambah/menghapus lewat Kelola Data Master.
INSERT INTO kelas (nama_kelas) VALUES ('X'), ('XI'), ('XII');

-- ============ SEED: Mata Pelajaran ============
INSERT INTO mata_pelajaran (nama_mapel) VALUES
('Jaringan Komputer'), ('Pemrograman'), ('Matematika'),
('Bahasa Indonesia'), ('Bahasa Inggris'), ('IPA'), ('IPS');

-- ============ SEED: Admin ============
-- Password: admin123  (bcrypt rounds=10)
INSERT INTO users (username, password, role, status) VALUES
('admin', '$2a$10$qLmrAK49mybsq0.LRgdpr.QA08wUF6zYnJn.K/Xb0UtDqQDjjp9Ty', 'admin', 'aktif');

INSERT INTO admin (id_user, nama) VALUES (1, 'Administrator');

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
DROP TABLE IF EXISTS izin;
DROP TABLE IF EXISTS absensi;
DROP TABLE IF EXISTS siswa;
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
  id_absensi INT AUTO_INCREMENT PRIMARY KEY,
  id_siswa   INT NOT NULL,
  tanggal    DATE NOT NULL,
  waktu      TIME NOT NULL,
  status     ENUM('hadir','izin','tidak_hadir') NOT NULL DEFAULT 'hadir',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_siswa_tanggal (id_siswa, tanggal),
  FOREIGN KEY (id_siswa) REFERENCES siswa(id_siswa) ON DELETE CASCADE
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

-- ============ SEED: Admin ============
-- Password: admin123  (bcrypt rounds=10)
INSERT INTO users (username, password, role, status) VALUES
('admin', '$2a$10$qLmrAK49mybsq0.LRgdpr.QA08wUF6zYnJn.K/Xb0UtDqQDjjp9Ty', 'admin', 'aktif');

INSERT INTO admin (id_user, nama) VALUES (1, 'Administrator');

-- =============================================
-- Migrasi: Mata Pelajaran sebagai data master (dikelola Admin)
-- Jalankan SEKALI di database PRODUKSI yang sudah berisi data.
-- Tidak ada DROP TABLE — aman, tidak menghapus data yang sudah ada.
-- =============================================

CREATE TABLE IF NOT EXISTS mata_pelajaran (
  id_mapel   INT AUTO_INCREMENT PRIMARY KEY,
  nama_mapel VARCHAR(100) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Seed dari mapel yang SUDAH dipakai (akun guru & jadwal), supaya data lama tidak yatim piatu
INSERT IGNORE INTO mata_pelajaran (nama_mapel)
SELECT DISTINCT mata_pelajaran FROM guru WHERE mata_pelajaran IS NOT NULL AND mata_pelajaran <> '';

INSERT IGNORE INTO mata_pelajaran (nama_mapel)
SELECT DISTINCT mata_pelajaran FROM jadwal_pelajaran WHERE mata_pelajaran IS NOT NULL AND mata_pelajaran <> '';

-- Seed titik awal standar
INSERT IGNORE INTO mata_pelajaran (nama_mapel) VALUES
('Jaringan Komputer'), ('Pemrograman'), ('Matematika'),
('Bahasa Indonesia'), ('Bahasa Inggris'), ('IPA'), ('IPS');

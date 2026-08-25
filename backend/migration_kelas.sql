-- =============================================
-- Migrasi: Kelas sebagai data master (dikelola Admin)
-- Jalankan SEKALI di database PRODUKSI yang sudah berisi data.
-- Tidak ada DROP TABLE — aman, tidak menghapus data yang sudah ada.
-- =============================================

CREATE TABLE IF NOT EXISTS kelas (
  id_kelas   INT AUTO_INCREMENT PRIMARY KEY,
  nama_kelas VARCHAR(30) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Seed dari kelas yang SUDAH dipakai siswa saat ini, supaya data lama tidak yatim piatu
INSERT IGNORE INTO kelas (nama_kelas)
SELECT DISTINCT kelas FROM siswa WHERE kelas IS NOT NULL AND kelas <> '';

-- Seed titik awal (kalau belum ada siswa sama sekali, atau mau tambah opsi standar)
INSERT IGNORE INTO kelas (nama_kelas) VALUES
('X TJKT'), ('X DKV'), ('X APHP'), ('X ATPH'), ('X APAT'),
('XI TJKT'), ('XI DKV'), ('XI APHP'), ('XI ATPH'), ('XI APAT'),
('XII TJKT'), ('XII DKV'), ('XII APHP'), ('XII ATPH'), ('XII APAT');

-- =============================================
-- Migrasi: Jadwal Pelajaran + Absen per Mapel + Telat/Tepat Waktu
-- Jalankan SEKALI di database PRODUKSI yang sudah berisi data (bukan database.sql!).
-- Tidak ada DROP TABLE di sini — aman, tidak menghapus data siswa/absensi yang sudah ada.
-- =============================================

CREATE TABLE IF NOT EXISTS jadwal_pelajaran (
  id_jadwal      INT AUTO_INCREMENT PRIMARY KEY,
  id_guru        INT NOT NULL,
  kelas          VARCHAR(20) NOT NULL,
  hari           ENUM('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu') NOT NULL,
  jam_mulai      TIME NOT NULL,
  jam_selesai    TIME NOT NULL,
  mata_pelajaran VARCHAR(100) NOT NULL,
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_guru_kelas_hari_jam (id_guru, kelas, hari, jam_mulai),
  FOREIGN KEY (id_guru) REFERENCES guru(id_guru) ON DELETE CASCADE
);

ALTER TABLE absensi
  ADD COLUMN id_jadwal INT NULL AFTER status,
  ADD COLUMN mata_pelajaran VARCHAR(100) NULL AFTER id_jadwal,
  ADD COLUMN status_waktu ENUM('tepat_waktu','telat') NULL AFTER mata_pelajaran,
  ADD FOREIGN KEY (id_jadwal) REFERENCES jadwal_pelajaran(id_jadwal) ON DELETE SET NULL,
  DROP INDEX uq_siswa_tanggal,
  ADD UNIQUE KEY uq_siswa_tanggal_jadwal (id_siswa, tanggal, id_jadwal);

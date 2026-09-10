-- =============================================
-- Migrasi: Geofencing untuk absen (satu titik lokasi sekolah)
-- Jalankan SEKALI di database PRODUKSI. Tidak ada DROP TABLE — aman.
--
-- Tabel ini sengaja dibiarkan kosong setelah migrasi — isi lewat Admin →
-- Pengaturan Geofencing di aplikasi. Selama kosong, absen tidak dibatasi
-- lokasi sama sekali (fail-open), jadi aman dijalankan kapan saja tanpa
-- mendadak memblokir siswa yang sedang aktif absen.
-- =============================================

CREATE TABLE IF NOT EXISTS geofence (
  id           INT PRIMARY KEY DEFAULT 1,
  latitude     DECIMAL(10,7) NOT NULL,
  longitude    DECIMAL(10,7) NOT NULL,
  radius_meter INT NOT NULL,
  updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_geofence_single_row CHECK (id = 1)
);

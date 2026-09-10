-- =============================================
-- Migrasi: Tambah kolom jurusan di jadwal_pelajaran
-- Jalankan SEKALI di database PRODUKSI, SETELAH migration_jadwal.sql.
-- Kelas dan Jurusan sekarang dua field terpisah (bukan digabung jadi satu
-- string kelas) — pencocokan absen membandingkan keduanya sekaligus, sama
-- seperti data siswa yang juga sudah punya kelas & jurusan terpisah.
-- =============================================

ALTER TABLE jadwal_pelajaran
  ADD COLUMN jurusan VARCHAR(50) NOT NULL DEFAULT '' AFTER kelas;

-- Jadwal lama (dibuat sebelum kolom ini ada) jurusannya kosong — perlu
-- diedit ulang manual lewat app (hapus, buat ulang dengan jurusan yang benar)
-- supaya bisa cocok ke siswa lagi.

-- Index baru dibuat DULU (dia juga menopang FK id_guru), baru index lama
-- boleh dihapus — kalau dibalik urutannya, MySQL menolak drop index lama
-- karena FK id_guru butuh index yang tersedia setiap saat
ALTER TABLE jadwal_pelajaran
  ADD UNIQUE KEY uq_guru_kelas_jurusan_hari_jam (id_guru, kelas, jurusan, hari, jam_mulai);
ALTER TABLE jadwal_pelajaran DROP INDEX uq_guru_kelas_hari_jam;

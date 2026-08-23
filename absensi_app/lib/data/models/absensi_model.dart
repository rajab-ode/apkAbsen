class AbsensiModel {
  final int idAbsensi;
  final String namaSiswa;
  final String nis;
  final String kelas;
  final String? fotoPath;
  final String tanggal;
  final String waktu;
  final String status;
  final String? mataPelajaran;
  final String? statusWaktu;

  const AbsensiModel({
    required this.idAbsensi,
    required this.namaSiswa,
    required this.nis,
    required this.kelas,
    this.fotoPath,
    required this.tanggal,
    required this.waktu,
    required this.status,
    this.mataPelajaran,
    this.statusWaktu,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> j) => AbsensiModel(
        idAbsensi: j['id_absensi'],
        namaSiswa: j['nama_siswa'] ?? '',
        nis: j['NIS'] ?? '',
        kelas: j['kelas'] ?? '',
        fotoPath: j['foto_path'] ?? j['foto'],
        tanggal: j['tanggal'] ?? '',
        waktu: j['waktu'] ?? '',
        status: j['status'] ?? 'hadir',
        mataPelajaran: j['mata_pelajaran'],
        statusWaktu: j['status_waktu'],
      );
}

class JadwalModel {
  final int idJadwal;
  final String kelas;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String mataPelajaran;

  const JadwalModel({
    required this.idJadwal,
    required this.kelas,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mataPelajaran,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> j) => JadwalModel(
        idJadwal: j['id_jadwal'],
        kelas: j['kelas'] ?? '',
        hari: j['hari'] ?? '',
        jamMulai: (j['jam_mulai'] ?? '').toString().substring(0, 5),
        jamSelesai: (j['jam_selesai'] ?? '').toString().substring(0, 5),
        mataPelajaran: j['mata_pelajaran'] ?? '',
      );
}

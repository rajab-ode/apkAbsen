class SiswaModel {
  final int idSiswa;
  final String namaSiswa;
  final String nis;
  final String jenisKelamin;
  final String kelas;
  final String jurusan;
  final String alamat;
  final String noTelepon;
  final String? fotoPath;
  final bool wajahTerdaftar;

  const SiswaModel({
    required this.idSiswa,
    required this.namaSiswa,
    required this.nis,
    required this.jenisKelamin,
    required this.kelas,
    required this.jurusan,
    required this.alamat,
    required this.noTelepon,
    this.fotoPath,
    required this.wajahTerdaftar,
  });

  String get jenisKelaminLabel =>
      jenisKelamin == 'L' ? 'Laki-laki' : jenisKelamin == 'P' ? 'Perempuan' : jenisKelamin;

  factory SiswaModel.fromJson(Map<String, dynamic> j) => SiswaModel(
        idSiswa: j['id_siswa'],
        namaSiswa: j['nama_siswa'],
        nis: j['NIS'],
        jenisKelamin: j['jenis_kelamin'] ?? '',
        kelas: j['kelas'] ?? '',
        jurusan: j['jurusan'] ?? '',
        alamat: j['alamat'] ?? '',
        noTelepon: j['no_telepon'] ?? '',
        fotoPath: j['foto'] != null ? '${j['foto']}' : null,
        // Backend mengirim flag wajah_terdaftar (MySQL: 0/1), bukan embedding mentahnya
        wajahTerdaftar: j['wajah_terdaftar'] == 1 ||
            j['wajah_terdaftar'] == true ||
            j['data_wajah'] != null,
      );
}

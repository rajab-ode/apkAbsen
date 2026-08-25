class KelasModel {
  final int idKelas;
  final String namaKelas;

  const KelasModel({required this.idKelas, required this.namaKelas});

  factory KelasModel.fromJson(Map<String, dynamic> j) => KelasModel(
        idKelas: j['id_kelas'],
        namaKelas: j['nama_kelas'] ?? '',
      );
}

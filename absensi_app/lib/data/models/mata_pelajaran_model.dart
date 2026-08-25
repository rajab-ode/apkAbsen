class MataPelajaranModel {
  final int idMapel;
  final String namaMapel;

  const MataPelajaranModel({required this.idMapel, required this.namaMapel});

  factory MataPelajaranModel.fromJson(Map<String, dynamic> j) => MataPelajaranModel(
        idMapel: j['id_mapel'],
        namaMapel: j['nama_mapel'] ?? '',
      );
}

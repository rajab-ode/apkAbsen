class IzinModel {
  final int idIzin;
  final String namaSiswa;
  final String nis;
  final String tanggal;
  final String jenis;
  final String? fileSurat;
  final String status;

  const IzinModel({
    required this.idIzin,
    required this.namaSiswa,
    required this.nis,
    required this.tanggal,
    required this.jenis,
    this.fileSurat,
    required this.status,
  });

  factory IzinModel.fromJson(Map<String, dynamic> j) => IzinModel(
        idIzin: j['id_izin'],
        namaSiswa: j['nama_siswa'] ?? '',
        nis: j['NIS'] ?? '',
        tanggal: j['tanggal'] ?? '',
        jenis: j['jenis'] ?? '',
        fileSurat: j['file_surat'],
        status: j['status'] ?? 'pending',
      );
}

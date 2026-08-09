class AkunModel {
  final int id;
  final String nama;
  final String peran;
  final String nisNip;
  final String username;
  final String status;
  final String? email;
  final String? noTelepon;
  final String? kelas;
  final String? mataPelajaran;

  const AkunModel({
    required this.id,
    required this.nama,
    required this.peran,
    required this.nisNip,
    required this.username,
    required this.status,
    this.email,
    this.noTelepon,
    this.kelas,
    this.mataPelajaran,
  });

  factory AkunModel.fromJson(Map<String, dynamic> j) => AkunModel(
        id: j['id_user'],
        nama: j['nama'] ?? '',
        peran: j['role'] ?? '',
        nisNip: j['nis_nip'] ?? '',
        username: j['username'],
        status: j['status'] ?? 'Aktif',
        email: j['email'],
        noTelepon: j['no_telepon'],
        kelas: j['kelas'],
        mataPelajaran: j['mata_pelajaran'],
      );
}

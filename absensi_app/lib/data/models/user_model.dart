class UserModel {
  final int id;
  final String username;
  final String role;
  final String nama;
  final String token;
  final int? extraId; // id_siswa untuk siswa, id_guru untuk guru

  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.nama,
    required this.token,
    this.extraId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        username: json['username'],
        role: json['role'],
        nama: json['nama'] ?? '',
        token: json['token'] ?? '',
        extraId: json['extraId'],
      );

  bool get isAdmin => role == 'admin';
  bool get isGuru => role == 'guru';
  bool get isSiswa => role == 'siswa';
}

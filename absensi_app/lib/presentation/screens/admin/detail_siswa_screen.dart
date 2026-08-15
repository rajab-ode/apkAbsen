import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/siswa_model.dart';
import '../../../data/services/siswa_service.dart';
import 'tambah_siswa_screen.dart';

class DetailSiswaScreen extends StatefulWidget {
  final int idSiswa;
  const DetailSiswaScreen({super.key, required this.idSiswa});

  @override
  State<DetailSiswaScreen> createState() => _DetailSiswaScreenState();
}

class _DetailSiswaScreenState extends State<DetailSiswaScreen> {
  final _service = SiswaService();
  SiswaModel? _siswa;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _service.getById(widget.idSiswa);
      if (mounted) setState(() { _siswa = s; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hapus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: const Text('Yakin ingin menghapus data siswa ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.delete(widget.idSiswa);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _edit() async {
    if (_siswa == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahSiswaScreen(existingData: {
          'id_siswa': _siswa!.idSiswa,
          'nama_siswa': _siswa!.namaSiswa,
          'NIS': _siswa!.nis,
          'kelas': _siswa!.kelas,
          'jurusan': _siswa!.jurusan,
          'jenis_kelamin': _siswa!.jenisKelamin,
          'alamat': _siswa!.alamat,
          'no_telepon': _siswa!.noTelepon,
        }),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Siswa')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _siswa == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _siswa!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Banner status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                const Text('Data siswa ini telah terdaftar di sistem',
                    style: TextStyle(color: AppTheme.success, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Foto & nama
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(s.namaSiswa,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('NIS: ${s.nis}',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (s.wajahTerdaftar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined, size: 14, color: AppTheme.success),
                          SizedBox(width: 4),
                          Text('Wajah Terdaftar',
                              style: TextStyle(fontSize: 12, color: AppTheme.success)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detail info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person_outline, 'Nama Lengkap', s.namaSiswa),
                  _buildDivider(),
                  _buildInfoRow(Icons.badge_outlined, 'NIS', s.nis),
                  _buildDivider(),
                  _buildInfoRow(Icons.wc_outlined, 'Jenis Kelamin', s.jenisKelamin),
                  _buildDivider(),
                  _buildInfoRow(Icons.class_outlined, 'Kelas', s.kelas),
                  _buildDivider(),
                  _buildInfoRow(Icons.school_outlined, 'Jurusan', s.jurusan),
                  _buildDivider(),
                  _buildInfoRow(Icons.location_on_outlined, 'Alamat', s.alamat),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Catatan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data ini digunakan untuk keperluan absensi dan verifikasi wajah siswa',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _hapus,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus Akun'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          const Text(': ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade200);
}

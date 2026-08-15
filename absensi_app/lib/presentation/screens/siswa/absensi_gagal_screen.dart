import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'daftar_wajah_screen.dart';

class AbsensiGagalScreen extends StatelessWidget {
  final String pesan;
  const AbsensiGagalScreen({super.key, required this.pesan});

  bool get _isWajahBelumTerdaftar =>
      pesan.toLowerCase().contains('wajah') &&
      (pesan.toLowerCase().contains('belum') || pesan.toLowerCase().contains('terdaftar'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_off,
                  size: 48,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Absensi Gagal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pesan,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pastikan:\n• Wajah berada tepat di dalam frame\n• Pencahayaan ruangan cukup terang\n• Wajah Anda sudah terdaftar di sistem',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.8,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/siswa/absensi', (_) => false),
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Coba Lagi'),
                ),
              ),
              if (_isWajahBelumTerdaftar) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DaftarWajahScreen()),
                    ),
                    icon: const Icon(Icons.face_outlined),
                    label: const Text('Daftarkan Wajah Sekarang'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/siswa/absensi', (_) => false),
                  child: const Text('Kembali ke Beranda'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

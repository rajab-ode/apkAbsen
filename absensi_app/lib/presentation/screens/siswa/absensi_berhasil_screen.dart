import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/absensi_model.dart';

class AbsensiBerhasilScreen extends StatelessWidget {
  final AbsensiModel absensi;
  const AbsensiBerhasilScreen({super.key, required this.absensi});

  String _formatTanggal(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

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
              _buildSuccessIcon(),
              const SizedBox(height: 20),
              const Text(
                'Absensi Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Terima kasih, absensi anda telah dicatat',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildDetailCard(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/siswa/absensi', (_) => false),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Kembali ke Beranda'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 52,
        color: AppTheme.success,
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: absensi.fotoPath != null
                  ? NetworkImage('${AppConstants.serverUrl}/uploads/${absensi.fotoPath}')
                  : null,
              child: absensi.fotoPath == null
                  ? const Icon(Icons.person, size: 42, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            _buildRow(Icons.person_outline, 'Nama', absensi.namaSiswa),
            _buildDivider(),
            _buildRow(Icons.calendar_today_outlined, 'Tanggal', _formatTanggal(absensi.tanggal)),
            _buildDivider(),
            _buildRow(Icons.access_time_outlined, 'Waktu', '${absensi.waktu} WIB'),
            _buildDivider(),
            _buildRow(
              Icons.circle,
              'Status',
              absensi.status[0].toUpperCase() + absensi.status.substring(1),
              valueColor: AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          const Text(' : ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade200);
}

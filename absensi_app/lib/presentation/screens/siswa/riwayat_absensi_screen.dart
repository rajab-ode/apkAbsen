import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/absensi_model.dart';
import '../../../data/services/absensi_service.dart';
import '../../../data/services/auth_provider.dart';

class RiwayatAbsensiScreen extends StatefulWidget {
  const RiwayatAbsensiScreen({super.key});

  @override
  State<RiwayatAbsensiScreen> createState() => _RiwayatAbsensiScreenState();
}

class _RiwayatAbsensiScreenState extends State<RiwayatAbsensiScreen> {
  final _service = AbsensiService();
  List<AbsensiModel> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final idSiswa = user?.extraId ?? user?.id ?? 0;
      final data = await _service.getMySiswa(idSiswa);
      if (mounted) setState(() { _list = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir':  return AppTheme.success;
      case 'izin':   return AppTheme.warning;
      default:       return AppTheme.error;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'hadir':  return Icons.check_circle_outline;
      case 'izin':   return Icons.access_time_outlined;
      default:       return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildCard(_list[i]),
                ),
    );
  }

  Widget _buildCard(AbsensiModel a) {
    final color = _statusColor(a.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(a.status), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTanggal(a.tanggal),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  a.mataPelajaran != null ? '${a.waktu} WITA · ${a.mataPelajaran}' : '${a.waktu} WITA',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (a.statusWaktu != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    a.statusWaktu == 'telat' ? 'Terlambat' : 'Tepat Waktu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: a.statusWaktu == 'telat' ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              a.status[0].toUpperCase() + a.status.substring(1),
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Belum ada riwayat absensi',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

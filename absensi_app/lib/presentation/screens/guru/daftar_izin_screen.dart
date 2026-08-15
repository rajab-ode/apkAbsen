import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/izin_model.dart';
import '../../../data/services/izin_service.dart';

class DaftarIzinScreen extends StatefulWidget {
  const DaftarIzinScreen({super.key});

  @override
  State<DaftarIzinScreen> createState() => _DaftarIzinScreenState();
}

class _DaftarIzinScreenState extends State<DaftarIzinScreen>
    with SingleTickerProviderStateMixin {
  final _service = IzinService();
  late TabController _tabCtrl;

  List<IzinModel> _all = [];
  bool _isLoading = true;

  final _tabs = const ['Semua', 'Pending', 'Disetujui', 'Ditolak'];
  final _statusMap = {
    'Semua': null,
    'Pending': 'pending',
    'Disetujui': 'approved',
    'Ditolak': 'rejected',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();
      if (mounted) {
        setState(() {
          _all = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<IzinModel> _filtered(String? status) {
    if (status == null) return _all;
    return _all.where((i) => i.status == status).toList();
  }

  Future<void> _updateStatus(IzinModel izin, String newStatus) async {
    final label = newStatus == 'approved' ? 'menyetujui' : 'menolak';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newStatus == 'approved' ? 'Setujui Izin' : 'Tolak Izin'),
        content: Text('Apakah Anda yakin ingin $label izin ${izin.namaSiswa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'approved' ? AppTheme.success : AppTheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus == 'approved' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.updateStatus(izin.idIzin, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newStatus == 'approved' ? 'Izin disetujui' : 'Izin ditolak'),
          backgroundColor: newStatus == 'approved' ? AppTheme.success : AppTheme.error,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin Siswa'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: _tabs.map((t) {
                final items = _filtered(_statusMap[t]);
                return _buildTabContent(items);
              }).toList(),
            ),
    );
  }

  Widget _buildTabContent(List<IzinModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text('Tidak ada pengajuan izin',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(IzinModel izin) {
    final statusColor = izin.status == 'approved'
        ? AppTheme.success
        : izin.status == 'rejected'
            ? AppTheme.error
            : AppTheme.warning;
    final statusLabel = izin.status == 'approved'
        ? 'Disetujui'
        : izin.status == 'rejected'
            ? 'Ditolak'
            : 'Pending';
    final jenisLabel = izin.jenis == 'sakit' ? 'Sakit' : 'Izin';
    final jenisColor = izin.jenis == 'sakit' ? AppTheme.error : AppTheme.warning;

    String tanggalFormatted = izin.tanggal;
    try {
      tanggalFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID')
          .format(DateTime.parse(izin.tanggal));
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(izin.namaSiswa,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('NIS: ${izin.nis}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(jenisLabel, jenisColor),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(tanggalFormatted,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
                if (izin.fileSurat != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openSurat(izin.fileSurat!),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf,
                            size: 16, color: AppTheme.error.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        const Text('Lihat Surat Izin',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (izin.status == 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(izin, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 38),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(izin, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 38),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Setujui', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _openSurat(String filePath) async {
    final url = '${AppConstants.serverUrl}/uploads/$filePath';
    final fileName = filePath.split('/').last;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh surat izin...')),
    );

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Gagal mengunduh file');

      final dir = await getTemporaryDirectory();
      final localFile = File('${dir.path}/$fileName');
      await localFile.writeAsBytes(response.bodyBytes);

      final result = await OpenFile.open(localFile.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka file: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka surat: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

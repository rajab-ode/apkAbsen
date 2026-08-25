import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/jadwal_model.dart';
import '../../../data/services/jadwal_service.dart';

class JadwalSayaScreen extends StatefulWidget {
  const JadwalSayaScreen({super.key});

  @override
  State<JadwalSayaScreen> createState() => _JadwalSayaScreenState();
}

class _JadwalSayaScreenState extends State<JadwalSayaScreen> {
  List<JadwalModel> _list = [];
  bool _isLoading = true;

  final _hariOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await JadwalService().getForSiswa();
      if (mounted) setState(() { _list = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<JadwalModel>> get _grouped {
    final map = <String, List<JadwalModel>>{};
    for (final j in _list) {
      map.putIfAbsent(j.hari, () => []).add(j);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final hariWithJadwal = _hariOrder.where((h) => grouped.containsKey(h)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Saya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hariWithJadwal.length,
                  itemBuilder: (_, i) {
                    final hari = hariWithJadwal[i];
                    return _buildHariSection(hari, grouped[hari]!);
                  },
                ),
    );
  }

  Widget _buildHariSection(String hari, List<JadwalModel> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hari, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary)),
          const SizedBox(height: 8),
          ...items.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${j.jamMulai}\n${j.jamSelesai}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(j.mataPelajaran, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            if (j.namaGuru != null) ...[
                              const SizedBox(height: 2),
                              Text(j.namaGuru!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Belum ada jadwal pelajaran', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Jadwal akan muncul setelah guru mengisi jadwal kelas Anda',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

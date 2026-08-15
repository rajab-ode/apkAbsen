import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/siswa_model.dart';
import '../../../data/services/siswa_service.dart';
import 'detail_siswa_screen.dart';
import 'tambah_siswa_screen.dart';

class KelolaDatabaseScreen extends StatefulWidget {
  const KelolaDatabaseScreen({super.key});

  @override
  State<KelolaDatabaseScreen> createState() => _KelolaDatabaseScreenState();
}

class _KelolaDatabaseScreenState extends State<KelolaDatabaseScreen> {
  final _service = SiswaService();
  final _searchCtrl = TextEditingController();
  List<SiswaModel> _list = [];
  bool _isLoading = true;
  int _total = 0;
  int _page = 1;
  int _totalPages = 1;
  String _search = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getPaginated(
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _list = result['data'];
          _total = result['total'];
          _totalPages = result['totalPages'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search = v;
      _page = 1;
      _load();
    });
  }

  Future<void> _hapus(SiswaModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text('Hapus data ${s.namaSiswa}?'),
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
    if (confirm != true) return;
    try {
      await _service.delete(s.idSiswa);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mengelola Database')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Cari NIS atau nama siswa',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Siswa', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              Text('$_total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.download_outlined, color: AppTheme.primary),
                      onPressed: () {},
                      tooltip: 'Export',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Header tabel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey.shade100,
            child: const Row(
              children: [
                SizedBox(width: 60, child: Text('NIS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(width: 90, child: Text('Nama', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(width: 40, child: Text('Kelas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(width: 50, child: Text('Jurusan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : ListView.separated(
                        itemCount: _list.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) => _buildRow(_list[i]),
                      ),
          ),

          if (_totalPages > 1) _buildPagination(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRow(SiswaModel s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(s.nis, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 90, child: Text(s.namaSiswa, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 40, child: Text(s.kelas, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 50, child: Text(s.jurusan, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionBtn('Lihat', Icons.visibility_outlined, AppTheme.primary, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DetailSiswaScreen(idSiswa: s.idSiswa),
                  )).then((_) => _load());
                }),
                const SizedBox(width: 4),
                _actionBtn('Edit', Icons.edit_outlined, AppTheme.warning, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TambahSiswaScreen(existingData: {
                      'id_siswa': s.idSiswa, 'nama_siswa': s.namaSiswa,
                      'NIS': s.nis, 'kelas': s.kelas, 'jurusan': s.jurusan,
                      'jenis_kelamin': s.jenisKelamin, 'alamat': s.alamat,
                      'no_telepon': s.noTelepon,
                    }),
                  )).then((r) { if (r == true) _load(); });
                }),
                const SizedBox(width: 4),
                _actionBtn('Hapus', Icons.delete_outline, AppTheme.error, () => _hapus(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Menampilkan ${(_page - 1) * 9 + 1}–${(_page * 9).clamp(0, _total)} dari $_total data',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
          ),
          Text('$_page / $_totalPages', style: const TextStyle(fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages ? () { setState(() => _page++); _load(); } : null,
          ),
        ],
      ),
    );
  }
}

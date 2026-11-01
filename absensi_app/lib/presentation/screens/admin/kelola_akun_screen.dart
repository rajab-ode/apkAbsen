import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/akun_model.dart';
import '../../../data/services/akun_service.dart';
import 'tambah_akun_screen.dart';

class KelolaAkunScreen extends StatefulWidget {
  const KelolaAkunScreen({super.key});

  @override
  State<KelolaAkunScreen> createState() => _KelolaAkunScreenState();
}

class _KelolaAkunScreenState extends State<KelolaAkunScreen>
    with SingleTickerProviderStateMixin {
  final _service = AkunService();
  final _searchCtrl = TextEditingController();

  late TabController _tabCtrl;
  List<AkunModel> _list = [];
  bool _isLoading = true;
  int _page = 1;
  int _totalPages = 1;
  int _totalGuru = 0;
  int _totalSiswa = 0;
  String _search = '';
  String _activeRole = 'semua';
  Timer? _debounce;

  final _tabs = ['Semua', 'Guru', 'Siswa'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _activeRole = _tabs[_tabCtrl.index].toLowerCase();
          _page = 1;
        });
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getPaginated(
        search: _search.isEmpty ? null : _search,
        role: _activeRole,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _list = result['data'];
          _totalPages = result['totalPages'];
          _totalGuru = result['totalGuru'];
          _totalSiswa = result['totalSiswa'];
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

  Future<void> _edit(AkunModel akun) async {
    final namaCtrl = TextEditingController(text: akun.nama);
    final passCtrl = TextEditingController();
    String status = akun.status;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Edit Akun — ${akun.nama}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru (kosongkan jika tidak diganti)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                    ],
                    onChanged: (v) { if (v != null) setDlg(() => status = v); },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (confirm != true) return;
    try {
      final body = <String, dynamic>{
        'nama': namaCtrl.text.trim(),
        'status': status,
        if (passCtrl.text.isNotEmpty) 'password': passCtrl.text.trim(),
      };
      await _service.update(akun.id, body);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _hapus(AkunModel akun) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text('Hapus akun ${akun.nama}?'),
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
      await _service.delete(akun.id);
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
      appBar: AppBar(title: const Text('Kelola Akun Pengguna')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Guru', _totalGuru, Icons.school_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Siswa', _totalSiswa, Icons.person_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('Total Pengguna', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      Text('${_totalGuru + _totalSiswa}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Cari nama, NIP atau NIS',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TambahAkunScreen()),
                      ).then((r) { if (r == true) _load(); }),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
          ),

          // Header tabel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Nama', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(width: 50, child: Text('Peran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(flex: 2, child: Text('NIS/NIP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(width: 40, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(flex: 2, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
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

  Widget _buildStatCard(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Akun Aktif', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(AkunModel a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(a.nama, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (a.peran == 'guru' ? Colors.blue : Colors.green).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                a.peran == 'guru' ? 'Guru' : 'Siswa',
                style: TextStyle(
                  fontSize: 10,
                  color: a.peran == 'guru' ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(a.nisNip, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (a.status == 'aktif' ? AppTheme.success : AppTheme.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              a.status == 'aktif' ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: a.status == 'aktif' ? AppTheme.success : AppTheme.error,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _actionBtn('Edit', Icons.edit_outlined, AppTheme.warning, () => _edit(a)),
                const SizedBox(width: 4),
                _actionBtn('Hapus', Icons.delete_outline, AppTheme.error, () => _hapus(a)),
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

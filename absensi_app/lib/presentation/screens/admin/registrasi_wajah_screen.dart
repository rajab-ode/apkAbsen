import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/siswa_model.dart';
import '../../../data/services/siswa_service.dart';
import 'registrasi_wajah_kamera_screen.dart';

class RegistrasiWajahScreen extends StatefulWidget {
  const RegistrasiWajahScreen({super.key});

  @override
  State<RegistrasiWajahScreen> createState() => _RegistrasiWajahScreenState();
}

class _RegistrasiWajahScreenState extends State<RegistrasiWajahScreen> {
  final _service = SiswaService();
  final _searchCtrl = TextEditingController();
  List<SiswaModel> _siswaList = [];
  bool _isLoading = true;
  String _search = '';
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
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
          _siswaList = result['data'];
          _totalPages = result['totalPages'];
          _total = result['total'];
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

  void _changePage(int page) {
    _page = page;
    _load();
  }

  Future<void> _registrasi(SiswaModel siswa) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrasiWajahKameraScreen(siswa: siswa),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Wajah Siswa')),
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
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch('');
                            })
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
                              Text('$_total',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.face_retouching_natural, color: AppTheme.primary, size: 32),
                  ],
                ),
              ],
            ),
          ),

          // Header tabel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: const Row(
              children: [
                SizedBox(width: 80, child: Text('NIS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(child: Text('Nama', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _siswaList.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        itemCount: _siswaList.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) => _buildRow(_siswaList[i]),
                      ),
          ),
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1 ? () => _changePage(_page - 1) : null,
                  ),
                  Text('$_page / $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _page < _totalPages ? () => _changePage(_page + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(SiswaModel s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(s.nis, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(s.namaSiswa, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _registrasi(s),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Ubah', style: TextStyle(fontSize: 12)),
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
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Belum ada data lainnya', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Data siswa yang terdaftar akan muncul di sini',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

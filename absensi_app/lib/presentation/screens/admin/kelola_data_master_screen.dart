import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/kelas_model.dart';
import '../../../data/models/mata_pelajaran_model.dart';
import '../../../data/services/kelas_service.dart';
import '../../../data/services/mata_pelajaran_service.dart';

class KelolaDataMasterScreen extends StatefulWidget {
  const KelolaDataMasterScreen({super.key});

  @override
  State<KelolaDataMasterScreen> createState() => _KelolaDataMasterScreenState();
}

class _KelolaDataMasterScreenState extends State<KelolaDataMasterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Master'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Kelas'), Tab(text: 'Mata Pelajaran')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [_KelasTab(), _MapelTab()],
      ),
    );
  }
}

class _KelasTab extends StatefulWidget {
  const _KelasTab();
  @override
  State<_KelasTab> createState() => _KelasTabState();
}

class _KelasTabState extends State<_KelasTab> {
  final _service = KelasService();
  List<KelasModel> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();
      if (mounted) setState(() { _list = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tambah() async {
    final ctrl = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kelas'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Mis. XI A, XI TJKT 1'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (nama == null || nama.isEmpty) return;
    try {
      await _service.create(nama);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _hapus(KelasModel k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: Text('Hapus kelas "${k.namaKelas}"?'),
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
      await _service.delete(k.idKelas);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('Belum ada data kelas'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildRow(_list[i].namaKelas, () => _hapus(_list[i])),
                ),
      floatingActionButton: FloatingActionButton(onPressed: _tambah, child: const Icon(Icons.add)),
    );
  }

  Widget _buildRow(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _MapelTab extends StatefulWidget {
  const _MapelTab();
  @override
  State<_MapelTab> createState() => _MapelTabState();
}

class _MapelTabState extends State<_MapelTab> {
  final _service = MataPelajaranService();
  List<MataPelajaranModel> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();
      if (mounted) setState(() { _list = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tambah() async {
    final ctrl = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Mata Pelajaran'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Mis. Kimia'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (nama == null || nama.isEmpty) return;
    try {
      await _service.create(nama);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _hapus(MataPelajaranModel m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mata Pelajaran'),
        content: Text('Hapus mata pelajaran "${m.namaMapel}"?'),
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
      await _service.delete(m.idMapel);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('Belum ada data mata pelajaran'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildRow(_list[i].namaMapel, () => _hapus(_list[i])),
                ),
      floatingActionButton: FloatingActionButton(onPressed: _tambah, child: const Icon(Icons.add)),
    );
  }

  Widget _buildRow(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), onPressed: onDelete),
        ],
      ),
    );
  }
}

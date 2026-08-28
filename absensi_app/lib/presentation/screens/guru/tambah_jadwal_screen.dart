import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/kelas_model.dart';
import '../../../data/models/mata_pelajaran_model.dart';
import '../../../data/services/jadwal_service.dart';
import '../../../data/services/kelas_service.dart';
import '../../../data/services/mata_pelajaran_service.dart';

class TambahJadwalScreen extends StatefulWidget {
  const TambahJadwalScreen({super.key});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  bool _isLoadingMaster = true;
  bool _isLoading = false;

  List<KelasModel> _kelasList = [];
  List<MataPelajaranModel> _mapelList = [];

  int? _idKelas;
  String _jurusan = 'TJKT';
  int? _idMapel;
  final Set<String> _selectedHari = {};
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  final _hariOptions = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  final _jurusanList = ['TJKT', 'DKV', 'APHP', 'ATPH', 'APAT'];

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    try {
      final results = await Future.wait([
        KelasService().getAll(),
        MataPelajaranService().getAll(),
      ]);
      if (mounted) {
        setState(() {
          _kelasList = results[0] as List<KelasModel>;
          _mapelList = results[1] as List<MataPelajaranModel>;
          _isLoadingMaster = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMaster = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickJam(bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isMulai ? _jamMulai : _jamSelesai) ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isMulai) {
        _jamMulai = picked;
      } else {
        _jamSelesai = picked;
      }
    });
  }

  Future<void> _simpan() async {
    if (_idKelas == null || _idMapel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih kelas dan mata pelajaran'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    if (_selectedHari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih minimal 1 hari'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    if (_jamMulai == null || _jamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih jam mulai dan jam selesai'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    final mulaiMin = _jamMulai!.hour * 60 + _jamMulai!.minute;
    final selesaiMin = _jamSelesai!.hour * 60 + _jamSelesai!.minute;
    if (selesaiMin <= mulaiMin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jam selesai harus setelah jam mulai'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    final kelas = _kelasList.firstWhere((k) => k.idKelas == _idKelas).namaKelas;
    final mapel = _mapelList.firstWhere((m) => m.idMapel == _idMapel).namaMapel;

    setState(() => _isLoading = true);
    try {
      final result = await JadwalService().create({
        'kelas': kelas,
        'jurusan': _jurusan,
        'hari': _selectedHari.toList(),
        'jam_mulai': _fmt(_jamMulai!),
        'jam_selesai': _fmt(_jamSelesai!),
        'mata_pelajaran': mapel,
      });
      if (mounted) {
        final duplikat = (result['data']?['duplikat'] as List?) ?? [];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Jadwal berhasil ditambahkan'),
          backgroundColor: duplikat.isNotEmpty ? AppTheme.warning : AppTheme.success,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Jadwal Mengajar')),
      body: _isLoadingMaster
          ? const Center(child: CircularProgressIndicator())
          : _kelasList.isEmpty || _mapelList.isEmpty
              ? _buildMasterKosong()
              : _buildForm(),
    );
  }

  Widget _buildMasterKosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _kelasList.isEmpty
                  ? 'Belum ada data Kelas. Minta admin menambahkan lewat menu Kelola Data Master.'
                  : 'Belum ada data Mata Pelajaran. Minta admin menambahkan lewat menu Kelola Data Master.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _idMapel,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.menu_book_outlined), hintText: 'Pilih mata pelajaran'),
            items: _mapelList.map((m) => DropdownMenuItem(value: m.idMapel, child: Text(m.namaMapel))).toList(),
            onChanged: (v) => setState(() => _idMapel = v),
          ),
          const SizedBox(height: 14),
          const Text('Kelas', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _idKelas,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.class_outlined), hintText: 'Pilih kelas'),
            items: _kelasList.map((k) => DropdownMenuItem(value: k.idKelas, child: Text(k.namaKelas))).toList(),
            onChanged: (v) => setState(() => _idKelas = v),
          ),
          const SizedBox(height: 14),
          const Text('Jurusan', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _jurusan,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
            items: _jurusanList.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
            onChanged: (v) => setState(() => _jurusan = v!),
          ),
          const SizedBox(height: 14),
          const Text('Hari', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 2),
          Text('Bisa pilih lebih dari satu', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hariOptions.map((h) {
              final selected = _selectedHari.contains(h);
              return FilterChip(
                label: Text(h),
                selected: selected,
                onSelected: (v) => setState(() => v ? _selectedHari.add(h) : _selectedHari.remove(h)),
                selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(color: selected ? AppTheme.primary : null, fontWeight: selected ? FontWeight.w600 : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildJamPicker('Jam Mulai', _jamMulai, () => _pickJam(true))),
              const SizedBox(width: 10),
              Expanded(child: _buildJamPicker('Jam Selesai', _jamSelesai, () => _pickJam(false))),
            ],
          ),
          const SizedBox(height: 28),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Jadwal'),
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildJamPicker(String label, TimeOfDay? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time_outlined)),
            child: Text(value != null ? _fmt(value) : 'Pilih jam'),
          ),
        ),
      ],
    );
  }
}

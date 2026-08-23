import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/jadwal_service.dart';

class TambahJadwalScreen extends StatefulWidget {
  const TambahJadwalScreen({super.key});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapelCtrl = TextEditingController();

  String _kelas = 'XI';
  String _jurusan = 'TJKT';
  String _hari = 'Senin';
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  bool _isLoading = false;

  final _kelasList = ['X', 'XI', 'XII'];
  final _jurusanList = ['TJKT', 'DKV', 'APHP', 'ATPH', 'APAT'];
  final _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void dispose() {
    _mapelCtrl.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;
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

    setState(() => _isLoading = true);
    try {
      await JadwalService().create({
        'kelas': '$_kelas $_jurusan',
        'hari': _hari,
        'jam_mulai': _fmt(_jamMulai!),
        'jam_selesai': _fmt(_jamSelesai!),
        'mata_pelajaran': _mapelCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Jadwal berhasil ditambahkan'),
          backgroundColor: AppTheme.success,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _mapelCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.menu_book_outlined),
                  hintText: 'Mis. Matematika',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Mata pelajaran tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),
              const Text('Kelas', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _kelas,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.class_outlined)),
                      items: _kelasList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _kelas = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _jurusan,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
                      items: _jurusanList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _jurusan = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Hari', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _hari,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined)),
                items: _hariList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _hari = v!),
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
        ),
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

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/siswa_service.dart';

class TambahSiswaScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  const TambahSiswaScreen({super.key, this.existingData});

  @override
  State<TambahSiswaScreen> createState() => _TambahSiswaScreenState();
}

class _TambahSiswaScreenState extends State<TambahSiswaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _nisCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();

  String _kelas = 'XI';
  String _jurusan = 'TJKT';
  String _jenisKelamin = 'Laki-laki';
  File? _foto;
  bool _isLoading = false;

  final _kelasList = ['X', 'XI', 'XII'];
  final _jurusanList = ['TJKT', 'DKV', 'APHP', 'ATPH', 'APAT'];
  final _jenisKelaminList = ['Laki-laki', 'Perempuan'];

  bool get isEdit => widget.existingData != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final d = widget.existingData!;
      _namaCtrl.text = d['nama_siswa'] ?? '';
      _nisCtrl.text = d['NIS'] ?? '';
      _alamatCtrl.text = d['alamat'] ?? '';
      _teleponCtrl.text = d['no_telepon'] ?? '';
      _kelas = d['kelas'] ?? 'XI';
      _jurusan = d['jurusan'] ?? 'TJKT';
      final jk = d['jenis_kelamin'];
      _jenisKelamin = (jk == 'L') ? 'Laki-laki' : (jk == 'P') ? 'Perempuan' : 'Laki-laki';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nisCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked != null) setState(() => _foto = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final body = {
        'nama_siswa': _namaCtrl.text.trim(),
        'NIS': _nisCtrl.text.trim(),
        'kelas': _kelas,
        'jurusan': _jurusan,
        'jenis_kelamin': _jenisKelamin == 'Laki-laki' ? 'L' : 'P',
        'alamat': _alamatCtrl.text.trim(),
        'no_telepon': _teleponCtrl.text.trim(),
      };
      if (isEdit) {
        await SiswaService().update(widget.existingData!['id_siswa'], body, fotoPath: _foto?.path);
      } else {
        await SiswaService().create(body, fotoPath: _foto?.path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Data berhasil diperbarui' : 'Data siswa berhasil disimpan'),
            backgroundColor: AppTheme.success,
          ),
        );
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Data Siswa' : 'Masukkan Data Siswa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(),
              const SizedBox(height: 20),
              _buildField('Nama Lengkap', _namaCtrl, Icons.person_outline, 'Masukkan nama lengkap siswa'),
              const SizedBox(height: 14),
              _buildField('NIS', _nisCtrl, Icons.badge_outlined, 'Masukkan NIS siswa',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildDropdown('Kelas', _kelas, _kelasList, Icons.class_outlined,
                  (v) => setState(() => _kelas = v!)),
              const SizedBox(height: 14),
              _buildDropdown('Jurusan', _jurusan, _jurusanList, Icons.school_outlined,
                  (v) => setState(() => _jurusan = v!)),
              const SizedBox(height: 14),
              _buildDropdown('Jenis Kelamin', _jenisKelamin, _jenisKelaminList,
                  Icons.wc_outlined, (v) => setState(() => _jenisKelamin = v!)),
              const SizedBox(height: 14),
              _buildField('Alamat', _alamatCtrl, Icons.location_on_outlined, 'Masukkan alamat siswa',
                  maxLines: 3),
              const SizedBox(height: 14),
              _buildField('No. Telepon', _teleponCtrl, Icons.phone_outlined, 'Masukkan nomor telepon',
                  keyboardType: TextInputType.phone, required: false),
              const SizedBox(height: 20),
              _buildFotoSection(),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _simpan,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(isEdit ? 'Perbarui Data Siswa' : 'Simpan Data Siswa'),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, color: AppTheme.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Data Siswa' : 'Masukkan Data Siswa',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lengkapi data siswa dengan benar untuk sistem absensi.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String hint,
      {TextInputType? keyboardType, int maxLines = 1, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: hint),
          validator: required ? (v) => v == null || v.isEmpty ? '$label tidak boleh kosong' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon,
      void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto Wajah Siswa', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 4),
        const Text(
          'Ambil foto wajah siswa untuk keperluan pengenalan wajah saat absensi',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickFoto,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: _foto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_foto!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade500),
                      const SizedBox(height: 8),
                      Text('Ambil Gambar',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Klik untuk ambil foto wajah siswa',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

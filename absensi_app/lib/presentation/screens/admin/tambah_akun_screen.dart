import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/siswa_model.dart';
import '../../../data/services/akun_service.dart';
import '../../../data/services/mata_pelajaran_service.dart';
import '../../../data/services/siswa_service.dart';

class TambahAkunScreen extends StatefulWidget {
  const TambahAkunScreen({super.key});

  @override
  State<TambahAkunScreen> createState() => _TambahAkunScreenState();
}

class _TambahAkunScreenState extends State<TambahAkunScreen> {
  final _formKey = GlobalKey<FormState>();
  final _akunService = AkunService();
  final _siswaService = SiswaService();

  bool _isGuru = true;
  bool _isLoading = false;
  bool _isLoadingSiswa = false;
  bool _isLoadingMapel = true;
  bool _obscurePass = true;

  // Guru fields
  final _namaCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  String? _mataPelajaran;

  // Shared fields
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Siswa dropdown
  List<SiswaModel> _siswaList = [];
  SiswaModel? _selectedSiswa;

  List<String> _mapelList = [];

  @override
  void initState() {
    super.initState();
    _loadSiswaTanpaAkun();
    _loadMapel();
  }

  Future<void> _loadMapel() async {
    try {
      final data = await MataPelajaranService().getAll();
      if (mounted) {
        setState(() {
          _mapelList = data.map((m) => m.namaMapel).toList();
          if (_mataPelajaran == null && _mapelList.isNotEmpty) _mataPelajaran = _mapelList.first;
          _isLoadingMapel = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMapel = false);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nipCtrl.dispose();
    _emailCtrl.dispose();
    _teleponCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSiswaTanpaAkun() async {
    setState(() => _isLoadingSiswa = true);
    try {
      final list = await _siswaService.getTanpaAkun();
      if (mounted) setState(() => _siswaList = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSiswa = false);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isGuru && _mataPelajaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih mata pelajaran terlebih dahulu'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> body;
      if (_isGuru) {
        body = {
          'role': 'guru',
          'nama': _namaCtrl.text.trim(),
          'nis_nip': _nipCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'no_telepon': _teleponCtrl.text.trim(),
          'mata_pelajaran': _mataPelajaran,
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        };
      } else {
        body = {
          'role': 'siswa',
          'nama': _selectedSiswa!.namaSiswa,
          'nis_nip': _selectedSiswa!.nis,
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        };
      }

      await _akunService.create(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dibuat'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Akun Pengguna')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambahkan akun guru atau siswa baru ke dalam sistem',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Toggle Guru / Siswa
              Row(
                children: [
                  Expanded(child: _buildToggle('Guru', Icons.school_outlined, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildToggle('Siswa', Icons.person_outlined, false)),
                ],
              ),
              const SizedBox(height: 24),

              if (_isGuru) ...[
                _buildSectionLabel('Informasi Guru'),
                const SizedBox(height: 12),
                _buildField('Nama Lengkap', _namaCtrl, Icons.person_outline, 'Masukkan nama lengkap'),
                const SizedBox(height: 12),
                _buildField('NIP', _nipCtrl, Icons.badge_outlined, 'Masukkan NIP',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildField('Email', _emailCtrl, Icons.email_outlined, 'Masukkan email',
                    keyboardType: TextInputType.emailAddress, required: false),
                const SizedBox(height: 12),
                _buildField('No. Telepon', _teleponCtrl, Icons.phone_outlined, 'Masukkan nomor telepon',
                    keyboardType: TextInputType.phone, required: false),
                const SizedBox(height: 12),
                _isLoadingMapel
                    ? const LinearProgressIndicator()
                    : _mapelList.isEmpty
                        ? const Text('Belum ada data mata pelajaran — tambahkan lewat Kelola Data Master',
                            style: TextStyle(fontSize: 12, color: AppTheme.error))
                        : DropdownButtonFormField<String>(
                            initialValue: _mataPelajaran,
                            decoration: const InputDecoration(
                              labelText: 'Mata Pelajaran',
                              prefixIcon: Icon(Icons.menu_book_outlined),
                            ),
                            items: _mapelList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => setState(() => _mataPelajaran = v),
                          ),
              ] else ...[
                _buildSectionLabel('Pilih Siswa'),
                const SizedBox(height: 12),
                _isLoadingSiswa
                    ? const Center(child: CircularProgressIndicator())
                    : _siswaList.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Semua siswa sudah memiliki akun, atau belum ada data siswa.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<SiswaModel>(
                            key: ValueKey(_isGuru),
                            initialValue: _selectedSiswa,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Siswa',
                              prefixIcon: Icon(Icons.person_search_outlined),
                              hintText: 'Cari dan pilih siswa',
                            ),
                            items: _siswaList
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text('${s.namaSiswa} — ${s.nis} (${s.kelas})',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedSiswa = v),
                            validator: (_) =>
                                _selectedSiswa == null ? 'Pilih siswa terlebih dahulu' : null,
                          ),
                if (_selectedSiswa != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nama: ${_selectedSiswa!.namaSiswa}',
                            style: const TextStyle(fontSize: 13)),
                        Text('NIS: ${_selectedSiswa!.nis}',
                            style: const TextStyle(fontSize: 13)),
                        Text('Kelas: ${_selectedSiswa!.kelas} — ${_selectedSiswa!.jurusan}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),
              _buildSectionLabel('Buat Akun Login'),
              const SizedBox(height: 12),
              _buildField('Username', _usernameCtrl, Icons.person_outline, 'Masukkan username'),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _simpan,
                            child: const Text('Simpan'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, IconData icon, bool isGuru) {
    final selected = _isGuru == isGuru;
    return GestureDetector(
      onTap: () => setState(() {
        _isGuru = isGuru;
        _selectedSiswa = null;
        _formKey.currentState?.reset();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppTheme.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                )),
            Text(
              isGuru ? 'Akun untuk tenaga pendidik' : 'Akun untuk peserta didik',
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white70 : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) =>
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String hint,
      {TextInputType? keyboardType, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label tidak boleh kosong' : null
          : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePass,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        hintText: 'Minimal 6 karakter',
        suffixIcon: IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Password tidak boleh kosong';
        if (v.trim().length < 6) return 'Password minimal 6 karakter';
        return null;
      },
    );
  }
}

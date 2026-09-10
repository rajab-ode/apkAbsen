import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/geofence_service.dart';

class PengaturanGeofencingScreen extends StatefulWidget {
  const PengaturanGeofencingScreen({super.key});

  @override
  State<PengaturanGeofencingScreen> createState() => _PengaturanGeofencingScreenState();
}

class _PengaturanGeofencingScreenState extends State<PengaturanGeofencingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = GeofenceService();

  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '100');

  bool _isLoading = true;
  bool _isSaving = false;
  bool _sudahDiatur = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final gf = await _service.getGeofence();
      if (mounted) {
        setState(() {
          if (gf != null) {
            _latCtrl.text = gf.latitude.toString();
            _lngCtrl.text = gf.longitude.toString();
            _radiusCtrl.text = gf.radiusMeter.toString();
            _sudahDiatur = true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _service.setGeofence(
        latitude: double.parse(_latCtrl.text.trim()),
        longitude: double.parse(_lngCtrl.text.trim()),
        radiusMeter: int.parse(_radiusCtrl.text.trim()),
      );
      if (mounted) {
        setState(() => _sudahDiatur = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pengaturan geofencing berhasil disimpan'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Geofencing')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Buka Google Maps → tekan lama titik lokasi sekolah → salin koordinat yang muncul, lalu tempel di kolom Latitude & Longitude di bawah.',
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_sudahDiatur) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Geofencing belum diatur — siswa masih bisa absen dari mana saja sampai lokasi ini diisi.',
                        style: TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildField('Latitude', _latCtrl, 'Mis. -3.9778120', signed: true),
                    const SizedBox(height: 14),
                    _buildField('Longitude', _lngCtrl, 'Mis. 122.5194330', signed: true),
                    const SizedBox(height: 14),
                    _buildField('Radius (meter)', _radiusCtrl, 'Mis. 100', signed: false),
                    const SizedBox(height: 28),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _simpan,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Simpan Pengaturan'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {required bool signed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: signed),
          decoration: InputDecoration(hintText: hint),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label tidak boleh kosong';
            if (double.tryParse(v.trim()) == null) return '$label harus berupa angka';
            return null;
          },
        ),
      ],
    );
  }
}

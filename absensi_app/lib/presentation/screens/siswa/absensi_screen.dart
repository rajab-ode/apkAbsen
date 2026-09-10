import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/absensi_service.dart';
import '../../../data/services/auth_provider.dart';
import '../../../data/services/face_recognition_service.dart';
import '../../widgets/face_frame_painter.dart';
import 'absensi_berhasil_screen.dart';
import 'absensi_gagal_screen.dart';
import 'jadwal_saya_screen.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  final _faceService = FaceRecognitionService();
  final _absensiService = AbsensiService();

  bool _isCameraReady = false;
  bool _isFaceServiceReady = false;
  bool _faceDetected = false;
  bool _isProcessing = false;
  bool _isTakingPicture = false;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initFaceService();
  }

  Future<void> _initFaceService() async {
    try {
      await _faceService.initialize();
      if (mounted) setState(() => _isFaceServiceReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraCtrl?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraCtrl?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Pilih kamera depan
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraCtrl = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraCtrl!.initialize();
    if (!mounted) return;

    setState(() => _isCameraReady = true);
    _startFaceDetectionTimer();
  }

  void _startFaceDetectionTimer() {
    // Deteksi wajah setiap 600ms untuk menghemat baterai
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!_isProcessing) _detectFaceFromStream();
    });
  }

  Future<void> _detectFaceFromStream() async {
    if (_isTakingPicture) return;
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    _isTakingPicture = true;
    try {
      final xFile = await _cameraCtrl!.takePicture();
      final faces = await _faceService.detectFaces(xFile.path);
      File(xFile.path).deleteSync();
      if (mounted) setState(() => _faceDetected = faces.isNotEmpty);
    } catch (_) {
    } finally {
      _isTakingPicture = false;
    }
  }

  /// Null berarti gagal (permission ditolak/GPS mati/dll) — pesan sudah
  /// ditampilkan lewat _onGagal di dalam fungsi ini, caller cukup return.
  Future<Position?> _pastikanLokasi() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _onGagal('Aktifkan GPS terlebih dahulu untuk bisa absen.');
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _onGagal('Izin lokasi diperlukan untuk absen.');
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      _onGagal('Gagal mendapatkan lokasi. Pastikan GPS aktif lalu coba lagi.');
      return null;
    }
  }

  Future<void> _absenSekarang() async {
    if (_isProcessing) return;
    if (!_isFaceServiceReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face recognition sedang dimuat, tunggu sebentar...'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    if (!_faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posisikan wajah Anda di dalam frame terlebih dahulu'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _detectionTimer?.cancel();

    final position = await _pastikanLokasi();
    if (position == null) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _startFaceDetectionTimer();
      }
      return;
    }

    while (_isTakingPicture) {
      await Future.delayed(const Duration(milliseconds: 30));
    }

    String? imagePath;
    _isTakingPicture = true;
    try {
      final xFile = await _cameraCtrl!.takePicture();
      imagePath = xFile.path;

      final faces = await _faceService.detectFaces(imagePath);
      if (faces.isEmpty) {
        _onGagal('Wajah tidak terdeteksi. Coba lagi.');
        return;
      }

      final embedding = await _faceService.getEmbedding(imagePath, faces.first);
      final result = await _absensiService.recognize(
        embedding,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AbsensiBerhasilScreen(absensi: result)),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _onGagal(msg);
    } finally {
      _isTakingPicture = false;
      if (imagePath != null) {
        try { File(imagePath).deleteSync(); } catch (_) {}
      }
      if (mounted) {
        setState(() => _isProcessing = false);
        _startFaceDetectionTimer();
      }
    }
  }

  void _onGagal(String pesan) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AbsensiGagalScreen(pesan: pesan)),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Absensi'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Jadwal Saya',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JadwalSayaScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Absensi',
            onPressed: () => Navigator.pushNamed(context, '/siswa/riwayat'),
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Ajukan Izin',
            onPressed: () => Navigator.pushNamed(context, '/siswa/izin'),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Riwayat Izin',
            onPressed: () => Navigator.pushNamed(context, '/siswa/riwayat-izin'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildCamera()),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        if (_isCameraReady && _cameraCtrl != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraCtrl!.value.previewSize!.height,
                height: _cameraCtrl!.value.previewSize!.width,
                child: CameraPreview(_cameraCtrl!),
              ),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        // Overlay gelap
        Container(color: Colors.black.withValues(alpha: 0.3)),

        // Face frame
        CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: FaceFramePainter(faceDetected: _faceDetected),
        ),

        // Label instruksi dan status
        Positioned(
          top: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Posisikan wajah anda\ndi dalam frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),

        // Indikator wajah terdeteksi
        Positioned(
          bottom: 24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _faceDetected
                  ? AppTheme.success.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _faceDetected ? Icons.check_circle : Icons.face_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _faceDetected ? 'Wajah Terdeteksi' : 'Mencari wajah...',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Loading overlay saat processing
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Memverifikasi wajah...',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _faceDetected ? AppTheme.primary : Colors.grey.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _isProcessing ? null : _absenSekarang,
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Absen Sekarang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_provider.dart';
import '../../../data/services/face_recognition_service.dart';
import '../../../data/services/siswa_service.dart';
import '../../widgets/face_frame_painter.dart';

class DaftarWajahScreen extends StatefulWidget {
  const DaftarWajahScreen({super.key});

  @override
  State<DaftarWajahScreen> createState() => _DaftarWajahScreenState();
}

class _DaftarWajahScreenState extends State<DaftarWajahScreen> {
  CameraController? _cameraCtrl;
  final _faceService = FaceRecognitionService();
  final _siswaService = SiswaService();
  Timer? _detectionTimer;

  bool _isCameraReady = false;
  bool _isFaceServiceReady = false;
  bool _faceDetected = false;
  bool _isProcessing = false;
  bool _isTakingPicture = false;
  String _statusMsg = 'Memuat model face recognition...';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initFaceService();
  }

  Future<void> _initFaceService() async {
    try {
      await _faceService.initialize();
      if (mounted) {
        setState(() {
          _isFaceServiceReady = true;
          _statusMsg = 'Posisikan wajah Anda di dalam frame';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMsg = 'Gagal load model: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
      }
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraCtrl?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraCtrl = CameraController(
      front,
      ResolutionPreset.medium, // medium cukup untuk live detection
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _cameraCtrl!.initialize();
    if (!mounted) return;
    setState(() => _isCameraReady = true);
    _startLiveDetection();
  }

  void _startLiveDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!_isProcessing) _detectOnce();
    });
  }

  Future<void> _detectOnce() async {
    if (_isTakingPicture) return;
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    _isTakingPicture = true;
    String? path;
    try {
      final xFile = await _cameraCtrl!.takePicture();
      path = xFile.path;
      final faces = await _faceService.detectFaces(path);
      if (mounted) setState(() => _faceDetected = faces.isNotEmpty);
    } catch (_) {
    } finally {
      _isTakingPicture = false;
      if (path != null) try { File(path).deleteSync(); } catch (_) {}
    }
  }

  Future<void> _daftarWajah() async {
    if (_isProcessing) return;
    if (!_isFaceServiceReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Face recognition sedang dimuat, tunggu sebentar...'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    if (!_faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wajah belum terdeteksi. Posisikan wajah dalam frame.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    final idSiswa = context.read<AuthProvider>().user?.extraId ?? 0;

    setState(() {
      _isProcessing = true;
      _statusMsg = 'Mengambil & memproses gambar...';
    });
    _detectionTimer?.cancel();
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
        if (mounted) setState(() => _statusMsg = 'Wajah tidak terdeteksi, coba lagi');
        return;
      }

      setState(() => _statusMsg = 'Mengekstrak data wajah...');
      final embedding = await _faceService.getEmbedding(imagePath, faces.first);

      setState(() => _statusMsg = 'Menyimpan ke server...');
      await _siswaService.registerFace(idSiswa, embedding);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Wajah berhasil didaftarkan! Silakan absen.'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.pushNamedAndRemoveUntil(context, '/siswa/absensi', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMsg = 'Posisikan wajah Anda di dalam frame');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
        _startLiveDetection(); // restart loop setelah gagal
      }
    } finally {
      _isTakingPicture = false;
      if (imagePath != null) try { File(imagePath).deleteSync(); } catch (_) {}
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Daftarkan Wajah'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Text(
                'Wajah Anda belum terdaftar. Daftarkan wajah terlebih dahulu untuk bisa absensi.',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: FaceFramePainter(faceDetected: _faceDetected),
                  ),
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusMsg,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
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
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text('Memproses wajah...',
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: _faceDetected ? AppTheme.primary : Colors.grey.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isProcessing ? null : _daftarWajah,
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                label: const Text(
                  'Daftarkan Wajah Saya',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/utils/math_utils.dart' as math_utils;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static const String _modelPath = 'assets/models/mobilefacenet.tflite';
  static const int _inputSize = 112;
  static const int _embeddingSize = 192;

  Interpreter? _interpreter;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: true, // aktifkan untuk basic liveness hints
    ),
  );

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _interpreter = await Interpreter.fromAsset(_modelPath);

    // Warmup inference — cegah cold-start latency di pengguna pertama
    final dummy = Float32List(1 * _inputSize * _inputSize * 3)
        .reshape([1, _inputSize, _inputSize, 3]);
    final dummyOut = [List.filled(_embeddingSize, 0.0)];
    _interpreter!.run(dummy, dummyOut);

    _isInitialized = true;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    await _faceDetector.close();
    _isInitialized = false;
  }

  Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return _faceDetector.processImage(inputImage);
  }

  /// Ekstrak embedding — async via compute() agar tidak blokir UI thread
  Future<List<double>> getEmbedding(String imagePath, Face face) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Face recognition service belum diinisialisasi');
    }

    // Baca file secara async (tidak blokir main thread)
    final bytes = await File(imagePath).readAsBytes();

    // Decode + preprocess di background isolate
    final bb = face.boundingBox;
    final cropArgs = _CropArgs(
      bytes: bytes,
      left: bb.left,
      top: bb.top,
      right: bb.right,
      bottom: bb.bottom,
      inputSize: _inputSize,
    );
    final inputTensor = await compute(_buildTensorIsolate, cropArgs);
    if (inputTensor == null) throw Exception('Gagal memproses gambar wajah');

    final output = [List.filled(_embeddingSize, 0.0)];
    _interpreter!.run(inputTensor, output);

    return _normalize(output[0]);
  }

  double cosineSimilarity(List<double> a, List<double> b) =>
      math_utils.cosineSimilarity(a, b);

  List<double> _normalize(List<double> v) {
    final norm = sqrt(v.fold(0.0, (s, x) => s + x * x));
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }
}

// Data class untuk dikirim ke isolate
class _CropArgs {
  final Uint8List bytes;
  final double left, top, right, bottom;
  final int inputSize;
  const _CropArgs({
    required this.bytes,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.inputSize,
  });
}

// Top-level function (wajib untuk compute())
Object? _buildTensorIsolate(_CropArgs args) {
  final rawImage = img.decodeImage(args.bytes);
  if (rawImage == null) return null;

  // Clamp bounding box dengan benar (hindari out-of-bounds)
  final x = args.left.toInt().clamp(0, rawImage.width - 1);
  final y = args.top.toInt().clamp(0, rawImage.height - 1);
  final right = args.right.toInt().clamp(0, rawImage.width);
  final bottom = args.bottom.toInt().clamp(0, rawImage.height);
  final w = (right - x).clamp(1, rawImage.width - x);
  final h = (bottom - y).clamp(1, rawImage.height - y);

  final cropped = img.copyCrop(rawImage, x: x, y: y, width: w, height: h);
  final resized = img.copyResize(cropped, width: args.inputSize, height: args.inputSize);

  // Gunakan Float32List (single buffer) bukan nested List — hemat GC
  final inputBytes = Float32List(args.inputSize * args.inputSize * 3);
  int idx = 0;
  for (int py = 0; py < args.inputSize; py++) {
    for (int px = 0; px < args.inputSize; px++) {
      final pixel = resized.getPixel(px, py);
      inputBytes[idx++] = (pixel.r / 127.5) - 1.0;
      inputBytes[idx++] = (pixel.g / 127.5) - 1.0;
      inputBytes[idx++] = (pixel.b / 127.5) - 1.0;
    }
  }
  return inputBytes.reshape([1, args.inputSize, args.inputSize, 3]);
}

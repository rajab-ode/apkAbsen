import 'package:flutter/material.dart';

class FaceFramePainter extends CustomPainter {
  final bool faceDetected;

  const FaceFramePainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final color = faceDetected ? const Color(0xFF10B981) : Colors.white;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const frameW = 200.0;
    const frameH = 220.0;

    final left = cx - frameW / 2;
    final top = cy - frameH / 2;
    final right = cx + frameW / 2;
    final bottom = cy + frameH / 2;

    // Sudut kiri atas
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), paint);

    // Sudut kanan atas
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLen), paint);

    // Sudut kiri bawah
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLen, bottom), paint);

    // Sudut kanan bawah
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen), paint);

    // Titik wajah di tengah saat tidak terdeteksi
    if (!faceDetected) {
      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy - 10), 20, dotPaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 20), width: 36, height: 20),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceFramePainter old) => old.faceDetected != faceDetected;
}

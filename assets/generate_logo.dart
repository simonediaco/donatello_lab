
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LogoGenerator {
  static Future<void> generateLogos() async {
    // Create directory if it doesn't exist
    final assetsDir = Directory('assets/images/logos');
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    // Generate 5 different logo variants
    await _generateLogo1(); // Minimalist geometric
    await _generateLogo2(); // Artistic brush stroke
    await _generateLogo3(); // Modern gradient circle
    await _generateLogo4(); // Renaissance inspired
    await _generateLogo5(); // Tech-elegant hybrid
  }

  // Logo 1: Minimalist Geometric
  static Future<void> _generateLogo1() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(300, 300);

    // Background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Main geometric shape - stylized "D"
    final path = Path();
    path.moveTo(60, 80);
    path.lineTo(60, 220);
    path.lineTo(120, 220);
    path.quadraticBezierTo(200, 220, 240, 150);
    path.quadraticBezierTo(200, 80, 120, 80);
    path.close();

    final gradient = ui.Gradient.linear(
      const Offset(60, 80),
      const Offset(240, 220),
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawPath(path, paint);

    // Accent dot
    final accentPaint = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(220, 100), 12, accentPaint);

    await _saveToPng(recorder, 'logo_1_minimalist.png');
  }

  // Logo 2: Artistic Brush Stroke
  static Future<void> _generateLogo2() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(300, 300);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Artistic brush stroke effect
    final path1 = Path();
    path1.moveTo(50, 150);
    path1.quadraticBezierTo(100, 80, 150, 120);
    path1.quadraticBezierTo(200, 160, 250, 100);

    final brushPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path1, brushPaint);

    // Second artistic stroke
    final path2 = Path();
    path2.moveTo(80, 200);
    path2.quadraticBezierTo(150, 180, 220, 210);

    final brushPaint2 = Paint()
      ..color = const Color(0xFFEC4899)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path2, brushPaint2);

    // Central elegance dot
    final centerPaint = Paint()
      ..color = const Color(0xFF06B6D4);
    canvas.drawCircle(const Offset(150, 150), 8, centerPaint);

    await _saveToPng(recorder, 'logo_2_artistic.png');
  }

  // Logo 3: Modern Gradient Circle
  static Future<void> _generateLogo3() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(300, 300);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Outer ring
    final outerGradient = ui.Gradient.radial(
      const Offset(150, 150),
      100,
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6), Colors.transparent],
      [0.7, 0.9, 1.0],
    );

    final outerPaint = Paint()
      ..shader = outerGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(150, 150), 100, outerPaint);

    // Inner core
    final innerGradient = ui.Gradient.radial(
      const Offset(150, 150),
      60,
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
    );

    final innerPaint = Paint()..shader = innerGradient;
    canvas.drawCircle(const Offset(150, 150), 60, innerPaint);

    // Central symbol
    final symbolPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final symbolPath = Path();
    symbolPath.moveTo(130, 130);
    symbolPath.lineTo(170, 150);
    symbolPath.lineTo(130, 170);
    canvas.drawPath(symbolPath, symbolPaint);

    await _saveToPng(recorder, 'logo_3_modern.png');
  }

  // Logo 4: Renaissance Inspired
  static Future<void> _generateLogo4() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(300, 300);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Renaissance frame
    final framePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final frameRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 40, 220, 220),
      const Radius.circular(20),
    );
    canvas.drawRRect(frameRect, framePaint);

    // Ornamental corners
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(150, 150);
      canvas.rotate((i * 90) * (3.14159 / 180));
      canvas.translate(-150, -150);

      final ornamentPaint = Paint()
        ..color = const Color(0xFFEC4899)
        ..style = PaintingStyle.fill;

      final ornamentPath = Path();
      ornamentPath.moveTo(50, 50);
      ornamentPath.lineTo(70, 50);
      ornamentPath.lineTo(60, 70);
      ornamentPath.close();

      canvas.drawPath(ornamentPath, ornamentPaint);
      canvas.restore();
    }

    // Central monogram "D"
    final letterPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.fill;

    final letterPath = Path();
    letterPath.moveTo(120, 100);
    letterPath.lineTo(120, 200);
    letterPath.lineTo(160, 200);
    letterPath.quadraticBezierTo(200, 180, 200, 150);
    letterPath.quadraticBezierTo(200, 120, 160, 100);
    letterPath.close();

    canvas.drawPath(letterPath, letterPaint);

    await _saveToPng(recorder, 'logo_4_renaissance.png');
  }

  // Logo 5: Tech-Elegant Hybrid
  static Future<void> _generateLogo5() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(300, 300);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Hexagonal base
    final hexPath = Path();
    final center = const Offset(150, 150);
    final radius = 80.0;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180);
      final x = center.dx + radius * (i == 0 ? 1 : (i % 2 == 0 ? 0.5 : -0.5));
      final y = center.dy + radius * (i < 2 ? -0.866 : (i < 4 ? 0 : 0.866));
      
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    final hexGradient = ui.Gradient.linear(
      const Offset(70, 70),
      const Offset(230, 230),
      [const Color(0xFF06B6D4), const Color(0xFF67E8F9)],
    );

    final hexPaint = Paint()..shader = hexGradient;
    canvas.drawPath(hexPath, hexPaint);

    // Inner tech pattern
    final techPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw circuit-like pattern
    canvas.drawLine(const Offset(130, 130), const Offset(170, 130), techPaint);
    canvas.drawLine(const Offset(170, 130), const Offset(170, 170), techPaint);
    canvas.drawLine(const Offset(170, 170), const Offset(130, 170), techPaint);
    
    // Accent nodes
    final nodePaint = Paint()..color = const Color(0xFFEC4899);
    canvas.drawCircle(const Offset(130, 130), 4, nodePaint);
    canvas.drawCircle(const Offset(170, 130), 4, nodePaint);
    canvas.drawCircle(const Offset(170, 170), 4, nodePaint);

    await _saveToPng(recorder, 'logo_5_tech_elegant.png');
  }

  static Future<void> _saveToPng(ui.PictureRecorder recorder, String filename) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final file = File('assets/images/logos/$filename');
    await file.writeAsBytes(pngBytes);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogoGenerator.generateLogos();
}

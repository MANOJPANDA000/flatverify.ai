import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/branding.dart';

void main() {
  test('generate launcher icons from the app painter', () async {
    Future<void> render(
      String path,
      int pixels, {
      bool foreground = false,
    }) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = pixels.toDouble();
      if (!foreground) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size, size),
            Radius.circular(size * .22),
          ),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF172B65), AppColors.primary],
            ).createShader(Rect.fromLTWH(0, 0, size, size)),
        );
      }
      final inset = size * (foreground ? .23 : .13);
      canvas.translate(inset, inset);
      const FlatverifyLogoPainter().paint(
        canvas,
        Size(size - inset * 2, size - inset * 2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(pixels, pixels);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
    await render(
      'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png',
      432,
      foreground: true,
    );
    await render('assets/branding/app_icon.png', 1024);
  });
}

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Builds the Home Screen icon master: B.T. Sun only (no wordmark), white bg.
///
/// Source: assets/images/bharat_traders_logo.png (same asset as splash/in-app).
/// Output: assets/images/app_icon_bt_sun.png (1024×1024 for flutter_launcher_icons).
Future<void> main() async {
  const sourcePath = 'assets/images/bharat_traders_logo.png';
  const outputPath = 'assets/images/app_icon_bt_sun.png';
  const canvasSize = 1024;
  const logoFill = 0.89; // 89% — within 85–90% safe area

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing source logo: $sourcePath');
    exit(1);
  }

  final source = decodeImage(sourceFile.readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode: $sourcePath');
    exit(1);
  }

  final sunOnly = _extractSunLogo(source);
  final icon = _composeAppIcon(sunOnly, canvasSize: canvasSize, logoFill: logoFill);

  File(outputPath).writeAsBytesSync(encodePng(icon));
  stdout.writeln('Wrote $outputPath (${canvasSize}x$canvasSize, sun logo ${(logoFill * 100).toStringAsFixed(1)}% fill)');
}

bool _isMaroonTextPixel(int r, int g, int b) {
  return r > 95 && r < 210 && g < 95 && b > 40 && b < 150 && r > g + 25;
}

bool _isInkPixel(int r, int g, int b) {
  return r < 235 || g < 235 || b < 235;
}

/// Crops to the circular B.T. sun emblem, excluding the BHARAT TRADERS wordmark.
Image _extractSunLogo(Image source) {
  var textTop = source.height;
  for (var y = source.height - 1; y >= 0; y--) {
    var maroonPixels = 0;
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      if (_isMaroonTextPixel(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt())) {
        maroonPixels++;
      }
    }
    if (maroonPixels > source.width * 0.04) {
      textTop = y;
    }
  }

  if (textTop >= source.height) {
    textTop = (source.height * 0.72).round();
  }

  var minX = source.width;
  var maxX = 0;
  var minY = source.height;
  var maxY = 0;

  final scanBottom = math.max(0, textTop - 4);
  for (var y = 0; y < scanBottom; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      if (!_isInkPixel(r, g, b)) continue;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
  }

  if (maxX <= minX || maxY <= minY) {
    final side = math.min(source.width, (source.height * 0.72).round());
    final x = (source.width - side) ~/ 2;
    return copyCrop(source, x: x, y: 0, width: side, height: side);
  }

  final contentW = maxX - minX + 1;
  final contentH = maxY - minY + 1;
  final side = math.max(contentW, contentH);
  final padX = ((side - contentW) / 2).round();
  final padY = ((side - contentH) / 2).round();

  var cropX = minX - padX;
  var cropY = minY - padY;
  cropX = cropX.clamp(0, source.width - 1);
  cropY = cropY.clamp(0, source.height - 1);
  final cropW = math.min(side, source.width - cropX);
  final cropH = math.min(side, source.height - cropY);

  return copyCrop(source, x: cropX, y: cropY, width: cropW, height: cropH);
}

Image _composeAppIcon(
  Image sunLogo, {
  required int canvasSize,
  required double logoFill,
}) {
  final canvas = Image(width: canvasSize, height: canvasSize);
  fill(canvas, color: ColorRgb8(255, 255, 255));

  final targetSide = (canvasSize * logoFill).round();
  final resized = copyResize(
    sunLogo,
    width: targetSide,
    height: targetSide,
    interpolation: Interpolation.cubic,
  );

  compositeImage(
    canvas,
    resized,
    dstX: (canvasSize - targetSide) ~/ 2,
    dstY: (canvasSize - targetSide) ~/ 2,
  );

  return canvas;
}

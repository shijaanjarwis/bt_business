import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'launcher_icon_gold.dart';

/// Heritage launcher icon — gold sun + curved BHARAT TRADERS wordmark.
/// Output is launcher-only; never used inside the app UI.
Future<void> main() async {
  const canvasSize = 1024;
  const sunFill = 0.89;
  const outputPath = 'assets/images/app_icon_launcher.png';

  final canvas = img.Image(width: canvasSize, height: canvasSize);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

  final goldSun = img.decodeImage(buildGoldSunPng(size: (canvasSize * sunFill).round()));
  if (goldSun == null) {
    stderr.writeln('Failed to build gold sun emblem');
    exit(1);
  }

  img.compositeImage(
    canvas,
    goldSun,
    dstX: (canvasSize - goldSun.width) ~/ 2,
    dstY: (canvasSize - goldSun.height) ~/ 2,
  );

  _drawArcWordmark(canvas);

  File(outputPath).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Wrote $outputPath (${canvasSize}x$canvasSize, sun ${(sunFill * 100).toStringAsFixed(0)}%)');
}

void _drawArcWordmark(img.Image canvas) {
  const text = 'BHARAT TRADERS';
  final maroon = img.ColorRgb8(122, 15, 23);
  final font = img.arial48;
  const letterSpacing = 4.0;
  const textRadius = 1024 * 0.335;
  const centerX = 1024 / 2;
  const centerY = 1024 / 2 + 1024 * 0.055;
  const startAngle = math.pi * 0.74;
  const endAngle = math.pi * 0.26;
  const glyphScale = 0.62;

  final glyphs = <img.Image>[];
  for (final char in text.split('')) {
    glyphs.add(_renderGlyph(char, font: font, color: maroon, scale: glyphScale));
  }

  var totalWidth = 0.0;
  for (final glyph in glyphs) {
    totalWidth += glyph.width + letterSpacing;
  }
  totalWidth -= letterSpacing;

  var traveled = 0.0;
  for (final glyph in glyphs) {
    final charWidth = glyph.width.toDouble();
    final mid = traveled + charWidth / 2;
    final t = mid / totalWidth;
    final angle = startAngle + (endAngle - startAngle) * t;

    final x = centerX + textRadius * math.cos(angle);
    final y = centerY + textRadius * math.sin(angle);
    final degrees = (angle - math.pi / 2) * 180 / math.pi;

    final rotated = img.copyRotate(glyph, angle: degrees);
    img.compositeImage(
      canvas,
      rotated,
      dstX: (x - rotated.width / 2).round(),
      dstY: (y - rotated.height / 2).round(),
    );

    traveled += charWidth + letterSpacing;
  }
}

img.Image _renderGlyph(
  String char, {
  required img.BitmapFont font,
  required img.Color color,
  double scale = 1.0,
}) {
  final scratch = img.Image(width: 120, height: 120, numChannels: 4);
  img.fill(scratch, color: img.ColorRgba8(0, 0, 0, 0));
  img.drawString(scratch, char, font: font, x: 10, y: 10, color: color);

  var trimmed = _trimTransparent(scratch);
  if (scale != 1.0) {
    trimmed = img.copyResize(
      trimmed,
      width: (trimmed.width * scale).round().clamp(1, 999),
      height: (trimmed.height * scale).round().clamp(1, 999),
      interpolation: img.Interpolation.cubic,
    );
  }
  return trimmed;
}

img.Image _trimTransparent(img.Image source) {
  var minX = source.width;
  var minY = source.height;
  var maxX = 0;
  var maxY = 0;

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).a.toInt() < 16) continue;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
  }

  if (maxX <= minX || maxY <= minY) return source;
  return img.copyCrop(
    source,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

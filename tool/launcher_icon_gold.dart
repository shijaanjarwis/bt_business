import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const _sourcePath = 'assets/images/bharat_traders_logo.png';

/// Premium metallic gold palette for the launcher icon sun only.
const _goldDark = (r: 156, g: 114, b: 18);
const _goldMid = (r: 201, g: 162, b: 48);
const _goldLight = (r: 232, g: 198, b: 92);
const _btInk = (r: 28, g: 18, b: 8);

/// Builds the cropped, gold-tinted sun emblem bytes (B.T. kept bold/dark).
Uint8List buildGoldSunPng({int size = 920}) {
  final sourceFile = File(_sourcePath);
  if (!sourceFile.existsSync()) {
    throw StateError('Missing source logo: $_sourcePath');
  }

  final source = img.decodeImage(sourceFile.readAsBytesSync());
  if (source == null) {
    throw StateError('Could not decode: $_sourcePath');
  }

  final sunCrop = _extractSunLogo(source);
  final goldSun = _applyGoldHeritageSun(sunCrop);
  final scaled = img.copyResize(
    goldSun,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );

  return Uint8List.fromList(img.encodePng(scaled));
}

bool _isMaroonTextPixel(int r, int g, int b) {
  return r > 95 && r < 210 && g < 95 && b > 40 && b < 150 && r > g + 25;
}

bool _isInkPixel(int r, int g, int b) {
  return r < 235 || g < 235 || b < 235;
}

img.Image _extractSunLogo(img.Image source) {
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
    return img.copyCrop(source, x: x, y: 0, width: side, height: side);
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

  return img.copyCrop(source, x: cropX, y: cropY, width: cropW, height: cropH);
}

img.Image _applyGoldHeritageSun(img.Image sunCrop) {
  final out = img.Image(width: sunCrop.width, height: sunCrop.height);
  final cx = sunCrop.width / 2;
  final cy = sunCrop.height / 2;
  final outerR = sunCrop.width / 2;

  for (var y = 0; y < sunCrop.height; y++) {
    for (var x = 0; x < sunCrop.width; x++) {
      final pixel = sunCrop.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      final dist = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / outerR;

      if (lum > 248) {
        out.setPixelRgb(x, y, 255, 255, 255);
      } else if (dist < 0.30 && lum > 185) {
        out.setPixelRgb(x, y, 255, 255, 255);
      } else if (dist < 0.30 && lum < 145) {
        out.setPixelRgb(x, y, _btInk.r, _btInk.g, _btInk.b);
      } else if (lum < 245) {
        final t = ((255 - lum) / 255).clamp(0.0, 1.0);
        final gold = _lerpGold(t);
        out.setPixelRgb(x, y, gold.$1, gold.$2, gold.$3);
      } else {
        out.setPixelRgb(x, y, 255, 255, 255);
      }
    }
  }

  return out;
}

(int, int, int) _lerpGold(double t) {
  if (t < 0.45) {
    final u = t / 0.45;
    return (
      (_goldDark.r + ((_goldMid.r - _goldDark.r) * u)).round(),
      (_goldDark.g + ((_goldMid.g - _goldDark.g) * u)).round(),
      (_goldDark.b + ((_goldMid.b - _goldDark.b) * u)).round(),
    );
  }
  final u = (t - 0.45) / 0.55;
  return (
    (_goldMid.r + ((_goldLight.r - _goldMid.r) * u)).round(),
    (_goldMid.g + ((_goldLight.g - _goldMid.g) * u)).round(),
    (_goldMid.b + ((_goldLight.b - _goldMid.b) * u)).round(),
  );
}

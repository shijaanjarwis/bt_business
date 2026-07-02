import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';

/// Regenerates ios/Runner/Assets.xcassets/AppIcon.appiconset from the
/// official BT Business logo used on the splash screen.
Future<void> main() async {
  const logoPath = 'assets/images/app_icon_bt_sun.png';
  const outDirPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

  final logoFile = File(logoPath);
  if (!logoFile.existsSync()) {
    stderr.writeln('Missing logo: $logoPath');
    exit(1);
  }

  final logo = decodeImage(logoFile.readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Could not decode logo: $logoPath');
    exit(1);
  }

  final outDir = Directory(outDirPath);
  outDir.createSync(recursive: true);

  Image renderSquare(int size) {
    final canvas = Image(width: size, height: size);
    fill(canvas, color: ColorRgb8(255, 255, 255));

    const paddingRatio = 0.1;
    final maxSide = (size * (1 - paddingRatio * 2)).round();
    final scale = maxSide / (logo.width > logo.height ? logo.width : logo.height);
    final targetW = (logo.width * scale).round();
    final targetH = (logo.height * scale).round();
    final resized = copyResize(
      logo,
      width: targetW,
      height: targetH,
      interpolation: Interpolation.cubic,
    );

    compositeImage(
      canvas,
      resized,
      dstX: (size - targetW) ~/ 2,
      dstY: (size - targetH) ~/ 2,
    );
    return canvas;
  }

  const entries = <({String filename, int pixels, String size, String idiom, String scale})>[
    (filename: 'Icon-App-20x20@2x.png', pixels: 40, size: '20x20', idiom: 'iphone', scale: '2x'),
    (filename: 'Icon-App-20x20@3x.png', pixels: 60, size: '20x20', idiom: 'iphone', scale: '3x'),
    (filename: 'Icon-App-29x29@2x.png', pixels: 58, size: '29x29', idiom: 'iphone', scale: '2x'),
    (filename: 'Icon-App-29x29@3x.png', pixels: 87, size: '29x29', idiom: 'iphone', scale: '3x'),
    (filename: 'Icon-App-40x40@2x.png', pixels: 80, size: '40x40', idiom: 'iphone', scale: '2x'),
    (filename: 'Icon-App-40x40@3x.png', pixels: 120, size: '40x40', idiom: 'iphone', scale: '3x'),
    (filename: 'Icon-App-60x60@2x.png', pixels: 120, size: '60x60', idiom: 'iphone', scale: '2x'),
    (filename: 'Icon-App-60x60@3x.png', pixels: 180, size: '60x60', idiom: 'iphone', scale: '3x'),
    (filename: 'Icon-App-20x20@1x.png', pixels: 20, size: '20x20', idiom: 'ipad', scale: '1x'),
    (filename: 'Icon-App-20x20@2x.png', pixels: 40, size: '20x20', idiom: 'ipad', scale: '2x'),
    (filename: 'Icon-App-29x29@1x.png', pixels: 29, size: '29x29', idiom: 'ipad', scale: '1x'),
    (filename: 'Icon-App-29x29@2x.png', pixels: 58, size: '29x29', idiom: 'ipad', scale: '2x'),
    (filename: 'Icon-App-40x40@1x.png', pixels: 40, size: '40x40', idiom: 'ipad', scale: '1x'),
    (filename: 'Icon-App-40x40@2x.png', pixels: 80, size: '40x40', idiom: 'ipad', scale: '2x'),
    (filename: 'Icon-App-76x76@1x.png', pixels: 76, size: '76x76', idiom: 'ipad', scale: '1x'),
    (filename: 'Icon-App-76x76@2x.png', pixels: 152, size: '76x76', idiom: 'ipad', scale: '2x'),
    (filename: 'Icon-App-83.5x83.5@2x.png', pixels: 167, size: '83.5x83.5', idiom: 'ipad', scale: '2x'),
    (filename: 'Icon-App-1024x1024@1x.png', pixels: 1024, size: '1024x1024', idiom: 'ios-marketing', scale: '1x'),
  ];

  final keep = <String>{'Contents.json'};
  for (final entry in entries) {
    keep.add(entry.filename);
    final rendered = renderSquare(entry.pixels);
    File('${outDir.path}/${entry.filename}').writeAsBytesSync(
      encodePng(rendered),
    );
    stdout.writeln('Wrote ${entry.filename} (${entry.pixels}px)');
  }

  for (final entity in outDir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!keep.contains(name)) {
      entity.deleteSync();
      stdout.writeln('Removed legacy icon $name');
    }
  }

  final contents = {
    'images': [
      for (final entry in entries)
        {
          'size': entry.size,
          'idiom': entry.idiom,
          'filename': entry.filename,
          'scale': entry.scale,
        },
    ],
    'info': {'version': 1, 'author': 'xcode'},
  };

  File('${outDir.path}/Contents.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(contents),
  );

  stdout.writeln('AppIcon.appiconset regenerated from $logoPath');
}

import 'dart:io';

import 'package:image/image.dart' as image;

/// Converts the temporary #00FF00 background used for generated character
/// sprite sheets into alpha while retaining anti-aliased feather edges.
///
/// Usage: dart run tool/remove_sprite_chroma.dart <input.png> <output.png>
void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/remove_sprite_chroma.dart <input.png> <output.png>',
    );
    exitCode = 64;
    return;
  }

  final input = File(arguments[0]);
  if (!input.existsSync()) {
    stderr.writeln('Input sprite sheet does not exist: ${input.path}');
    exitCode = 66;
    return;
  }

  final source = image.decodeImage(input.readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode character sprite sheet: ${input.path}');
    exitCode = 65;
    return;
  }
  // Generated PNGs are RGB-only. Force RGBA before setting alpha; otherwise
  // image's encoder legitimately drops the transparency channel.
  final decoded = source.convert(numChannels: 4);

  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();
      final alpha = pixel.a.toInt();
      final greenDominance = green - (red > blue ? red : blue);

      if (green < 130 || greenDominance < 52) {
        continue;
      }

      // Image generation applies light compression/colour variation to the
      // nominal #00FF00 background (for example 16/240/17). Treat that whole
      // strong-green range as the solid key, otherwise it remains a visibly
      // dark green rectangle after alpha compositing.
      if (red <= 48 && blue <= 48 && green >= 180 && greenDominance >= 130) {
        decoded.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      // A solid chroma pixel is removed entirely. Pixels close to a feather
      // edge are softly attenuated so antialiasing stays clean at gameplay
      // size instead of leaving a green halo.
      final keyStrength = ((greenDominance - 52) / 130).clamp(0.0, 1.0);
      final brightnessStrength = ((green - 130) / 90).clamp(0.0, 1.0);
      final removal = keyStrength * brightnessStrength;
      final outputAlpha = (alpha * (1 - removal)).round().clamp(0, 255);

      // Remove green spill from partially transparent edge pixels.
      final spill = (green * removal * 0.65).round();
      decoded.setPixelRgba(
        x,
        y,
        red,
        (green - spill).clamp(0, 255),
        blue,
        outputAlpha,
      );
    }
  }

  final output = File(arguments[1]);
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(image.encodePng(decoded, level: 6));
  stdout.writeln(
    'Wrote transparent ${decoded.width}x${decoded.height} sprite sheet: '
    '${output.path}',
  );
}

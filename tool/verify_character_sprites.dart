import 'dart:io';

import 'package:image/image.dart' as image;

const _characterIds = <String>{
  'nova',
  'pulse',
  'volt',
  'glitch',
  'spectre',
  'quasar',
  'ember',
  'cyber',
  'phantom',
  'aurora',
  'nebula',
  'titan',
  'zenith',
  'singularity',
  'cosmos',
  'eclipse',
  'nova_prime',
  'infinity',
  'omega_plus',
  'myth',
  'legend',
  'apex',
  'genesis',
  'universe',
};

/// Verifies that every persisted character ID has a real, transparent and
/// correctly aligned 3x2 runtime sheet before Flutter is pointed at it.
void main() {
  var hasFailure = false;

  for (final id in _characterIds) {
    final file = File('assets/characters/$id.png');
    if (!file.existsSync()) {
      stderr.writeln('Missing asset: ${file.path}');
      hasFailure = true;
      continue;
    }

    final decoded = image.decodePng(file.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('Unreadable PNG: ${file.path}');
      hasFailure = true;
      continue;
    }
    if (decoded.width != 1536 || decoded.height != 1024) {
      stderr.writeln(
        'Unexpected dimensions for $id: ${decoded.width}x${decoded.height}; '
        'expected 1536x1024.',
      );
      hasFailure = true;
    }

    var transparentSamples = 0;
    var opaqueChromaSamples = 0;
    for (var y = 0; y < decoded.height; y += 8) {
      for (var x = 0; x < decoded.width; x += 8) {
        final pixel = decoded.getPixel(x, y);
        if (pixel.a < 8) transparentSamples++;
        if (pixel.a > 245 && pixel.r < 18 && pixel.g > 238 && pixel.b < 18) {
          opaqueChromaSamples++;
        }
      }
    }
    if (transparentSamples == 0) {
      stderr.writeln('No transparent pixels found in $id.');
      hasFailure = true;
    }
    if (opaqueChromaSamples > 0) {
      stderr.writeln('Green chroma pixels remain in $id: $opaqueChromaSamples');
      hasFailure = true;
    }

    stdout.writeln(
      '$id: ${decoded.width}x${decoded.height}, alpha samples '
      '$transparentSamples',
    );
  }

  if (hasFailure) exitCode = 1;
}

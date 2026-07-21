import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/services/audio_service.dart';

void main() {
  testWidgets('every selectable music track is a bundled CC0 OGG asset',
      (tester) async {
    for (final track in MusicTrack.values) {
      expect(track.id, isNotEmpty);
      expect(track.title, isNotEmpty);
      expect(track.artist, isNotEmpty);
      expect(track.sourceCategory, isNotEmpty);
      expect(track.sourceUrl, startsWith('https://opengameart.org/'));
      expect(track.originalFilename, endsWith('.ogg'));
      expect(track.asset, endsWith('.ogg'));
      expect(track.isPlaceholder, isFalse);

      final data = await rootBundle.load('assets/${track.asset}');
      final header = Uint8List.sublistView(data, 0, 4);
      expect(String.fromCharCodes(header), 'OggS');
    }
  });
}

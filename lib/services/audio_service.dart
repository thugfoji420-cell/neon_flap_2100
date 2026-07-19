import 'package:audioplayers/audioplayers.dart';

/// Enum of every sound effect in the game (maps to an asset file).
enum Sfx {
  buttonClick('audio/button_click.wav'),
  tap('audio/tap.wav'),
  coin('audio/coin.wav'),
  characterUnlock('audio/character_unlock.wav'),
  purchaseSuccess('audio/purchase_success.wav'),
  rewardReceived('audio/reward_received.wav'),
  gameOver('audio/game_over.wav'),
  countdown('audio/countdown.wav'),
  victory('audio/victory.wav');

  const Sfx(this.asset);
  final String asset;
}

/// Background music tracks.
enum MusicTrack {
  menu('audio/bg_menu.mp3'),
  game('audio/bg_game.mp3');

  const MusicTrack(this.asset);
  final String asset;
}

/// Wraps audioplayers. A small round-robin POOL of low-latency players is
/// used for SFX so that:
///   * multiple sounds can overlap (e.g. a coin pickup while a tap plays), and
///   * one shot can never stop() another in-flight sound (the original bug
///     where a shared player was stop()+play()'d on every call, racing with
///     rapid coin/tap bursts and silencing later sounds).
/// Background music uses its own dedicated looping player. Volumes are driven
/// live by [SettingsService].
class AudioService {
  AudioService();

  /// Number of low-latency SFX players in the pool. Three is plenty for the
  /// fastest burst (tap → coin → tap) while staying memory-cheap.
  static const int _sfxPoolSize = 3;

  final List<AudioPlayer> _sfxPlayers = [];
  int _sfxIndex = 0;
  late final AudioPlayer _musicPlayer;

  double _sfxVolume = 0.8;
  double _musicVolume = 0.6;
  MusicTrack? _currentTrack;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    // Do NOT let sound effects grab Android audio focus — the default
    // (AndroidAudioFocus.gain) makes every SFX pause the music player, so a
    // button click or a volume-slider tap would mute the background track.
    // Focus `none` lets SFX and music play together without ducking.
    final context = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await AudioPlayer.global.setAudioContext(context);

    for (var i = 0; i < _sfxPoolSize; i++) {
      final p = AudioPlayer();
      await p.setAudioContext(context);
      await p.setPlayerMode(PlayerMode.lowLatency);
      _sfxPlayers.add(p);
    }
    _musicPlayer = AudioPlayer();
    await _musicPlayer.setAudioContext(context);
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    for (final p in _sfxPlayers) {
      try {
        await p.setVolume(_sfxVolume);
      } catch (_) {
        // Ignore.
      }
    }
  }

  Future<void> setMusicVolume(double v) async {
    _musicVolume = v.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
  }

  /// Play a one-shot sound effect. Safe to call from game loops.
  ///
  /// A free player is pulled from the pool (round-robin) and replayed from the
  /// start. Because each shot uses its own player, overlapping sounds never
  /// cancel each other, and a rapid burst of coins/taps can't leave the SFX
  /// engine silently stopped. The play is launched fire-and-forget so the
  /// calling frame is never blocked.
  /// Play a one-shot sound effect. Safe to call from game loops.
  ///
  /// A free player is pulled from the pool (round-robin) and replayed from the
  /// start. Because each shot uses its own player, overlapping sounds never
  /// cancel each other. The player's volume is set once in [setSfxVolume] and
  /// does not need to be passed on every [play] call.
  Future<void> playSfx(Sfx sfx) async {
    if (_sfxPlayers.isEmpty) return;
    final player = _sfxPlayers[_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPlayers.length;
    try {
      await player.stop();
      await player.play(AssetSource(sfx.asset));
    } catch (_) {
      // Audio failures must never crash gameplay.
    }
  }

  /// Start looping background music. If the requested track is already
  /// playing this is a no-op.
  Future<void> playMusic(MusicTrack track, {bool loop = true}) async {
    if (_currentTrack == track && _musicPlayer.state == PlayerState.playing) {
      return;
    }
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _musicPlayer.play(AssetSource(track.asset), volume: _musicVolume);
      _currentTrack = track;
    } catch (_) {
      // Ignore audio errors.
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
      _currentTrack = null;
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> resumeMusic() async {
    try {
      if (_currentTrack != null) await _musicPlayer.resume();
    } catch (_) {
      // Ignore.
    }
  }

  void dispose() {
    for (final p in _sfxPlayers) {
      try {
        p.dispose();
      } catch (_) {
        // Ignore.
      }
    }
    _sfxPlayers.clear();
    _musicPlayer.dispose();
  }
}

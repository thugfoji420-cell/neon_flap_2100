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

/// Wraps audioplayers: one low-latency player for SFX and one looping player
/// for background music. Volumes are driven live by [SettingsService].
class AudioService {
  AudioService();

  late final AudioPlayer _sfxPlayer;
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

    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();
    await _sfxPlayer.setAudioContext(context);
    await _musicPlayer.setAudioContext(context);
    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _musicPlayer.setVolume(_musicVolume);
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  Future<void> setMusicVolume(double v) async {
    _musicVolume = v.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
  }

  /// Play a one-shot sound effect. Safe to call from game loops.
  Future<void> playSfx(Sfx sfx) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(sfx.asset), volume: _sfxVolume);
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
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}

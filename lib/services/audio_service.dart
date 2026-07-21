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
enum MusicCategory { menu, gameplay }

enum MusicTrack {
  menu(
    id: 'menu_neon_dawn',
    title: 'Space Adventure',
    artist: 'MintoDog',
    sourceCategory: 'Synthwave • loopable',
    sourceUrl: 'https://opengameart.org/content/space-adventure',
    originalFilename: 'space_adventure_bpm140.ogg',
    asset: 'audio/music/menu/space_adventure.ogg',
    category: MusicCategory.menu,
  ),
  menuSkylineDrive(
    id: 'menu_skyline_drive',
    title: 'Revelation',
    artist: 'Centurion_of_war',
    sourceCategory: 'Synth • loopable',
    sourceUrl: 'https://opengameart.org/content/revelation-0',
    originalFilename: 'revelationsynth.ogg',
    asset: 'audio/music/menu/revelation.ogg',
    category: MusicCategory.menu,
  ),
  menuCrystalArcade(
    id: 'menu_crystal_arcade',
    title: 'Lost in the Snow Wave',
    artist: 'hatmix',
    sourceCategory: 'Synthwave • loopable',
    sourceUrl: 'https://opengameart.org/content/lost-in-the-snow-wave',
    originalFilename: 'lost_in_the_snow_wave.ogg',
    asset: 'audio/music/menu/lost_in_the_snow_wave.ogg',
    category: MusicCategory.menu,
  ),
  menuOrbitLounge(
    id: 'menu_orbit_lounge',
    title: 'Synthwave House Loop',
    artist: 'Fupi',
    sourceCategory: 'Synthwave / house • loop',
    sourceUrl: 'https://opengameart.org/content/synthwave-house-loop',
    originalFilename: 'synthwavehouse.ogg',
    asset: 'audio/music/menu/synthwave_house_loop.ogg',
    category: MusicCategory.menu,
  ),
  game(
    id: 'game_grid_runner',
    title: 'Future Power Loop',
    artist: 'request',
    sourceCategory: 'Synth adventure • loop',
    sourceUrl:
        'https://opengameart.org/content/future-power-bgm-loopable-synthy-adventure',
    originalFilename: 'futurepower_loop.ogg',
    asset: 'audio/music/gameplay/future_power_loop.ogg',
    category: MusicCategory.gameplay,
  ),
  gameQuantumChase(
    id: 'game_quantum_chase',
    title: 'Boss Stage Synth Track',
    artist: 'killerfishred',
    sourceCategory: 'Synth • loopable',
    sourceUrl: 'https://opengameart.org/content/boss-stage-synth-track',
    originalFilename: 'fight.ogg',
    asset: 'audio/music/gameplay/boss_stage_synth.ogg',
    category: MusicCategory.gameplay,
  ),
  gameVoidRush(
    id: 'game_void_rush',
    title: 'Tense Future Loop',
    artist: 'gmason',
    sourceCategory: 'Futuristic • loop • percussion',
    sourceUrl: 'https://opengameart.org/content/tense-future-loop',
    originalFilename: 'tensefutureloop.ogg',
    asset: 'audio/music/gameplay/tense_future_loop.ogg',
    category: MusicCategory.gameplay,
  ),
  gameStarlightSprint(
    id: 'game_starlight_sprint',
    title: 'Futuristic-Resources',
    artist: 'section31',
    sourceCategory: 'Futuristic electronic / techno',
    sourceUrl: 'https://opengameart.org/content/futuristic-resources',
    originalFilename: 'S31-Futuristic-Resources.ogg',
    asset: 'audio/music/gameplay/futuristic_resources.ogg',
    category: MusicCategory.gameplay,
  );

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceCategory,
    required this.sourceUrl,
    required this.originalFilename,
    required this.asset,
    required this.category,
  });

  /// Stable setting key. These legacy values are intentionally retained so an
  /// existing player's selection survives the licensed-track upgrade.
  final String id;
  final String title;
  final String artist;
  final String sourceCategory;
  final String sourceUrl;
  final String originalFilename;
  final String asset;
  final MusicCategory category;

  static const String licenseName = 'CC0 1.0 Universal';
  static const String licenseUrl =
      'https://creativecommons.org/publicdomain/zero/1.0/';
  static const String downloadedOn = '2026-07-21';
  static const String conversionDetails =
      'Original OGG retained; no conversion or edit was made.';

  /// Kept for settings UI compatibility. Every selectable entry is now a real
  /// bundled asset; no generated or missing-track fallback is advertised.
  bool get isPlaceholder => false;
  String get playbackAsset => asset;

  static List<MusicTrack> byCategory(MusicCategory category) => values
      .where((track) => track.category == category)
      .toList(growable: false);

  static MusicTrack fromId(String? id, MusicCategory category) {
    return byCategory(category).firstWhere(
      (track) => track.id == id,
      orElse: () =>
          category == MusicCategory.menu ? MusicTrack.menu : MusicTrack.game,
    );
  }
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
  bool _resumeMusicAfterLifecyclePause = false;
  bool _isPreviewing = false;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  MusicTrack? get currentTrack => _currentTrack;
  bool get isPreviewing => _isPreviewing;

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
    if (_currentTrack == track &&
        _musicPlayer.state == PlayerState.playing &&
        !_isPreviewing) {
      return;
    }
    try {
      _resumeMusicAfterLifecyclePause = false;
      await _musicPlayer.stop();
      await _musicPlayer
          .setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _musicPlayer.play(
        AssetSource(track.playbackAsset),
        volume: _musicVolume,
      );
      _currentTrack = track;
      _isPreviewing = false;
    } catch (_) {
      // Ignore audio errors.
    }
  }

  Future<void> stopMusic() async {
    try {
      _resumeMusicAfterLifecyclePause = false;
      await _musicPlayer.stop();
      _currentTrack = null;
      _isPreviewing = false;
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

  /// Plays one non-looping selection preview on the dedicated music player.
  /// The current track is stopped first, so a settings preview can never layer
  /// over gameplay or menu music. [restoreAfterPreview] restores the prior
  /// context when the selector is dismissed without a choice.
  Future<void> previewMusic(MusicTrack track) async {
    try {
      _resumeMusicAfterLifecyclePause = false;
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.release);
      await _musicPlayer.play(
        AssetSource(track.playbackAsset),
        volume: _musicVolume,
      );
      _currentTrack = track;
      _isPreviewing = true;
    } catch (_) {
      // A missing/unsupported asset must not make settings unusable.
    }
  }

  /// Stops a temporary preview and resumes exactly the normal screen track
  /// that was playing before it. A null [normalTrack] means music was stopped
  /// before the preview, so it remains stopped afterwards.
  Future<void> restoreAfterPreview(MusicTrack? normalTrack) async {
    if (!_isPreviewing) return;
    try {
      await _musicPlayer.stop();
    } catch (_) {
      // Continue to restore the normal context if stopping fails.
    }
    _currentTrack = null;
    _isPreviewing = false;
    if (normalTrack != null) await playMusic(normalTrack);
  }

  /// Silences game audio while Android backgrounds the app or turns the screen
  /// off. Music resumes only when it was genuinely playing before the
  /// interruption; manually stopped music stays stopped after wake-up.
  Future<void> pauseForAppLifecycle() async {
    final shouldResume =
        _currentTrack != null && _musicPlayer.state == PlayerState.playing;

    if (shouldResume) {
      // Android commonly sends both inactive and paused. Keep this flag once
      // set so the second callback cannot erase the pending resume.
      _resumeMusicAfterLifecyclePause = true;
      await pauseMusic();
    }

    // Short SFX must never continue behind the lock screen. They are one-shot
    // feedback, so stopping rather than resuming them is the natural result.
    for (final player in _sfxPlayers) {
      try {
        await player.stop();
      } catch (_) {
        // Ignore audio failures.
      }
    }
  }

  /// Restores only the background track that [pauseForAppLifecycle] paused.
  Future<void> resumeAfterAppLifecycle() async {
    if (!_resumeMusicAfterLifecyclePause || _currentTrack == null) return;
    _resumeMusicAfterLifecyclePause = false;
    await resumeMusic();
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

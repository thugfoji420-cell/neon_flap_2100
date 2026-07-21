import 'package:flutter/foundation.dart';

/// Persisted player settings. Volumes are [0..1]; vibration is on/off.
@immutable
class GameSettings {
  const GameSettings({
    this.musicVolume = 0.6,
    this.sfxVolume = 0.8,
    this.vibration = true,
    this.selectedMenuTrackId = 'menu_neon_dawn',
    this.selectedGameplayTrackId = 'game_grid_runner',
  });

  final double musicVolume;
  final double sfxVolume;
  final bool vibration;
  final String selectedMenuTrackId;
  final String selectedGameplayTrackId;

  GameSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? vibration,
    String? selectedMenuTrackId,
    String? selectedGameplayTrackId,
  }) =>
      GameSettings(
        musicVolume: musicVolume ?? this.musicVolume,
        sfxVolume: sfxVolume ?? this.sfxVolume,
        vibration: vibration ?? this.vibration,
        selectedMenuTrackId: selectedMenuTrackId ?? this.selectedMenuTrackId,
        selectedGameplayTrackId:
            selectedGameplayTrackId ?? this.selectedGameplayTrackId,
      );

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        musicVolume: (json['musicVolume'] as num? ?? 0.6).toDouble(),
        sfxVolume: (json['sfxVolume'] as num? ?? 0.8).toDouble(),
        vibration: (json['vibration'] as bool? ?? true),
        selectedMenuTrackId:
            json['selectedMenuTrackId'] as String? ?? 'menu_neon_dawn',
        selectedGameplayTrackId:
            json['selectedGameplayTrackId'] as String? ?? 'game_grid_runner',
      );

  Map<String, dynamic> toJson() => {
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'vibration': vibration,
        'selectedMenuTrackId': selectedMenuTrackId,
        'selectedGameplayTrackId': selectedGameplayTrackId,
      };
}

import 'package:flutter/foundation.dart';

/// Persisted player settings. Volumes are [0..1]; vibration is on/off.
@immutable
class GameSettings {
  const GameSettings({
    this.musicVolume = 0.6,
    this.sfxVolume = 0.8,
    this.vibration = true,
  });

  final double musicVolume;
  final double sfxVolume;
  final bool vibration;

  GameSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? vibration,
  }) =>
      GameSettings(
        musicVolume: musicVolume ?? this.musicVolume,
        sfxVolume: sfxVolume ?? this.sfxVolume,
        vibration: vibration ?? this.vibration,
      );

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        musicVolume: (json['musicVolume'] as num? ?? 0.6).toDouble(),
        sfxVolume: (json['sfxVolume'] as num? ?? 0.8).toDouble(),
        vibration: (json['vibration'] as bool? ?? true),
      );

  Map<String, dynamic> toJson() => {
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'vibration': vibration,
      };
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'siren_stub.dart' if (dart.library.js_interop) 'siren_web.dart';

class CitizenAlertService {
  static DateTime? _lastSirenTime;
  static AudioPlayer? _audioPlayer;

  static AudioPlayer get _player {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  /// Trigger emergency attention siren and vibration
  static Future<void> triggerProximityAlert({bool isCritical = false}) async {
    // 1. Mobile / system haptic feedback
    try {
      HapticFeedback.heavyImpact();
      if (isCritical) {
        HapticFeedback.vibrate();
      }
    } catch (_) {}

    // 2. System sound fallback
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    // 3. Play loud siren audio (rate-limited so sounds don't overlap)
    final now = DateTime.now();
    if (_lastSirenTime == null || now.difference(_lastSirenTime!).inMilliseconds >= 3000) {
      _lastSirenTime = now;
      await _playSirenAudio();
    }
  }

  /// Direct manual trigger to test the siren audio immediately
  static Future<void> testSiren() async {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    await _playSirenAudio();
  }

  static Future<void> _playSirenAudio() async {
    // 1. Play native AudioPlayer asset (works across Android, iOS, Desktop)
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/emergency_siren.wav'));
      debugPrint("🚨 Native AudioPlayer playing emergency_siren.wav");
    } catch (e) {
      debugPrint("Notice: AudioPlayer play notice: $e");
    }

    // 2. On Web, also trigger Web Audio synthesized sweep for instant low-latency audio
    if (kIsWeb) {
      try {
        triggerWebSiren();
      } catch (_) {}
    }
  }

  static Future<void> stopSiren() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
  }
}

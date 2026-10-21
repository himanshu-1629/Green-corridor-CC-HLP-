import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'siren_stub.dart' if (dart.library.js_interop) 'siren_web.dart';

class CitizenAlertService {
  static DateTime? _lastSirenTime;

  /// Trigger emergency attention siren and vibration
  static void triggerProximityAlert({bool isCritical = false}) {
    // 1. Mobile / system haptic feedback
    try {
      HapticFeedback.heavyImpact();
      if (isCritical) {
        HapticFeedback.vibrate();
      }
    } catch (_) {}

    // 2. System sound
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    // 3. Dual-tone synthesizer siren (rate-limited so sounds don't overlap)
    final now = DateTime.now();
    if (_lastSirenTime == null || now.difference(_lastSirenTime!).inMilliseconds >= 3200) {
      _lastSirenTime = now;
      if (kIsWeb) {
        triggerWebSiren();
      }
    }
  }

  /// Direct manual trigger to test the siren audio immediately
  static void testSiren() {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    if (kIsWeb) {
      triggerWebSiren();
    }
  }
}

import 'dart:js_interop';

@JS('playEmergencySiren')
external void _playEmergencySiren();

void triggerWebSiren() {
  try {
    _playEmergencySiren();
  } catch (_) {}
}

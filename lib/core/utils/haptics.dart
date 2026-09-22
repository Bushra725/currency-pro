import 'package:flutter/services.dart';

/// Keypad feedback, gated by the two switches in App Settings.
///
/// Named `Haptics` rather than `Feedback` so it never collides with the
/// Material class of the same name.
class Haptics {
  const Haptics._();

  static Future<void> tap({required bool vibrate, required bool sound}) async {
    if (vibrate) {
      await HapticFeedback.selectionClick();
    }
    if (sound) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> heavy({required bool vibrate}) async {
    if (vibrate) await HapticFeedback.mediumImpact();
  }
}

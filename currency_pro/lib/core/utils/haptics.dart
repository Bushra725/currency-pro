import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Keypad feedback, gated by the two switches in App Settings.
///
/// Named `Haptics` rather than `Feedback` so it never collides with the
/// Material class of the same name.
///
/// Vibration goes through a native MethodChannel that drives the phone
/// motor directly. The `vibration` plugin used USAGE_ALARM + a 20 ms pulse,
/// which Samsung (and Do Not Disturb) often swallows.
class Haptics {
  const Haptics._();

  static const MethodChannel _motor =
      MethodChannel('com.theoccess.currencypro/haptics');

  static final AudioPlayer _click = AudioPlayer();
  static bool _playerReady = false;

  static Future<void> warmup() async {
    if (_playerReady) return;
    try {
      await _click.setReleaseMode(ReleaseMode.stop);
      await _click.setPlayerMode(PlayerMode.lowLatency);
      await _click.setVolume(0.6);
      await _click.setSource(AssetSource('sounds/key_click.wav'));
      _playerReady = true;
    } catch (_) {
      _playerReady = false;
    }
  }

  static Future<void> tap({required bool vibrate, required bool sound}) async {
    if (vibrate) {
      // Do not await — a stuck platform call must not block the click sound.
      buzz();
    }
    if (sound) {
      await playClick();
    }
  }

  static Future<void> buzz() async {
    try {
      await _motor.invokeMethod<void>('tick');
      return;
    } catch (_) {
      // Fall through if the native channel is missing (tests, web).
    }
    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> playClick() async {
    try {
      await warmup();
      await _click.stop();
      await _click.play(AssetSource('sounds/key_click.wav'), volume: 0.6);
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> heavy({required bool vibrate}) async {
    if (!vibrate) return;
    await buzz();
  }
}

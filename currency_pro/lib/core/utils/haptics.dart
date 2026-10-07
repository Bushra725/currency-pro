import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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

  /// Audio settings that let the click play *over* whatever the user is
  /// listening to.
  ///
  /// By default audioplayers requests `AndroidAudioFocus.gain`, which tells
  /// Android this app wants the audio stream — so Spotify pauses for every
  /// keypress. Declaring the click as a short interface sound and asking for
  /// no focus at all leaves other players untouched. On iOS the `ambient`
  /// category already mixes with other audio; `mixWithOthers` is not a legal
  /// option for that category and would stop the click from being set up.
  static final AudioContext _clickContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
    ),
  );

  /// The session the keypad click actually uses. Tests assert this so a
  /// future change cannot quietly request audio focus again.
  @visibleForTesting
  static AudioContext get clickContext => _clickContext;

  static Future<void> warmup() async {
    if (_playerReady) return;
    try {
      // Global first: it covers the session-level category on iOS.
      await AudioPlayer.global.setAudioContext(_clickContext);
      await _click.setAudioContext(_clickContext);
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
      await _click.play(
        AssetSource('sounds/key_click.wav'),
        volume: 0.6,
        ctx: _clickContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> heavy({required bool vibrate}) async {
    if (!vibrate) return;
    await buzz();
  }
}

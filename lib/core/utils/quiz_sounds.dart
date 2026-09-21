import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/app_sounds.dart';

/// Short, non-blocking quiz sound cues. Failures never affect gameplay.
abstract final class QuizSounds {
  static AudioPlayer? _feedback;
  static AudioPlayer? _overlay;
  static AudioPlayer? _timer;
  static var _ready = false;
  static var _configuring = false;
  static var _generation = 0;
  static final Map<String, Uint8List> _bytes = {};

  static Future<void> warmUp() => _ensureReady();

  static Future<void> _ensureReady() async {
    if (_ready) return;
    if (_configuring) {
      while (!_ready && _configuring) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      return;
    }
    _configuring = true;
    try {
      await _loadBytes();
      _feedback = AudioPlayer();
      _overlay = AudioPlayer();
      _timer = AudioPlayer();
      await Future.wait([
        _feedback!.setReleaseMode(ReleaseMode.stop),
        _overlay!.setReleaseMode(ReleaseMode.stop),
        _timer!.setReleaseMode(ReleaseMode.stop),
        _feedback!.setVolume(1),
        _overlay!.setVolume(1),
        _timer!.setVolume(1),
      ]);
      await _configureContext();
      _ready = true;
    } catch (error, stack) {
      debugPrint('QuizSounds init failed: $error\n$stack');
      _ready = _feedback != null;
    } finally {
      _configuring = false;
    }
  }

  static Future<void> _loadBytes() async {
    if (_bytes.isNotEmpty) return;
    await Future.wait([
      for (final asset in AppSounds.all) _loadOne(asset),
    ]);
  }

  static Future<void> _loadOne(String asset) async {
    final data = await rootBundle.load(asset);
    _bytes[asset] = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
  }

  static Future<void> _configureContext() async {
    try {
      final context = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: false,
      ).build();
      await AudioPlayer.global.setAudioContext(context);
      await Future.wait([
        _feedback!.setAudioContext(context),
        _overlay!.setAudioContext(context),
        _timer!.setAudioContext(context),
      ]);
    } catch (error) {
      debugPrint('QuizSounds audio context skipped: $error');
    }
  }

  static Future<void> _playOn(
    AudioPlayer? Function() playerOf,
    String asset,
  ) async {
    try {
      await _ensureReady();
      final player = playerOf();
      final bytes = _bytes[asset];
      if (player == null || bytes == null || bytes.isEmpty) {
        debugPrint('QuizSounds missing player/bytes for $asset');
        return;
      }
      await player.play(
        BytesSource(bytes, mimeType: AppSounds.mimeType(asset)),
        volume: 1,
        mode: PlayerMode.mediaPlayer,
      );
    } catch (error) {
      debugPrint('QuizSounds play failed ($asset): $error');
    }
  }

  static Future<void> _beginFeedback() async {
    _generation++;
    try {
      await _overlay?.stop();
    } catch (_) {}
  }

  static Future<void> correct({bool streakMilestone = false}) async {
    await _beginFeedback();
    final generation = _generation;
    await _playOn(() => _feedback, AppSounds.correct);
    if (!streakMilestone) return;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (generation != _generation) return;
    await _playOn(() => _overlay, AppSounds.streak5);
  }

  static Future<void> incorrect() async {
    await _beginFeedback();
    await _playOn(() => _feedback, AppSounds.incorrect);
  }

  static Future<void> fail() async {
    await _beginFeedback();
    await _playOn(() => _feedback, AppSounds.fail);
  }

  static Future<void> lastTenSeconds() =>
      _playOn(() => _timer, AppSounds.lastTenSeconds);

  static Future<void> stopTimerCue() async {
    try {
      await _timer?.stop();
    } catch (_) {}
  }

  static Future<void> stopAll() async {
    _generation++;
    try {
      await Future.wait([
        _feedback?.stop() ?? Future<void>.value(),
        _overlay?.stop() ?? Future<void>.value(),
        _timer?.stop() ?? Future<void>.value(),
      ]);
    } catch (_) {}
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isDisposed = false;

  // Start alarm
  Future<void> playAlarm() async {
    if (_isPlaying || _isDisposed) return;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      await _audioPlayer.play(
        AssetSource('sounds/alarm.wav'),
      );

      _isPlaying = true;
    } catch (e) {
      _isPlaying = false;
      debugPrint('Alarm Error: $e');
    }
  }

  // Stop alarm
  Future<void> stopAlarm() async {
    if (_isDisposed || !_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Stop Alarm Error: $e');
    }
  }

  // Check alarm status
  bool get isPlaying => _isPlaying;

  // Dispose audio player
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    _isPlaying = false;

    await _audioPlayer.dispose();
  }
}
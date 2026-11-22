import 'package:flutter/services.dart';

enum GameSound { taskSuccess, stickerReward }

const _channel = MethodChannel('labutica/task_audio');

Future<void> playGameSound(GameSound sound) async {
  try {
    await _channel.invokeMethod<void>(switch (sound) {
      GameSound.taskSuccess => 'playSuccess',
      GameSound.stickerReward => 'playStickerReward',
    });
  } on MissingPluginException {
    // Audio playback is provided by the Android host.
  } on PlatformException {
    // Audio feedback must not interrupt game progress.
  }
}

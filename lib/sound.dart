import 'package:audioplayers/audioplayers.dart';

enum Sound { none, bowl, bell, ring, whistle, bird, cheer, yeah }

final player = AudioPlayer();

Future<void> playSound(Sound sound) async {
  if (sound == Sound.none) return;

  final soundPath = 'sounds/${sound.toString().split('.').last}.mp3';
  await player.play(AssetSource(soundPath));
}

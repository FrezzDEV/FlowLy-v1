import 'package:flutter/material.dart';

import '../features/player/infrastructure/audio_player_service.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioServiceManager.instance.initialize();
  runApp(FlowLyApp(musicRepository: createMusicRepository()));
}

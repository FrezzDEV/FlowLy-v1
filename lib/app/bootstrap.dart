import 'package:flutter/material.dart';

import '../features/player/infrastructure/audio_player_service.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The UI must not depend on the media service initializing successfully.
  // audio_service can fail on platforms whose native runner is not configured yet.
  // We still want the app shell/search UI to render so the failure is isolated.
  runApp(FlowLyApp(musicRepository: createMusicRepository()));

  try {
    await AudioServiceManager.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('FlowLy audio service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

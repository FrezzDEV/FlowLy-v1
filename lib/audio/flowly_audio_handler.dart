import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class FlowLyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  FlowLyAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> loadTrack({
    required String streamUrl,
    required String title,
    required String artist,
    String? artworkUrl,
    Duration? duration,
    bool autoplay = false,
  }) async {
    final item = MediaItem(
      id: streamUrl,
      album: 'FlowLy',
      title: title,
      artist: artist,
      artUri: artworkUrl == null ? null : Uri.tryParse(artworkUrl),
      duration: duration,
    );

    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(streamUrl), tag: item),
    );

    if (autoplay) {
      await _player.play();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    const processingStates = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    };

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingStates[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep the media session alive when the app is dismissed from recents.
  }
}

class FlowLyAudioService {
  FlowLyAudioService._();

  static final FlowLyAudioService instance = FlowLyAudioService._();

  AudioHandler? _handler;

  AudioHandler get handler {
    final value = _handler;
    if (value == null) {
      throw StateError('FlowLyAudioService has not been initialized');
    }
    return value;
  }

  Future<void> initialize() async {
    if (_handler != null) return;

    _handler = await AudioService.init(
      builder: FlowLyAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.flowly.audio',
        androidNotificationChannelName: 'FlowLy playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
      ),
    );
  }
}

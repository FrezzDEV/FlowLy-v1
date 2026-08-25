import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class FlowLyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  FlowLyAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.positionStream.listen((position) {
      final item = mediaItem.valueOrNull;
      if (item != null) {
        mediaItem.add(item.copyWith(duration: _player.duration, extras: {
          ...?item.extras,
          'position': position.inMilliseconds,
        }));
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();

  static const String demoUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  Future<void> loadDemoTrack() async {
    const item = MediaItem(
      id: demoUrl,
      album: 'FlowLy',
      title: 'Test Track',
      artist: 'FlowLy Artist',
      duration: Duration(minutes: 3, seconds: 42),
    );

    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(demoUrl), tag: item),
      initialPosition: const Duration(minutes: 1, seconds: 8),
    );
    await _player.pause();
    _broadcastState(_player.playbackEvent);
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
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
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

  @override
  Future<void> close() async {
    await _player.dispose();
    await super.close();
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
        notificationColor: null,
        preloadArtwork: true,
      ),
    );

    await (_handler! as FlowLyAudioHandler).loadDemoTrack();
  }
}

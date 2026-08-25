import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/audio_player_service.dart';
import 'global_audio_player.dart';

class PlayerHost extends StatefulWidget {
  const PlayerHost({
    super.key,
    required this.mainBarHeight,
    this.onOpenStateChanged,
    this.onProgressChanged,
  });

  final double mainBarHeight;
  final ValueChanged<bool>? onOpenStateChanged;
  final ValueChanged<double>? onProgressChanged;

  @override
  State<PlayerHost> createState() => _PlayerHostState();
}

class _PlayerHostState extends State<PlayerHost>
    with SingleTickerProviderStateMixin {
  static const _miniFactor = 0.075;
  static const _expandedFactor = 1.0;
  static const _miniLiftFactor = 0.008;
  static const _radiusFactor = 0.022;

  late final AnimationController _progress;
  late final AudioHandler _audioHandler;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaSubscription;

  Duration _position = Duration.zero;
  Duration _trackDuration = const Duration(minutes: 3, seconds: 42);
  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isDownloaded = false;
  String _title = 'No track';
  String _artist = 'FlowLy';
  String? _artworkUrl;

  @override
  void initState() {
    super.initState();
    _audioHandler = AudioServiceManager.instance.handler;
    _progress = AnimationController(vsync: this, value: 0)
      ..addListener(_notifyProgress);

    _playbackSubscription = _audioHandler.playbackStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _position = state.position;
      });
    });
    _mediaSubscription = _audioHandler.mediaItem.listen((item) {
      if (!mounted || item == null) return;
      setState(() {
        _title = item.title;
        _artist = item.artist ?? 'FlowLy';
        _trackDuration = item.duration ?? _trackDuration;
        _artworkUrl = item.artUri?.toString();
      });
    });
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _mediaSubscription?.cancel();
    _progress.removeListener(_notifyProgress);
    _progress.dispose();
    super.dispose();
  }

  void _notifyProgress() => widget.onProgressChanged?.call(_progress.value);

  Future<void> open() async {
    widget.onOpenStateChanged?.call(true);
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> close() async {
    await _progress.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    widget.onOpenStateChanged?.call(false);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final height = MediaQuery.sizeOf(context).height;
    final travel = height * (_expandedFactor - _miniFactor);
    if (travel <= 0) return;
    _progress.value = (_progress.value -
            (details.primaryDelta ?? 0) / travel)
        .clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity.abs() > 600
        ? (velocity < 0 ? 1.0 : 0.0)
        : (_progress.value > 0.5 ? 1.0 : 0.0);
    target == 1 ? await open() : await close();
  }

  void _seek(double value) => _audioHandler.seek(Duration(
        milliseconds: (_trackDuration.inMilliseconds * value).round(),
      ));

  void _togglePlayPause() => _isPlaying
      ? _audioHandler.pause()
      : _audioHandler.play();

  void _toggleLike() => setState(() => _isLiked = !_isLiked);

  void _downloadTrack() {
    if (_isDownloaded) return;
    setState(() => _isDownloaded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Трек добавлен в загрузки')),
    );
  }

  String _format(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final bodyHeight = constraints.maxHeight;
          final width = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              final t = _progress.value;
              final playerHeight = bodyHeight * _lerp(_miniFactor, _expandedFactor, t);
              final bottomGap = widget.mainBarHeight * (1 - t);
              final miniLift = bodyHeight * _miniLiftFactor * (1 - t);
              final radius = width * _radiusFactor * (1 - t);
              final artSize = _lerp(width * 0.12, width * 0.56, t);
              final artTop = _lerp(playerHeight * 0.16, bodyHeight * 0.095, t);
              final artLeft = _lerp(width * 0.025, (width - artSize) / 2, t);
              final miniOpacity = 1 - _remap(t, 0, 0.32);
              final expandedOpacity = _remap(t, 0.45, 1);

              return Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, -(bottomGap + miniLift)),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Container(
                      width: width,
                      height: playerHeight,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(radius),
                          topRight: Radius.circular(radius),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 18,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _ArtworkBackground(
                            imageUrl: _artworkUrl,
                            opacity: _lerp(0.30, 0.62, t),
                            blurSigma: _lerp(18, 34, t),
                          ),
                          Container(color: Colors.black.withOpacity(0.42)),
                          Positioned(
                            top: artTop,
                            left: artLeft,
                            width: artSize,
                            height: artSize,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(width * 0.024),
                              child: Image.network(
                                _artworkUrl ??
                                    'https://picsum.photos/seed/flowly-test-track/1000/1000',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _FallbackArtwork(),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: t > 0.35,
                              child: Opacity(
                                opacity: miniOpacity,
                                child: GestureDetector(
                                  onTap: open,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.17,
                                      right: width * 0.03,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(_artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        IconButton(onPressed: _togglePlayPause, color: Colors.white, icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: artTop + artSize + bodyHeight * 0.035,
                            left: width * 0.06,
                            right: width * 0.06,
                            child: IgnorePointer(
                              ignoring: t < 0.5,
                              child: Opacity(
                                opacity: expandedOpacity,
                                child: Column(
                                  children: [
                                    GlobalAudioPlayer(
                                      title: _title,
                                      artist: _artist,
                                      isPlaying: _isPlaying,
                                      isLiked: _isLiked,
                                      isDownloaded: _isDownloaded,
                                      onDownload: _downloadTrack,
                                      onPrevious: _audioHandler.skipToPrevious,
                                      onPlayPause: _togglePlayPause,
                                      onNext: _audioHandler.skipToNext,
                                      onLike: _toggleLike,
                                    ),
                                    SizedBox(height: width * 0.035),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.transparent,
                                        trackHeight: width * 0.01,
                                      ),
                                      child: Slider(
                                        value: _trackDuration.inMilliseconds == 0
                                            ? 0
                                            : (_position.inMilliseconds / _trackDuration.inMilliseconds).clamp(0.0, 1.0),
                                        onChanged: _seek,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: width * 0.012),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_format(_position), style: TextStyle(color: Colors.white70, fontSize: width * 0.032)),
                                          Text(_format(_trackDuration), style: TextStyle(color: Colors.white70, fontSize: width * 0.032)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _remap(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
}

class _ArtworkBackground extends StatelessWidget {
  const _ArtworkBackground({required this.imageUrl, required this.opacity, required this.blurSigma});

  final String? imageUrl;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Image.network(
            imageUrl ?? 'https://picsum.photos/seed/flowly-test-track-background/1000/1000',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _FallbackArtwork(),
          ),
        ),
      );
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF292929),
        alignment: Alignment.center,
        child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 32),
      );
}

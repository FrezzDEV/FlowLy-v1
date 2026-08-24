import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'global_audio_player.dart';

class DraggableView extends StatefulWidget {
  const DraggableView({super.key, this.onOpenStateChanged, this.onProgressChanged, required this.mainBarHeight});
  final ValueChanged<bool>? onOpenStateChanged;
  final ValueChanged<double>? onProgressChanged;
  final double mainBarHeight;
  @override
  State<DraggableView> createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView> with SingleTickerProviderStateMixin {
  static const double _miniFactor = 0.075;
  static const double _expandedFactor = 1.0;
  static const double _miniLiftFactor = 0.008;
  static const double _radiusFactor = 0.022;
  static const Duration _trackDuration = Duration(minutes: 3, seconds: 42);

  late final AnimationController _progress;
  late final String _artworkUrl;
  Duration _position = const Duration(minutes: 1, seconds: 8);
  bool _isPlaying = true;
  bool _isLiked = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, value: 0)..addListener(_notifyProgress);
    final seed = DateTime.now().microsecondsSinceEpoch;
    _artworkUrl = 'https://picsum.photos/seed/flowly-$seed/1000/1000';
    widget.onProgressChanged?.call(0);
  }

  @override
  void dispose() {
    _progress.removeListener(_notifyProgress);
    _progress.dispose();
    super.dispose();
  }

  void _notifyProgress() => widget.onProgressChanged?.call(_progress.value);

  Future<void> open() async {
    if (!mounted) return;
    widget.onOpenStateChanged?.call(true);
    await _progress.animateTo(1, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> close() async {
    if (!mounted) return;
    await _progress.animateTo(0, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    widget.onOpenStateChanged?.call(false);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final height = MediaQuery.sizeOf(context).height;
    final travel = height * (_expandedFactor - _miniFactor);
    if (travel <= 0) return;
    _progress.value = (_progress.value - (details.primaryDelta ?? 0) / travel).clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity.abs() > 600 ? (velocity < 0 ? 1.0 : 0.0) : (_progress.value > 0.5 ? 1.0 : 0.0);
    if (target == 1) {
      await open();
    } else {
      await close();
    }
  }

  void _seek(double value) => setState(() {
        _position = Duration(milliseconds: (_trackDuration.inMilliseconds * value).round());
      });

  void _togglePlayPause() => setState(() => _isPlaying = !_isPlaying);
  void _previousTrack() => setState(() { _position = Duration.zero; _isPlaying = true; });
  void _nextTrack() => setState(() { _position = Duration.zero; _isPlaying = true; });
  void _toggleLike() => setState(() => _isLiked = !_isLiked);

  void _downloadTrack() {
    if (_isDownloaded) return;
    setState(() => _isDownloaded = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Трек добавлен в загрузки')));
  }

  String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight = constraints.maxHeight;
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final t = _progress.value;
            final playerHeight = bodyHeight * lerpDouble(_miniFactor, _expandedFactor, t);
            final bottomGap = widget.mainBarHeight * (1 - t);
            final miniLift = bodyHeight * _miniLiftFactor * (1 - t);
            final radius = width * _radiusFactor * (1 - t);
            final artSize = lerpDouble(width * 0.12, width * 0.56, t);
            final artTop = lerpDouble(playerHeight * 0.16, bodyHeight * 0.095, t);
            final artLeft = lerpDouble(width * 0.025, (width - artSize) / 2, t);
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
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius)),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, -4))],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _BlurredArtworkBackground(imageUrl: _artworkUrl, blurSigma: lerpDouble(18, 34, t), opacity: lerpDouble(0.30, 0.62, t)),
                        Container(color: Colors.black.withOpacity(0.42)),
                        Positioned(
                          top: artTop,
                          left: artLeft,
                          width: artSize,
                          height: artSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(width * 0.024),
                            child: Image.network(_artworkUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _FallbackArtwork()),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: t > 0.35,
                            child: Opacity(
                              opacity: miniOpacity,
                              child: _MiniContent(
                                onTap: open,
                                onPrevious: _previousTrack,
                                onPlayPause: _togglePlayPause,
                                onNext: _nextTrack,
                                isPlaying: _isPlaying,
                                width: width,
                                artSize: width * 0.12,
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
                                    title: 'Test Track',
                                    artist: 'FlowLy Artist',
                                    isPlaying: _isPlaying,
                                    isLiked: _isLiked,
                                    isDownloaded: _isDownloaded,
                                    onDownload: _downloadTrack,
                                    onPrevious: _previousTrack,
                                    onPlayPause: _togglePlayPause,
                                    onNext: _nextTrack,
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
                                      value: _trackDuration.inMilliseconds == 0 ? 0 : (_position.inMilliseconds / _trackDuration.inMilliseconds).clamp(0.0, 1.0),
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
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
  double _remap(double value, double start, double end) => ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
}

class _BlurredArtworkBackground extends StatelessWidget {
  const _BlurredArtworkBackground({required this.imageUrl, required this.blurSigma, required this.opacity});
  final String imageUrl;
  final double blurSigma;
  final double opacity;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _FallbackArtwork()),
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

class _MiniContent extends StatelessWidget {
  const _MiniContent({required this.onTap, required this.onPrevious, required this.onPlayPause, required this.onNext, required this.isPlaying, required this.width, required this.artSize});
  final VoidCallback onTap;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final bool isPlaying;
  final double width;
  final double artSize;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(left: artSize + width * 0.05, right: width * 0.03),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Track', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('FlowLy Artist', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(onPressed: onPrevious, tooltip: 'Предыдущий трек', color: Colors.white, icon: const Icon(Icons.skip_previous_rounded)),
              IconButton(onPressed: onPlayPause, tooltip: isPlaying ? 'Пауза' : 'Воспроизвести', color: Colors.white, icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
              IconButton(onPressed: onNext, tooltip: 'Следующий трек', color: Colors.white, icon: const Icon(Icons.skip_next_rounded)),
            ],
          ),
        ),
      );
}

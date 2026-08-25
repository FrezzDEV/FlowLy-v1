import 'package:flutter/material.dart';

class GlobalAudioPlayer extends StatelessWidget {
  const GlobalAudioPlayer({
    super.key,
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.isLiked,
    this.isDownloaded = false,
    this.onDownload,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
    this.onLike,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.onSeek,
  });

  final String title;
  final String artist;
  final bool isPlaying;
  final bool isLiked;
  final bool isDownloaded;
  final VoidCallback? onDownload;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onLike;
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onSeek;

  String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.058,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: width * 0.036,
          ),
        ),
        SizedBox(height: width * 0.055),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PlayerButton(
              icon: isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
              onPressed: isDownloaded ? null : onDownload,
              tooltip: 'Скачать',
            ),
            _PlayerButton(
              icon: Icons.skip_previous_rounded,
              onPressed: onPrevious,
              tooltip: 'Назад',
            ),
            _PlayPauseButton(isPlaying: isPlaying, onPressed: onPlayPause),
            _PlayerButton(
              icon: Icons.skip_next_rounded,
              onPressed: onNext,
              tooltip: 'Вперёд',
            ),
            _PlayerButton(
              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              onPressed: onLike,
              tooltip: 'Лайк',
            ),
          ],
        ),
        SizedBox(height: width * 0.035),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white38,
            thumbColor: Colors.white,
            overlayColor: Colors.transparent,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: progress,
            onChanged: onSeek,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.012),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(position), style: TextStyle(color: Colors.white70, fontSize: width * 0.032)),
              Text(_format(duration), style: TextStyle(color: Colors.white70, fontSize: width * 0.032)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerButton extends StatelessWidget {
  const _PlayerButton({required this.icon, required this.onPressed, required this.tooltip});
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.12;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size * 0.62,
      color: Colors.white,
      disabledColor: Colors.white38,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      icon: Icon(icon),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.onPressed});
  final bool isPlaying;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.15;
    return IconButton(
      onPressed: onPressed,
      tooltip: isPlaying ? 'Пауза' : 'Воспроизвести',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      iconSize: size * 0.65,
      color: Colors.white,
      icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

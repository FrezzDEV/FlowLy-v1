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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.sizeOf(context).width * 0.06,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: MediaQuery.sizeOf(context).width * 0.038,
          ),
        ),
        SizedBox(height: MediaQuery.sizeOf(context).width * 0.08),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PlayerButton(
              icon: isDownloaded
                  ? Icons.download_done_rounded
                  : Icons.download_rounded,
              onPressed: isDownloaded ? null : onDownload,
              tooltip: 'Скачать',
            ),
            _PlayerButton(
              icon: Icons.skip_previous_rounded,
              onPressed: onPrevious,
              tooltip: 'Назад',
            ),
            _PlayPauseButton(
              isPlaying: isPlaying,
              onPressed: onPlayPause,
            ),
            _PlayerButton(
              icon: Icons.skip_next_rounded,
              onPressed: onNext,
              tooltip: 'Вперёд',
            ),
            _PlayerButton(
              icon: isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              onPressed: onLike,
              tooltip: 'Лайк',
            ),
          ],
        ),
      ],
    );
  }
}

class _PlayerButton extends StatelessWidget {
  const _PlayerButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.13;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size * 0.5,
      color: Colors.white,
      disabledColor: Colors.white38,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      icon: Icon(icon),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.18;
    return IconButton(
      onPressed: onPressed,
      tooltip: isPlaying ? 'Пауза' : 'Воспроизвести',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      iconSize: size * 0.52,
      color: Colors.white,
      icon: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      ),
    );
  }
}

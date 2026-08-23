import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Port of FlowLy's draggable player surface.
/// The original implementation lives in FrezzDEV/FlowLy at
/// lib/utils/draggable_view.dart; this version is adapted for the v1 test UI.
class DraggableView extends StatefulWidget {
  const DraggableView({super.key});

  @override
  State<DraggableView> createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView>
    with SingleTickerProviderStateMixin {
  static const double _miniHeight = 64;
  static const double _miniMargin = 4;
  static const double _miniRadius = 14;
  static const double _navBarHeight = 64;

  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> open() async {
    if (!mounted) return;
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> close() async {
    if (!mounted) return;
    await _progress.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final range = MediaQuery.sizeOf(context).height - _miniHeight;
    if (range <= 0) return;
    _progress.value = (_progress.value -
            (details.primaryDelta ?? 0) / range)
        .clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity.abs() > 600
        ? (velocity < 0 ? 1.0 : 0.0)
        : (_progress.value > 0.5 ? 1.0 : 0.0);

    if (target == 1) {
      await open();
    } else {
      await close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final t = _progress.value;
        final artSize = lerpDouble(42, size.width * 0.56, t)!;
        final artTop = lerpDouble(11, 92, t)!;
        final artLeft = lerpDouble(10, (size.width - artSize) / 2, t)!;
        final cardWidth = size.width - lerpDouble(_miniMargin * 2, 0, t)!;
        final cardHeight = lerpDouble(_miniHeight, size.height, t)!;
        final miniOpacity = 1 - _remap(t, 0, 0.3);
        final expandedOpacity = _remap(t, 0.5, 1);
        final bottomMargin =
            lerpDouble(_navBarHeight + safeBottom + 3, 0, t)!;

        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              margin: EdgeInsets.only(bottom: bottomMargin),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF191919),
                  const Color(0xFF0B0B0B),
                  t,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(lerpDouble(_miniRadius, 0, t)!),
                  topRight: Radius.circular(lerpDouble(_miniRadius, 0, t)!),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: artTop,
                    left: artLeft,
                    width: artSize,
                    height: artSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const _Artwork(showText: false),
                    ),
                  ),
                  Positioned(
                    left: 62,
                    right: 142,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: IgnorePointer(
                        ignoring: t > 0.3,
                        child: GestureDetector(
                          onTap: open,
                          behavior: HitTestBehavior.opaque,
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: _TrackInfo(compact: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 90,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: const _ActionButton(icon: Icons.skip_previous_rounded),
                    ),
                  ),
                  Positioned(
                    right: 45,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: const _ActionButton(icon: Icons.play_arrow_rounded),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: const _ActionButton(icon: Icons.skip_next_rounded),
                    ),
                  ),
                  Positioned(
                    top: artTop + artSize + 42,
                    left: 22,
                    right: 22,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: const _ExpandedPlayer(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 34,
                    right: 8,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: GestureDetector(
                          onTap: close,
                          child: const _ActionButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _remap(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test Track', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        Text('FlowLy Artist', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ExpandedPlayer extends StatelessWidget {
  const _ExpandedPlayer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Test Track', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('FlowLy Artist', style: TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 48),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.transparent,
            trackHeight: 4,
          ),
          child: const Slider(value: 0.28, onChanged: null),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(icon: Icons.skip_previous_rounded, size: 64),
            _LargePlayButton(),
            _ActionButton(icon: Icons.skip_next_rounded, size: 64),
          ],
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.showText});
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF292929),
      alignment: Alignment.center,
      child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 32),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, this.size = 42});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Center(child: Icon(icon, color: Colors.white, size: size * 0.56)),
      );
}

class _LargePlayButton extends StatelessWidget {
  const _LargePlayButton();

  @override
  Widget build(BuildContext context) => Container(
        width: 82,
        height: 82,
        decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
      );
}

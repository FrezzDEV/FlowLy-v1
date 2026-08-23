import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Responsive draggable player adapted from FrezzDEV/FlowLy.
class DraggableView extends StatefulWidget {
  const DraggableView({super.key});

  @override
  State<DraggableView> createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView>
    with SingleTickerProviderStateMixin {
  // Proportions of the available body height instead of fixed pixel heights.
  static const double _miniFactor = 0.085;
  static const double _expandedFactor = 1.0;
  static const double _miniRadiusFactor = 0.022;

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
    final height = MediaQuery.sizeOf(context).height;
    final travel = height * (_expandedFactor - _miniFactor);
    if (travel <= 0) return;
    _progress.value = (_progress.value - (details.primaryDelta ?? 0) / travel)
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final t = _progress.value;
            final heightFactor = lerpDouble(_miniFactor, _expandedFactor, t)!;
            final playerHeight = height * heightFactor;
            final radius = width * _miniRadiusFactor * (1 - t);
            final artSize = lerpDouble(width * 0.12, width * 0.56, t)!;
            final artTop = lerpDouble(playerHeight * 0.18, height * 0.10, t)!;
            final artLeft = lerpDouble(width * 0.025, (width - artSize) / 2, t)!;
            final miniOpacity = 1 - _remap(t, 0, 0.32);
            final expandedOpacity = _remap(t, 0.45, 1);

            return Align(
              alignment: Alignment.bottomCenter,
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
                    children: [
                      Positioned(
                        top: artTop,
                        left: artLeft,
                        width: artSize,
                        height: artSize,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(width * 0.024),
                          child: const _Artwork(),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: t > 0.4,
                          child: Opacity(
                            opacity: miniOpacity,
                            child: _MiniContent(
                              onTap: open,
                              width: width,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: t < 0.5,
                          child: Opacity(
                            opacity: expandedOpacity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                              child: _ExpandedContent(
                                top: artTop + artSize + height * 0.04,
                                width: width,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: height * 0.025,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: t < 0.5,
                          child: Opacity(
                            opacity: expandedOpacity,
                            child: GestureDetector(
                              onTap: close,
                              child: Center(
                                child: Container(
                                  width: width * 0.11,
                                  height: height * 0.006,
                                  decoration: BoxDecoration(
                                    color: Colors.white38,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
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
      },
    );
  }

  double _remap(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
}

class _MiniContent extends StatelessWidget {
  const _MiniContent({required this.onTap, required this.width});

  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Test Track',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'FlowLy Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({required this.top, required this.width});

  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              'Test Track',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.06,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: width * 0.015),
          Align(
            alignment: Alignment.center,
            child: Text(
              'FlowLy Artist',
              style: TextStyle(color: Colors.white70, fontSize: width * 0.038),
            ),
          ),
          SizedBox(height: width * 0.10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
              trackHeight: width * 0.01,
            ),
            child: const Slider(value: 0.28, onChanged: null),
          ),
          SizedBox(height: width * 0.035),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(icon: Icons.skip_previous_rounded, sizeFactor: 0.16),
              _LargePlayButton(),
              _ActionButton(icon: Icons.skip_next_rounded, sizeFactor: 0.16),
            ],
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF292929),
        alignment: Alignment.center,
        child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 32),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.sizeFactor});

  final IconData icon;
  final double sizeFactor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width * sizeFactor;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(icon, color: Colors.white, size: size * 0.56),
      ),
    );
  }
}

class _LargePlayButton extends StatelessWidget {
  const _LargePlayButton();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.20;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}

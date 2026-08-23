import 'package:flutter/material.dart';

void main() => runApp(const FlowLyApp());

class FlowLyApp extends StatelessWidget {
  const FlowLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowLy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showMiniPlayer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeTab(
              onTrackTap: () => setState(() => _showMiniPlayer = true),
            ),
            const EmptyTab(label: 'Search'),
            const EmptyTab(label: 'Library'),
            const EmptyTab(label: 'Profile'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(
                  icon: Icons.home_rounded,
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavIcon(
                  icon: Icons.search_rounded,
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavIcon(
                  icon: Icons.library_music_rounded,
                  selected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavIcon(
                  icon: Icons.person_rounded,
                  selected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _showMiniPlayer ? const MiniPlayer() : null,
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: selected ? 27 : 25,
        color: Colors.black,
      ),
      splashRadius: 24,
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onTrackTap});

  final VoidCallback onTrackTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        const Text(
          'FlowLy',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Home',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        TrackCard(onTap: onTrackTap),
      ],
    );
  }
}

class TrackCard extends StatelessWidget {
  const TrackCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 120,
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE7E7E7), Color(0xFFBEBEBE)],
                ),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Track',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'FlowLy Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0x99000000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  static const double _minHeight = 72;
  static const double _maxHeight = 520;

  late final AnimationController _controller;
  double _height = _minHeight;
  double _dragStartHeight = _minHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartHeight = _height;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _height = (_dragStartHeight - details.localPosition.dy +
              details.globalPosition.dy - details.globalPosition.dy)
          .clamp(_minHeight, _maxHeight);
    });
  }

  void _onDragUpdateSafe(DragUpdateDetails details) {
    setState(() {
      _height = (_height - details.delta.dy).clamp(_minHeight, _maxHeight);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final shouldExpand = _height > (_minHeight + _maxHeight) / 2 ||
        details.primaryVelocity != null && details.primaryVelocity! < -250;
    final target = shouldExpand ? _maxHeight : _minHeight;

    final animation = Tween<double>(begin: _height, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller
      ..reset()
      ..addListener(() {
        if (mounted) {
          setState(() => _height = animation.value);
        }
      })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: _height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdateSafe,
            onVerticalDragEnd: _onDragEnd,
            child: _height < 140 ? _buildCompact() : _buildExpanded(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE7E7E7), Color(0xFFBEBEBE)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'FlowLy Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0x99000000),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE7E7E7), Color(0xFFBEBEBE)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Test Track',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FlowLy Artist',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0x99000000),
                  ),
                ),
                const Spacer(),
                const LinearProgressIndicator(
                  value: 0.28,
                  minHeight: 4,
                  backgroundColor: Color(0xFFE5E5E5),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_previous_rounded, size: 32),
                      color: Colors.black,
                    ),
                    const SizedBox(width: 18),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_next_rounded, size: 32),
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyTab extends StatelessWidget {
  const EmptyTab({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

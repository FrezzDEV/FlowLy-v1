import 'package:flutter/material.dart';

import 'shared/widgets/draggable_view.dart';

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
  // Intentionally compact: the Main bar should read as a small control strip,
  // not as a second large panel.
  static const double _mainBarFactor = 0.06;

  int _selectedIndex = 0;
  bool _showPlayer = false;
  double _playerProgress = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(onTrackTap: () => setState(() => _showPlayer = true)),
      const EmptyTab(label: 'Search'),
      const EmptyTab(label: 'Library'),
      const EmptyTab(label: 'Profile'),
    ];

    final screenHeight = MediaQuery.sizeOf(context).height;
    final mainBarHeight = screenHeight * _mainBarFactor;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
          IgnorePointer(
            ignoring: _playerProgress > 0.65,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, mainBarHeight * _playerProgress),
                child: SizedBox(
                  height: mainBarHeight,
                  width: double.infinity,
                  child: _MainBar(
                    selectedIndex: _selectedIndex,
                    onSelect: (index) => setState(() => _selectedIndex = index),
                  ),
                ),
              ),
            ),
          ),
          if (_showPlayer)
            DraggableView(
              mainBarHeight: mainBarHeight,
              onOpenStateChanged: (expanded) {
                if (!expanded && mounted) {
                  setState(() => _playerProgress = 0);
                }
              },
              onProgressChanged: (progress) {
                if (!mounted) return;
                setState(() => _playerProgress = progress);
              },
            ),
        ],
      ),
    );
  }
}

class _MainBar extends StatelessWidget {
  const _MainBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.home_rounded,
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavIcon(
            icon: Icons.search_rounded,
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavIcon(
            icon: Icons.library_music_rounded,
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavIcon(
            icon: Icons.person_rounded,
            selected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),
        ],
      ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: double.infinity,
        child: Center(
          child: Icon(
            icon,
            size: selected ? 25 : 23,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onTrackTap});

  final VoidCallback onTrackTap;

  @override
  Widget build(BuildContext context) => ListView(
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

class TrackCard extends StatelessWidget {
  const TrackCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 120,
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE7E7E7), Color(0xFFBEBEBE)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Test Track',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class EmptyTab extends StatelessWidget {
  const EmptyTab({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => ListView(
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

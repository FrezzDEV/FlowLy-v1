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
  int _selectedIndex = 0;
  bool _showPlayer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeTab(onTrackTap: () => setState(() => _showPlayer = true)),
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
                _NavIcon(icon: Icons.home_rounded, selected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
                _NavIcon(icon: Icons.search_rounded, selected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
                _NavIcon(icon: Icons.library_music_rounded, selected: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
                _NavIcon(icon: Icons.person_rounded, selected: _selectedIndex == 3, onTap: () => setState(() => _selectedIndex = 3)),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeTab(onTrackTap: () => setState(() => _showPlayer = true)),
                const EmptyTab(label: 'Search'),
                const EmptyTab(label: 'Library'),
                const EmptyTab(label: 'Profile'),
              ],
            ),
          ),
          if (_showPlayer) const DraggableView(),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: selected ? 27 : 25, color: Colors.black),
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
        const Text('FlowLy', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: Colors.black)),
        const SizedBox(height: 28),
        const Text('Home', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
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
                  child: Text('Test Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
                ),
              ),
            ),
          ),
        ),
      ),
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
        Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: Colors.black)),
      ],
    );
  }
}

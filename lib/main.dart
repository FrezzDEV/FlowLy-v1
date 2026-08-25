import 'package:flutter/material.dart';

import 'audio/flowly_audio_handler.dart';
import 'services/flowly_api.dart';
import 'shared/widgets/draggable_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlowLyAudioService.instance.initialize();
  runApp(const FlowLyApp());
}

class FlowLyApp extends StatelessWidget {
  const FlowLyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double _mainBarFactor = 0.06;

  final _api = FlowLyApi();
  int _selectedIndex = 0;
  bool _showPlayer = false;
  double _playerProgress = 0;
  FlowLyTrack? _currentTrack;
  bool _loadingTrack = false;

  Future<void> _openTrack() async {
    if (_loadingTrack) return;
    setState(() => _loadingTrack = true);
    try {
      final results = await _api.search('Test Track');
      if (results.isEmpty) throw Exception('No tracks found');
      final track = results.first;
      final handler = FlowLyAudioService.instance.handler as FlowLyAudioHandler;
      await handler.loadTrack(
        streamUrl: _api.streamUrl(track.videoId),
        title: track.title,
        artist: track.artist,
        artworkUrl: track.thumbnail,
        duration: track.durationSeconds == null
            ? null
            : Duration(seconds: track.durationSeconds!),
        autoplay: true,
      );
      if (mounted) {
        setState(() {
          _currentTrack = track;
          _showPlayer = true;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить трек: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTrack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(onTrackTap: _openTrack, loading: _loadingTrack),
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
            child: IndexedStack(index: _selectedIndex, children: screens),
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
              track: _currentTrack,
              onOpenStateChanged: (expanded) {
                if (!expanded && mounted) setState(() => _playerProgress = 0);
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
  const _MainBar({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            4,
            (index) => _NavIcon(
              icon: [
                Icons.home_rounded,
                Icons.search_rounded,
                Icons.library_music_rounded,
                Icons.person_rounded,
              ][index],
              index: index,
              selected: selectedIndex == index,
              onTap: () => onSelect(index),
            ),
          ),
        ),
      );
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: double.infinity,
          child: Center(
            child: Icon(
              icon,
              size: selected ? 24 : 22,
              color: Colors.black,
            ),
          ),
        ),
      );
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onTrackTap, required this.loading});
  final VoidCallback onTrackTap;
  final bool loading;

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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TrackCard(onTap: onTrackTap, loading: loading),
        ],
      );
}

class TrackCard extends StatelessWidget {
  const TrackCard({super.key, required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 120,
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://picsum.photos/seed/flowly-test-track/600/600',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFFD4D4D4)),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Play from backend',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
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
            ),
          ),
        ],
      );
}

import 'package:flutter/material.dart';

import '../data/datasources/remote/music_api.dart';
import '../data/repositories/music_repository_impl.dart';
import '../domain/repositories/music_repository.dart';
import '../features/player/infrastructure/audio_player_service.dart';
import '../features/player/presentation/widgets/player_host.dart';
import '../features/search/data/search_repository_impl.dart';
import '../features/search/presentation/pages/search_page.dart';

class FlowLyApp extends StatelessWidget {
  const FlowLyApp({super.key, required this.musicRepository});

  final MusicRepository musicRepository;

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
        home: MainScreen(musicRepository: musicRepository),
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.musicRepository});

  final MusicRepository musicRepository;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double _mainBarFactor = 0.06;

  int _selectedIndex = 0;
  bool _showPlayer = false;
  bool _loadingTrack = false;
  double _playerProgress = 0;

  Future<void> _openFeaturedTrack() async {
    if (_loadingTrack) return;
    setState(() => _loadingTrack = true);

    try {
      final results = await widget.musicRepository.search('Test Track');
      if (results.isEmpty) throw StateError('No tracks found');

      final track = results.first;
      final handler = AudioServiceManager.instance.handler as AudioPlayerService;
      await handler.loadTrack(
        streamUrl: widget.musicRepository.streamUrl(track.videoId),
        title: track.title,
        artist: track.artist,
        artworkUrl: track.thumbnail,
        duration: track.durationSeconds == null
            ? null
            : Duration(seconds: track.durationSeconds!),
        autoplay: true,
      );

      if (mounted) setState(() => _showPlayer = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить трек: $error')),
      );
    } finally {
      if (mounted) setState(() => _loadingTrack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mainBarHeight = screenHeight * _mainBarFactor;
    final searchRepository = SearchRepositoryImpl(widget.musicRepository);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeTab(onTrackTap: _openFeaturedTrack, loading: _loadingTrack),
                SearchPage(searchRepository: searchRepository),
                const EmptyTab(label: 'Library'),
                const EmptyTab(label: 'Profile'),
              ],
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
            PlayerHost(
              mainBarHeight: mainBarHeight,
              onOpenStateChanged: (expanded) {
                if (!expanded && mounted) setState(() => _playerProgress = 0);
              },
              onProgressChanged: (progress) {
                if (mounted) setState(() => _playerProgress = progress);
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

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.library_music_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _icons.length,
            (index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(index),
              child: SizedBox(
                width: 44,
                height: double.infinity,
                child: Center(
                  child: Icon(
                    _icons[index],
                    size: selectedIndex == index ? 24 : 22,
                    color: Colors.black,
                  ),
                ),
              ),
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
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Home',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: loading ? null : onTrackTap,
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
                          colors: [
                            Colors.transparent,
                            Color(0x99000000),
                          ],
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
          ),
        ],
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

MusicRepository createMusicRepository() => MusicRepositoryImpl(MusicApi());

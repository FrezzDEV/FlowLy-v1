import 'package:flutter/material.dart';

import '../data/datasources/remote/music_api.dart';
import '../data/models/track_model.dart';
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
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
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
  double _playerProgress = 0;

  Future<void> _playTrack(FlowLyTrack track) async {
    try {
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить трек. Проверьте подключение к FlowLy API.'),
        ),
      );
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
                HomeTab(
                  repository: widget.musicRepository,
                  onTrackTap: _playTrack,
                  onSeeAll: () => setState(() => _selectedIndex = 1),
                ),
                SearchPage(
                  searchRepository: searchRepository,
                  onPlayerRequested: () => setState(() => _showPlayer = true),
                ),
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
        color: Colors.black,
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
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.repository,
    required this.onTrackTap,
    required this.onSeeAll,
  });

  final MusicRepository repository;
  final ValueChanged<FlowLyTrack> onTrackTap;
  final VoidCallback onSeeAll;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<FlowLyTrack>> _trendingFuture;

  @override
  void initState() {
    super.initState();
    _trendingFuture = widget.repository.trending();
  }

  void _retry() {
    setState(() => _trendingFuture = widget.repository.trending());
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: () async => _retry(),
        child: ListView(
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
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Трендовые треки для вас',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: widget.onSeeAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Смотреть все'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<FlowLyTrack>>(
              future: _trendingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const _TrendingSkeleton();
                }

                if (snapshot.hasError) {
                  return _TrendingError(onRetry: _retry);
                }

                final tracks = snapshot.data ?? const <FlowLyTrack>[];
                if (tracks.isEmpty) {
                  return _TrendingError(
                    message: 'Пока не удалось загрузить трендовые треки.',
                    onRetry: _retry,
                  );
                }

                return Column(
                  children: [
                    for (final track in tracks)
                      _TrendingTrackTile(
                        track: track,
                        onTap: () => widget.onTrackTap(track),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _TrendingTrackTile extends StatelessWidget {
  const _TrendingTrackTile({required this.track, required this.onTap});

  final FlowLyTrack track;
  final VoidCallback onTap;

  String _durationLabel(int? seconds) {
    if (seconds == null || seconds < 0) return '—';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: track.thumbnail == null
                        ? const ColoredBox(
                            color: Color(0xFF181818),
                            child: Icon(Icons.music_note_rounded, color: Colors.white54),
                          )
                        : Image.network(
                            track.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFF181818),
                              child: Icon(Icons.music_note_rounded, color: Colors.white54),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${track.artist} • ${_durationLabel(track.durationSeconds)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F8F8F),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  splashRadius: 22,
                  color: Colors.white70,
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF151515),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(
                        width: 180,
                        height: 16,
                        child: ColoredBox(color: Color(0xFF171717)),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: 130,
                        height: 13,
                        child: ColoredBox(color: Color(0xFF131313)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TrendingError extends StatelessWidget {
  const _TrendingError({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message ?? 'Не удалось загрузить трендовые треки.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ],
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

MusicRepository createMusicRepository() => MusicRepositoryImpl(MusicApi());

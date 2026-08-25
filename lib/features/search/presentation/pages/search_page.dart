import 'package:flutter/material.dart';

import '../../../../data/models/track_model.dart';
import '../../../player/infrastructure/audio_player_service.dart';
import '../../domain/search_repository.dart';
import '../bloc/search_controller.dart';
import '../../data/recent_search_store.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.searchRepository,
    required this.onPlayerRequested,
  });

  final SearchRepository searchRepository;
  final VoidCallback onPlayerRequested;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final FlowLySearchController _controller;
  late final RecentSearchStore _recentStore;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  List<String> _recentSearches = const <String>[];
  String? _playingVideoId;
  bool _loadingTrack = false;

  @override
  void initState() {
    super.initState();
    _controller = FlowLySearchController(widget.searchRepository);
    _recentStore = const RecentSearchStore();
    _focusNode.requestFocus();
    _controller.addListener(_onChanged);
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final recent = await _recentStore.load();
    if (!mounted) return;
    setState(() => _recentSearches = recent);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectRecent(String query) async {
    _textController.text = query;
    _textController.selection = TextSelection.collapsed(offset: query.length);
    await _controller.search(query);
    if (mounted) setState(() {});
  }

  Future<void> _removeRecent(String query) async {
    await _recentStore.remove(query);
    await _loadRecentSearches();
  }

  Future<void> _play(FlowLyTrack track) async {
    if (_loadingTrack) return;
    setState(() {
      _loadingTrack = true;
      _playingVideoId = track.videoId;
    });

    try {
      final audio = AudioServiceManager.instance.handler as AudioPlayerService;
      await audio.loadTrack(
        streamUrl: widget.searchRepository.streamUrl(track.videoId),
        title: track.title,
        artist: track.artist,
        artworkUrl: track.thumbnail,
        duration: track.durationSeconds == null
            ? null
            : Duration(seconds: track.durationSeconds!),
        autoplay: true,
      );

      final query = _textController.text.trim();
      if (query.isNotEmpty) {
        await _recentStore.add(query);
        if (mounted) await _loadRecentSearches();
      }
      widget.onPlayerRequested();
    } catch (_) {
      if (mounted) {
        setState(() => _playingVideoId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось воспроизвести трек')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTrack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _textController.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
      children: [
        const Text(
          'Search',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: _controller.queryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Songs, artists or albums',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: hasQuery
                ? IconButton(
                    onPressed: () {
                      _textController.clear();
                      _controller.queryChanged('');
                      _focusNode.requestFocus();
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (!hasQuery) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await _recentStore.clear();
                    if (mounted) setState(() => _recentSearches = const []);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_recentSearches.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                'Your recent searches will appear here',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ..._recentSearches.map(
              (query) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.history_rounded),
                title: Text(query),
                trailing: IconButton(
                  tooltip: 'Remove',
                  onPressed: () => _removeRecent(query),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
                onTap: () => _selectRecent(query),
              ),
            ),
        ] else ...[
          const Text(
            'Search results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_controller.isLoading)
            ...List.generate(
              5,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: LinearProgressIndicator(minHeight: 10),
              ),
            )
          else if (_controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  const Text('Не удалось выполнить поиск'),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => _controller.search(_textController.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          else if (_controller.results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Ничего не найдено',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ..._controller.results.map(
              (FlowLyTrack track) => SearchResultTile(
                track: track,
                isPlaying: _playingVideoId == track.videoId,
                onTap: () => _play(track),
              ),
            ),
        ],
      ],
    );
  }
}

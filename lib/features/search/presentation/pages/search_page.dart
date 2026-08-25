import 'package:flutter/material.dart';

import '../../../data/models/track_model.dart';
import '../../player/infrastructure/audio_player_service.dart';
import '../data/search_repository_impl.dart';
import '../domain/search_repository.dart';
import '../presentation/bloc/search_controller.dart';
import '../presentation/widgets/search_result_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.searchRepository});

  final SearchRepository searchRepository;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchController _controller;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  final List<String> _recentSearches = <String>[
    'The Weeknd',
    'Blinding Lights',
    'Daft Punk',
  ];

  String? _playingVideoId;
  bool _loadingTrack = false;

  @override
  void initState() {
    super.initState();
    _controller = SearchController(widget.searchRepository);
    _focusNode.requestFocus();
    _controller.addListener(_onChanged);
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

  Future<void> _play(FlowLyTrack track) async {
    if (_loadingTrack) return;
    setState(() {
      _loadingTrack = true;
      _playingVideoId = track.videoId;
    });

    try {
      final audio = AudioServiceManager.instance.handler as AudioPlayerService;
      await audio.loadTrack(
        streamUrl: widget.searchRepository is SearchRepositoryImpl
            ? (widget.searchRepository as SearchRepositoryImpl)
                .musicRepository
                .streamUrl(track.videoId)
            : '',
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
        _recentSearches.remove(query);
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 6) _recentSearches.removeLast();
      }
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
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
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
                      setState(() {});
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
          const Text(
            'Recent',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ..._recentSearches.map(
            (query) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.history_rounded),
              title: Text(query),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _textController.text = query;
                _textController.selection = TextSelection.collapsed(offset: query.length);
                _controller.search(query);
                setState(() {});
              },
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
                  Text(_controller.error!),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _controller.search(_textController.text.trim()),
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
              (track) => SearchResultTile(
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

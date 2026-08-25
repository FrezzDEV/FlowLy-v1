import 'dart:convert';

import 'package:http/http.dart' as http;

class FlowLyApi {
  FlowLyApi({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  // Android emulator -> host machine. Override this for a physical device/server.
  static const defaultBaseUrl = 'http://10.0.2.2:4000/api';
  final String baseUrl;

  Future<List<FlowLyTrack>> search(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search').replace(queryParameters: {'q': query}));
    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['results'] as List<dynamic>? ?? const [])
        .map((item) => FlowLyTrack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String streamUrl(String videoId) => '$baseUrl/stream/$videoId';
}

class FlowLyTrack {
  const FlowLyTrack({
    required this.videoId,
    required this.title,
    required this.artist,
    this.thumbnail,
    this.durationSeconds,
  });

  factory FlowLyTrack.fromJson(Map<String, dynamic> json) => FlowLyTrack(
        videoId: json['videoId'] as String,
        title: json['title'] as String? ?? 'Unknown track',
        artist: json['artist'] as String? ?? 'Unknown artist',
        thumbnail: json['thumbnail'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      );

  final String videoId;
  final String title;
  final String artist;
  final String? thumbnail;
  final int? durationSeconds;
}

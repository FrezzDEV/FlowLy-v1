import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../models/track_model.dart';

class MusicApi {
  MusicApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;

  Future<List<FlowLyTrack>> search(String query) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/search').replace(
        queryParameters: {'q': query},
      ),
    );

    if (response.statusCode != 200) {
      throw MusicApiException('Search failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['results'] as List<dynamic>? ?? const [])
        .map((item) => FlowLyTrack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String streamUrl(String videoId) => '$baseUrl/stream/$videoId';

  void dispose() => _client.close();
}

class MusicApiException implements Exception {
  const MusicApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

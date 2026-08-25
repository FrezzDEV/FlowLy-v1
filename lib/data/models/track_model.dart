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

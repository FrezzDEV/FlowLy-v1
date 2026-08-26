import '../../data/models/track_model.dart';

abstract interface class MusicRepository {
  Future<List<FlowLyTrack>> search(String query);
  Future<List<FlowLyTrack>> trending();
  String streamUrl(String videoId);
}

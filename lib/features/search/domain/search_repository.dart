import '../../../data/models/track_model.dart';

abstract interface class SearchRepository {
  Future<List<FlowLyTrack>> search(String query);
  String streamUrl(String videoId);
}

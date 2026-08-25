import '../../domain/repositories/music_repository.dart';
import '../datasources/remote/music_api.dart';
import '../models/track_model.dart';

class MusicRepositoryImpl implements MusicRepository {
  MusicRepositoryImpl(this._api);

  final MusicApi _api;

  @override
  Future<List<FlowLyTrack>> search(String query) => _api.search(query);

  @override
  String streamUrl(String videoId) => _api.streamUrl(videoId);
}

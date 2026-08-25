import '../../../data/models/track_model.dart';
import '../../../domain/repositories/music_repository.dart';
import '../domain/search_repository.dart';

final class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this.musicRepository);

  final MusicRepository musicRepository;

  @override
  Future<List<FlowLyTrack>> search(String query) => musicRepository.search(query);
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/track_model.dart';
import '../../domain/search_repository.dart';

final class FlowLySearchController extends ChangeNotifier {
  FlowLySearchController(this.repository);

  final SearchRepository repository;
  Timer? _debounce;
  bool isLoading = false;
  String? error;
  List<FlowLyTrack> results = const [];

  void queryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      isLoading = false;
      error = null;
      results = const [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      search(query);
    });
  }

  Future<void> search(String query) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      results = await repository.search(query);
    } catch (_) {
      results = const [];
      error = 'Не удалось выполнить поиск';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

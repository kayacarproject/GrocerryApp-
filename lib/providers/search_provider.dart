import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/debouncer.dart';
import '../models/product.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const AsyncData([]),
    this.recent = const [],
  });

  final String query;
  final AsyncValue<List<Product>> results;
  final List<String> recent;

  bool get hasQuery => query.trim().length >= SearchNotifier.minQueryLength;

  SearchState copyWith({
    String? query,
    AsyncValue<List<Product>>? results,
    List<String>? recent,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    recent: recent ?? this.recent,
  );
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

final popularSearchesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(catalogRepositoryProvider).getPopularSearches(),
);

class SearchNotifier extends Notifier<SearchState> {
  static const minQueryLength = 2;
  static const _maxRecent = 8;

  final _debouncer = Debouncer(delay: const Duration(milliseconds: 400));

  // Guards against slow responses for an older query overwriting newer ones.
  int _requestId = 0;

  @override
  SearchState build() {
    ref.onDispose(_debouncer.dispose);
    return SearchState(recent: ref.read(localCacheProvider).recentSearches);
  }

  /// Called on every keystroke; the API is only hit once typing pauses.
  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    if (query.trim().length < minQueryLength) {
      _debouncer.cancel();
      _requestId++;
      state = state.copyWith(results: const AsyncData([]));
      return;
    }
    _debouncer.run(() => _search(query));
  }

  /// Immediate search, e.g. keyboard "search" action or tapping a suggestion.
  Future<void> submit(String query) async {
    final term = query.trim();
    if (term.isEmpty) return;
    _debouncer.cancel();
    state = state.copyWith(query: term);
    _saveRecent(term);
    await _search(term);
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    state = state.copyWith(results: const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).search(query),
    );
    if (requestId == _requestId) state = state.copyWith(results: result);
  }

  void clear() => onQueryChanged('');

  void _saveRecent(String term) {
    final updated = [
      term,
      ...state.recent.where((t) => t.toLowerCase() != term.toLowerCase()),
    ].take(_maxRecent).toList();
    state = state.copyWith(recent: updated);
    ref.read(localCacheProvider).setRecentSearches(updated);
  }

  void removeRecent(String term) {
    final updated = state.recent.where((t) => t != term).toList();
    state = state.copyWith(recent: updated);
    ref.read(localCacheProvider).setRecentSearches(updated);
  }

  void clearRecent() {
    state = state.copyWith(recent: const []);
    ref.read(localCacheProvider).setRecentSearches(const []);
  }
}

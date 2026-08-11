import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/products/data/datasources/search_history_local_data_source.dart';
import 'package:untitled3/features/products/domain/entities/product.dart';
import 'package:untitled3/features/products/presentation/providers/product_providers.dart';

final searchHistoryDataSourceProvider =
    Provider<SearchHistoryLocalDataSource>((ref) => SearchHistoryLocalDataSource());

/// Raw text as the user types; debounces writes into
/// [debouncedSearchQueryProvider] (400ms) so [searchResultsProvider] only
/// re-runs once typing pauses, not on every keystroke.
class SearchQueryController extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void update(String value) {
    state = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(debouncedSearchQueryProvider.notifier).set(value.trim());
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
    ref.read(debouncedSearchQueryProvider.notifier).set('');
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

class DebouncedSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final debouncedSearchQueryProvider =
    NotifierProvider<DebouncedSearchQueryController, String>(DebouncedSearchQueryController.new);

/// Search results.
///
/// LIMITATION (documented, not hidden): Firestore has no native full-text
/// search. There is no maintained lowercase-name field on product
/// documents to drive an indexed prefix query (`where('name_lowercase',
/// isGreaterThanOrEqualTo: q)...`), and adding one now would require a
/// backend migration/Cloud Function to backfill every existing product —
/// out of scope for this buyer-features batch. Instead this filters
/// client-side over `activeProductsProvider`'s already-loaded stream. That
/// is fine at the current catalog size but does NOT scale: every keystroke
/// (after debounce) re-scans the full active-product list in memory, and
/// opening search at all forces that unbounded stream to load if nothing
/// else on screen already needed it. A real fix is either (a) add a
/// maintained `name_lowercase` field (small backend addition + one-time
/// backfill script) and switch this to a server-side range query, or (b) a
/// dedicated search service (Algolia/Typesense/Meilisearch) synced via a
/// Cloud Function trigger on product writes.
final searchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider);
  if (query.isEmpty) return const [];
  final products = await ref.watch(activeProductsProvider.future);
  final lower = query.toLowerCase();
  return products.where((p) => p.name.toLowerCase().contains(lower)).toList();
});

class SearchHistoryController extends AsyncNotifier<List<String>> {
  late final SearchHistoryLocalDataSource _dataSource;

  @override
  FutureOr<List<String>> build() {
    _dataSource = ref.watch(searchHistoryDataSourceProvider);
    return _dataSource.getRecent();
  }

  Future<void> record(String query) async {
    await _dataSource.add(query);
    state = AsyncData(await _dataSource.getRecent());
  }

  Future<void> clear() async {
    await _dataSource.clear();
    state = const AsyncData([]);
  }
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryController, List<String>>(SearchHistoryController.new);

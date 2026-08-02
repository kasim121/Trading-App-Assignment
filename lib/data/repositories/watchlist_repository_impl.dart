import '../../domain/entities/watchlist.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../local/trading_local_store.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(this._store);

  final TradingLocalStore _store;

  @override
  List<Watchlist> loadWatchlists() => _store.loadWatchlists();

  @override
  String? loadActiveWatchlistId() => _store.loadActiveWatchlistId();

  @override
  Future<void> saveWatchlists(List<Watchlist> lists) =>
      _store.saveWatchlists(lists);

  @override
  Future<void> saveActiveWatchlistId(String id) =>
      _store.saveActiveWatchlistId(id);

  @override
  String newId() => _store.newId();
}

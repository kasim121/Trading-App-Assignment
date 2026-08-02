import '../entities/watchlist.dart';


abstract class WatchlistRepository {
  List<Watchlist> loadWatchlists();

  String? loadActiveWatchlistId();

  Future<void> saveWatchlists(List<Watchlist> lists);

  Future<void> saveActiveWatchlistId(String id);

  String newId();
}

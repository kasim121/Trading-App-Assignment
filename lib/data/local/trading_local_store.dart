import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/money/money.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/watchlist.dart';

const Money kStartingBalance = Money(10000000); 


class TradingLocalStore {
  TradingLocalStore(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  static const _kWatchlists = 'watchlists_v1';
  static const _kActiveWatchlistId = 'active_watchlist_id_v1';
  static const _kBalance = 'wallet_balance_paise_v1';
  static const _kHoldings = 'holdings_v1';
  static const _kOrders = 'orders_v1';

  static Future<TradingLocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return TradingLocalStore(prefs);
  }



  List<Watchlist> loadWatchlists() {
    final raw = _prefs.getString(_kWatchlists);
    if (raw == null || raw.isEmpty) {
      final seed = Watchlist(
        id: _uuid.v4(),
        name: 'Watchlist 1',
        symbols: const [],
      );
      saveWatchlists([seed]);
      saveActiveWatchlistId(seed.id);
      return [seed];
    }
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Watchlist.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isEmpty) {
      final seed = Watchlist(
        id: _uuid.v4(),
        name: 'Watchlist 1',
        symbols: const [],
      );
      saveWatchlists([seed]);
      return [seed];
    }
    return list;
  }

  Future<void> saveWatchlists(List<Watchlist> lists) async {
    final encoded = jsonEncode(lists.map((w) => w.toJson()).toList());
    await _prefs.setString(_kWatchlists, encoded);
  }

  String? loadActiveWatchlistId() => _prefs.getString(_kActiveWatchlistId);

  Future<void> saveActiveWatchlistId(String id) async {
    await _prefs.setString(_kActiveWatchlistId, id);
  }

  String newId() => _uuid.v4();



  Money loadBalance() {
    final paise = _prefs.getInt(_kBalance);
    if (paise == null) {
      _prefs.setInt(_kBalance, kStartingBalance.paise);
      return kStartingBalance;
    }
    return Money(paise);
  }

  Future<void> saveBalance(Money balance) async {
    await _prefs.setInt(_kBalance, balance.paise);
  }

  Map<String, Holding> loadHoldings() {
    final raw = _prefs.getString(_kHoldings);
    if (raw == null || raw.isEmpty) return {};
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Holding.fromJson(e as Map<String, dynamic>))
        .toList();
    return {for (final h in list) h.symbol: h};
  }

  Future<void> saveHoldings(Map<String, Holding> holdings) async {
    final encoded =
        jsonEncode(holdings.values.map((h) => h.toJson()).toList());
    await _prefs.setString(_kHoldings, encoded);
  }

  List<Order> loadOrders() {
    final raw = _prefs.getString(_kOrders);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveOrders(List<Order> orders) async {
    final encoded = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs.setString(_kOrders, encoded);
  }
}

import '../../domain/repositories/portfolio_repository.dart';
import '../local/trading_local_store.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl(this._store);

  final TradingLocalStore _store;

  @override
  PortfolioSnapshot load() {
    return PortfolioSnapshot(
      balance: _store.loadBalance(),
      holdings: _store.loadHoldings(),
      orders: _store.loadOrders(),
    );
  }

  @override
  Future<void> save(PortfolioSnapshot snapshot) async {
    await _store.saveBalance(snapshot.balance);
    await _store.saveHoldings(snapshot.holdings);
    await _store.saveOrders(snapshot.orders);
  }

  @override
  String newId() => _store.newId();
}

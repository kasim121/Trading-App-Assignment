import '../../domain/entities/price_tick.dart';
import '../../domain/repositories/market_repository.dart';
import '../market/mock_market_feed.dart';


class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl(this._feed);

  final MockMarketFeed _feed;

  @override
  Map<String, PriceTick> get snapshot => _feed.snapshot;

  @override
  PriceTick? latest(String symbol) => _feed.latest(symbol);

  @override
  Stream<PriceTick> get ticks => _feed.ticks;

  @override
  Stream<PriceTick> watch(String symbol) => _feed.watch(symbol);

  @override
  double get ticksPerSecondPerStock => _feed.ticksPerSecondPerStock;

  @override
  void setTicksPerSecondPerStock(double value) =>
      _feed.setTicksPerSecondPerStock(value);

  @override
  void start() => _feed.start();

  @override
  void stop() => _feed.stop();
}

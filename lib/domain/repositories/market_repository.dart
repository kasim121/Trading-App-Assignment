import '../entities/price_tick.dart';


abstract class MarketRepository {
  Map<String, PriceTick> get snapshot;

  PriceTick? latest(String symbol);

  Stream<PriceTick> get ticks;

  Stream<PriceTick> watch(String symbol);

  double get ticksPerSecondPerStock;

  void setTicksPerSecondPerStock(double value);

  void start();

  void stop();
}

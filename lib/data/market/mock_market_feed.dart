import 'dart:async';
import 'dart:math';

import '../../core/constants/market_feed_config.dart';
import '../../core/constants/stocks.dart';
import '../../core/money/money.dart';
import '../../domain/entities/price_tick.dart';


class MockMarketFeed {
  MockMarketFeed({
    double ticksPerSecondPerStock = MarketFeedConfig.ticksPerSecondPerStock,
    Random? random,
  })  : _ticksPerSecondPerStock = ticksPerSecondPerStock,
        _random = random ?? Random() {
    _seed();
  }

  final Random _random;


  double _ticksPerSecondPerStock;

  final Map<String, PriceTick> _latest = {};
  final Map<String, StreamController<PriceTick>> _controllers = {};
  final _allTicksController = StreamController<PriceTick>.broadcast();

  Timer? _timer;
  bool _running = false;

  double get ticksPerSecondPerStock => _ticksPerSecondPerStock;


  Map<String, PriceTick> get snapshot => Map.unmodifiable(_latest);

  PriceTick? latest(String symbol) => _latest[symbol];


  Stream<PriceTick> get ticks => _allTicksController.stream;


  Stream<PriceTick> watch(String symbol) async* {
    final current = _latest[symbol];
    if (current != null) yield current;
    final controller = _controllers.putIfAbsent(
      symbol,
      () => StreamController<PriceTick>.broadcast(),
    );
    yield* controller.stream;
  }

  void start() {
    if (_running) return;
    _running = true;
    _restartTimer();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }


  void setTicksPerSecondPerStock(double value) {
    _ticksPerSecondPerStock = value.clamp(0.1, 30.0);
    if (_running) _restartTimer();
  }

  void dispose() {
    stop();
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _allTicksController.close();
  }

  void _seed() {
    final now = DateTime.now();
    for (final symbol in Stocks.symbols) {
      final open = Money(Stocks.startingPricesPaise[symbol]!);
      final tick = PriceTick(
        symbol: symbol,
        ltp: open,
        open: open,
        previousLtp: open,
        timestamp: now,
      );
      _latest[symbol] = tick;
      _controllers.putIfAbsent(
        symbol,
        () => StreamController<PriceTick>.broadcast(),
      );
    }
  }

  void _restartTimer() {
    _timer?.cancel();

    final overallPerSecond =
        _ticksPerSecondPerStock * Stocks.symbols.length;
    final intervalMs = (1000 / overallPerSecond).round().clamp(8, 1000);
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _emitOneRandomTick();
    });
  }

  void _emitOneRandomTick() {
    final symbol = Stocks.symbols[_random.nextInt(Stocks.symbols.length)];
    final previous = _latest[symbol]!;
    final nextLtp = _nextPrice(previous.ltp);
    final tick = PriceTick(
      symbol: symbol,
      ltp: nextLtp,
      open: previous.open,
      previousLtp: previous.ltp,
      timestamp: DateTime.now(),
    );
    _latest[symbol] = tick;
    _controllers[symbol]?.add(tick);
    if (!_allTicksController.isClosed) {
      _allTicksController.add(tick);
    }
  }

  Money _nextPrice(Money current) {

    final maxMove = (current.paise * MarketFeedConfig.maxMoveFraction)
        .round()
        .clamp(1, current.paise);
    final delta = _random.nextInt(maxMove * 2 + 1) - maxMove;
    final next = (current.paise + delta)
        .clamp(MarketFeedConfig.minPricePaise, 1 << 62);
    return Money(next);
  }
}

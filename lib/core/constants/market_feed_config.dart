/// Tunables for the mock market-data feed.
///
/// Interview talking point: tick rate is a constant (or debug setting), not
/// buried inside the timer, so we can stress the UI without rewriting logic.
class MarketFeedConfig {
  MarketFeedConfig._();

  /// Default: ~2 ticks per stock per second → ~20 ticks/sec overall.
  /// Raise to 5+ for the stress scenario in Feature 2.
  static const double ticksPerSecondPerStock = 2.0;

  /// Stress profile used from the Market screen debug toggle.
  static const double stressTicksPerSecondPerStock = 5.0;

  /// Max absolute random move per tick as a fraction of LTP (e.g. 0.15%).
  static const double maxMoveFraction = 0.0015;

  /// Floor so prices never go non-positive after a down tick.
  static const int minPricePaise = 100; // ₹1.00
}

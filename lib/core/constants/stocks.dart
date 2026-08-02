/// The fixed universe of tradeable symbols for this assignment.
///
/// Keeping this as a single source of truth avoids hardcoding the list
/// across watchlist pickers, market overview, and seed prices.
class Stocks {
  Stocks._();

  static const List<String> symbols = [
    'RELIANCE',
    'TCS',
    'INFY',
    'HDFCBANK',
    'ICICIBANK',
    'SBIN',
    'ITC',
    'LT',
    'BHARTIARTL',
    'AXISBANK',
  ];

  /// Starting last-traded prices in paise (₹ × 100).
  /// Reasonable NSE-like levels as of a typical market day — not live data.
  static const Map<String, int> startingPricesPaise = {
    'RELIANCE': 298450, // ₹2,984.50
    'TCS': 412080, // ₹4,120.80
    'INFY': 187520, // ₹1,875.20
    'HDFCBANK': 168340, // ₹1,683.40
    'ICICIBANK': 124560, // ₹1,245.60
    'SBIN': 84230, // ₹842.30
    'ITC': 45870, // ₹458.70
    'LT': 356210, // ₹3,562.10
    'BHARTIARTL': 158940, // ₹1,589.40
    'AXISBANK': 112780, // ₹1,127.80
  };
}

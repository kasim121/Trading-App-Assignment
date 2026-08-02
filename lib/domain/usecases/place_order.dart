import '../../core/money/money.dart';
import '../entities/holding.dart';
import '../entities/order.dart';
import '../failures/order_exception.dart';
import '../repositories/portfolio_repository.dart';


class PlaceOrderUseCase {
  const PlaceOrderUseCase();

  PlaceOrderResult call({
    required PortfolioSnapshot current,
    required String symbol,
    required OrderSide side,
    required int quantity,
    required Money ltp,
    required String orderId,
    DateTime? now,
  }) {
    if (quantity <= 0) {
      throw const OrderException('Quantity must be a positive whole number.');
    }
    if (ltp.isZero || ltp.isNegative) {
      throw const OrderException('Invalid market price.');
    }

    final value = ltp.times(quantity);
    var balance = current.balance;
    final holdings = Map<String, Holding>.from(current.holdings);

    if (side == OrderSide.buy) {
      if (value > balance) {
        throw OrderException(
          'Insufficient balance. Need ${value.format()}, have ${balance.format()}.',
        );
      }
      balance = balance - value;
      final existing = holdings[symbol];
      if (existing == null) {
        holdings[symbol] = Holding(
          symbol: symbol,
          quantity: quantity,
          avgCost: ltp,
        );
      } else {
        final totalCost =
            existing.avgCost.times(existing.quantity) + ltp.times(quantity);
        final newQty = existing.quantity + quantity;
        final newAvg = Money((totalCost.paise / newQty).round());
        holdings[symbol] = existing.copyWith(
          quantity: newQty,
          avgCost: newAvg,
        );
      }
    } else {
      final held = holdings[symbol]?.quantity ?? 0;
      if (quantity > held) {
        throw OrderException(
          'Cannot sell $quantity. You hold $held shares of $symbol.',
        );
      }
      balance = balance + value;
      final remaining = held - quantity;
      if (remaining == 0) {
        holdings.remove(symbol);
      } else {
        holdings[symbol] = holdings[symbol]!.copyWith(quantity: remaining);
      }
    }

    final order = Order(
      id: orderId,
      symbol: symbol,
      side: side,
      quantity: quantity,
      price: ltp,
      value: value,
      createdAt: now ?? DateTime.now(),
    );

    return PlaceOrderResult(
      snapshot: PortfolioSnapshot(
        balance: balance,
        holdings: holdings,
        orders: [order, ...current.orders],
      ),
      order: order,
    );
  }
}

class PlaceOrderResult {
  const PlaceOrderResult({required this.snapshot, required this.order});

  final PortfolioSnapshot snapshot;
  final Order order;
}

import '../../core/money/money.dart';
import '../entities/holding.dart';
import '../entities/order.dart';


class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.balance,
    required this.holdings,
    required this.orders,
  });

  final Money balance;
  final Map<String, Holding> holdings;
  final List<Order> orders;
}


abstract class PortfolioRepository {
  PortfolioSnapshot load();

  Future<void> save(PortfolioSnapshot snapshot);

  String newId();
}

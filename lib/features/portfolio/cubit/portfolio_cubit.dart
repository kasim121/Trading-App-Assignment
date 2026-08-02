import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/holding.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/failures/order_exception.dart';
import '../../../domain/repositories/portfolio_repository.dart';
import '../../../domain/usecases/place_order.dart';

class PortfolioState extends Equatable {
  const PortfolioState({
    required this.balance,
    required this.holdings,
    required this.orders,
  });

  final Money balance;
  final Map<String, Holding> holdings;
  final List<Order> orders;

  int quantityHeld(String symbol) => holdings[symbol]?.quantity ?? 0;

  factory PortfolioState.fromSnapshot(PortfolioSnapshot snapshot) {
    return PortfolioState(
      balance: snapshot.balance,
      holdings: snapshot.holdings,
      orders: snapshot.orders,
    );
  }

  PortfolioSnapshot toSnapshot() => PortfolioSnapshot(
        balance: balance,
        holdings: holdings,
        orders: orders,
      );

  PortfolioState copyWith({
    Money? balance,
    Map<String, Holding>? holdings,
    List<Order>? orders,
  }) {
    return PortfolioState(
      balance: balance ?? this.balance,
      holdings: holdings ?? this.holdings,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [balance, holdings, orders];
}

/// Presentation state for wallet + holdings. Delegates rules to [PlaceOrderUseCase].
class PortfolioCubit extends Cubit<PortfolioState> {
  PortfolioCubit(
    this._repository, {
    PlaceOrderUseCase placeOrderUseCase = const PlaceOrderUseCase(),
  })  : _placeOrder = placeOrderUseCase,
        super(PortfolioState.fromSnapshot(_repository.load()));

  final PortfolioRepository _repository;
  final PlaceOrderUseCase _placeOrder;

  /// Executes a market order at [ltp]. Throws [OrderException] on validation failure.
  Future<Order> placeOrder({
    required String symbol,
    required OrderSide side,
    required int quantity,
    required Money ltp,
  }) async {
    final result = _placeOrder(
      current: state.toSnapshot(),
      symbol: symbol,
      side: side,
      quantity: quantity,
      ltp: ltp,
      orderId: _repository.newId(),
    );

    emit(PortfolioState.fromSnapshot(result.snapshot));
    await _repository.save(result.snapshot);
    return result.order;
  }
}

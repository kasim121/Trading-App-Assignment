import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/failures/order_exception.dart';
import '../../portfolio/cubit/portfolio_cubit.dart';

class TicketState extends Equatable {
  const TicketState({
    required this.symbol,
    required this.side,
    required this.quantityText,
    this.quantityError,
    this.submitError,
    this.submitting = false,
    this.placedOrder,
  });

  final String symbol;
  final OrderSide side;
  final String quantityText;
  final String? quantityError;
  final String? submitError;
  final bool submitting;
  final Order? placedOrder;

  int? get parsedQuantity {
    if (quantityText.trim().isEmpty) return null;
    return int.tryParse(quantityText.trim());
  }

  TicketState copyWith({
    OrderSide? side,
    String? quantityText,
    String? quantityError,
    bool clearQuantityError = false,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitting,
    Order? placedOrder,
  }) {
    return TicketState(
      symbol: symbol,
      side: side ?? this.side,
      quantityText: quantityText ?? this.quantityText,
      quantityError:
          clearQuantityError ? null : (quantityError ?? this.quantityError),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitting: submitting ?? this.submitting,
      placedOrder: placedOrder ?? this.placedOrder,
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        side,
        quantityText,
        quantityError,
        submitError,
        submitting,
        placedOrder,
      ];
}

class TicketCubit extends Cubit<TicketState> {
  TicketCubit({
    required this.portfolio,
    required String symbol,
    OrderSide initialSide = OrderSide.buy,
  }) : super(
          TicketState(
            symbol: symbol,
            side: initialSide,
            quantityText: '',
          ),
        );

  final PortfolioCubit portfolio;

  void setSide(OrderSide side) {
    emit(state.copyWith(
      side: side,
      clearQuantityError: true,
      clearSubmitError: true,
    ));
  }

  void setQuantityText(String text) {
    emit(state.copyWith(
      quantityText: text,
      clearQuantityError: true,
      clearSubmitError: true,
    ));
  }

  String? _validateQuantity({required int held}) {
    final raw = state.quantityText.trim();
    if (raw.isEmpty) return 'Enter quantity';
    if (raw.contains('.') || raw.contains(',')) {
      return 'Quantity must be a whole number';
    }
    final qty = int.tryParse(raw);
    if (qty == null) return 'Enter a valid whole number';
    if (qty <= 0) return 'Quantity must be greater than zero';
    if (state.side == OrderSide.sell && qty > held) {
      return 'You only hold $held shares';
    }
    return null;
  }

  Future<void> submit(Money ltp) async {
    final held = portfolio.state.quantityHeld(state.symbol);
    final qtyError = _validateQuantity(held: held);
    if (qtyError != null) {
      emit(state.copyWith(quantityError: qtyError));
      return;
    }

    final qty = state.parsedQuantity!;
    if (state.side == OrderSide.buy) {
      final value = ltp.times(qty);
      if (value > portfolio.state.balance) {
        emit(state.copyWith(
          submitError:
              'Insufficient balance. Need ${value.format()}, have ${portfolio.state.balance.format()}.',
        ));
        return;
      }
    }

    emit(state.copyWith(
      submitting: true,
      clearSubmitError: true,
      clearQuantityError: true,
    ));

    try {
      final order = await portfolio.placeOrder(
        symbol: state.symbol,
        side: state.side,
        quantity: qty,
        ltp: ltp,
      );
      emit(state.copyWith(submitting: false, placedOrder: order));
    } on OrderException catch (e) {
      emit(state.copyWith(submitting: false, submitError: e.message));
    } catch (_) {
      emit(state.copyWith(
        submitting: false,
        submitError: 'Something went wrong. Please try again.',
      ));
    }
  }
}

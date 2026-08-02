import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/price_tick.dart';
import '../../../domain/repositories/market_repository.dart';


class PricesCubit extends Cubit<PricesState> {
  PricesCubit(this._market) : super(PricesState(ticks: _market.snapshot)) {
    _subscription = _market.ticks.listen(_onTick);
  }

  final MarketRepository _market;
  StreamSubscription<PriceTick>? _subscription;

  void _onTick(PriceTick tick) {
    final next = Map<String, PriceTick>.from(state.ticks);
    next[tick.symbol] = tick;
    emit(PricesState(ticks: next, lastUpdatedSymbol: tick.symbol));
  }

  PriceTick? operator [](String symbol) => state.ticks[symbol];

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class PricesState extends Equatable {
  const PricesState({
    required this.ticks,
    this.lastUpdatedSymbol,
  });

  final Map<String, PriceTick> ticks;
  final String? lastUpdatedSymbol;

  @override
  List<Object?> get props => [ticks, lastUpdatedSymbol];
}

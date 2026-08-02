import 'package:equatable/equatable.dart';

import '../../core/money/money.dart';

class Holding extends Equatable {
  const Holding({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
  });

  final String symbol;
  final int quantity;


  final Money avgCost;

  Money get invested => avgCost.times(quantity);

  Money currentValue(Money ltp) => ltp.times(quantity);

  Money pnl(Money ltp) => currentValue(ltp) - invested;


  double pnlPercent(Money ltp) {
    if (invested.isZero) return 0;
    return (pnl(ltp).paise * 10000 / invested.paise) / 100.0;
  }

  Holding copyWith({int? quantity, Money? avgCost}) {
    return Holding(
      symbol: symbol,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity,
        'avgCostPaise': avgCost.paise,
      };

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as int,
      avgCost: Money(json['avgCostPaise'] as int),
    );
  }

  @override
  List<Object?> get props => [symbol, quantity, avgCost];
}

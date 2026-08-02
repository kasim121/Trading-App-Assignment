import 'package:equatable/equatable.dart';

import '../../core/money/money.dart';

enum OrderSide { buy, sell }

class Order extends Equatable {
  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.value,
    required this.createdAt,
  });

  final String id;
  final String symbol;
  final OrderSide side;
  final int quantity;


  final Money price;
  final Money value;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'quantity': quantity,
        'pricePaise': price.paise,
        'valuePaise': value.paise,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: OrderSide.values.byName(json['side'] as String),
      quantity: json['quantity'] as int,
      price: Money(json['pricePaise'] as int),
      value: Money(json['valuePaise'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, symbol, side, quantity, price, value, createdAt];
}

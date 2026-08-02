import 'package:equatable/equatable.dart';

import '../../core/money/money.dart';


class PriceTick extends Equatable {
  const PriceTick({
    required this.symbol,
    required this.ltp,
    required this.open,
    required this.previousLtp,
    required this.timestamp,
  });

  final String symbol;
  final Money ltp;


  final Money open;

  final Money previousLtp;

  final DateTime timestamp;

  Money get change => ltp - open;


  double get changePercent {
    if (open.isZero) return 0;
    return (change.paise * 10000 / open.paise) / 100.0;
  }


  TickDirection get tickDirection {
    if (ltp.paise > previousLtp.paise) return TickDirection.up;
    if (ltp.paise < previousLtp.paise) return TickDirection.down;
    return TickDirection.flat;
  }

  bool get isUpFromOpen => change.isPositive;

  PriceTick copyWith({
    Money? ltp,
    Money? previousLtp,
    DateTime? timestamp,
  }) {
    return PriceTick(
      symbol: symbol,
      ltp: ltp ?? this.ltp,
      open: open,
      previousLtp: previousLtp ?? this.previousLtp,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [symbol, ltp, open, previousLtp, timestamp];
}

enum TickDirection { up, down, flat }

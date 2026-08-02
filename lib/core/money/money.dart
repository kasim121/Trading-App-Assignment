import 'package:intl/intl.dart';

class Money implements Comparable<Money> {
  const Money(this.paise);


  final int paise;

  static const Money zero = Money(0);

  factory Money.fromRupees(num rupees) =>
      Money((rupees * 100).round());

  double get asRupees => paise / 100.0;

  Money operator +(Money other) => Money(paise + other.paise);

  Money operator -(Money other) => Money(paise - other.paise);

  Money operator -() => Money(-paise);

  Money times(int quantity) => Money(paise * quantity);

  bool operator >(Money other) => paise > other.paise;

  bool operator <(Money other) => paise < other.paise;

  bool operator >=(Money other) => paise >= other.paise;

  bool operator <=(Money other) => paise <= other.paise;

  bool get isNegative => paise < 0;

  bool get isZero => paise == 0;

  bool get isPositive => paise > 0;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;


  String format({bool showSign = false}) {
    final abs = Money(paise.abs());
    final formatted = _rupeeFormat.format(abs.asRupees);
    if (showSign) {
      if (paise > 0) return '+$formatted';
      if (paise < 0) return '-$formatted';
    } else if (paise < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static final _rupeeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  String toString() => format();
}

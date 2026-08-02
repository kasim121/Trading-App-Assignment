import 'package:equatable/equatable.dart';


class Watchlist extends Equatable {
  const Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
  });

  final String id;
  final String name;
  final List<String> symbols;

  Watchlist copyWith({
    String? name,
    List<String>? symbols,
  }) {
    return Watchlist(
      id: id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbols': symbols,
      };

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: (json['symbols'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  List<Object?> get props => [id, name, symbols];
}

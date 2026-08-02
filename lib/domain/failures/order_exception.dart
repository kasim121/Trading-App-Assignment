
class OrderException implements Exception {
  const OrderException(this.message);
  final String message;

  @override
  String toString() => message;
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/price_text_style.dart';
import '../../../domain/entities/order.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final color = isBuy ? AppColors.gain : AppColors.loss;


    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('Order placed')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              '${isBuy ? 'Bought' : 'Sold'} ${order.quantity} ${order.symbol}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'at ${order.price.format()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            _row('Side', isBuy ? 'Buy' : 'Sell'),
            _row('Quantity', '${order.quantity}'),
            _row('Price', order.price.format()),
            _row('Value', order.value.format()),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: priceTextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


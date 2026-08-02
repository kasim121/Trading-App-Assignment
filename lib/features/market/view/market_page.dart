import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/market_feed_config.dart';
import '../../../core/constants/stocks.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stock_price_row.dart';
import '../../../domain/repositories/market_repository.dart';
import '../../ticket/ticket_navigation.dart';

/// Feature 2 — Live Prices overview.
///
/// The list itself is static (10 symbols). Only cells that receive a tick
/// rebuild via [StockPriceRow]'s BlocSelector.
class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  bool _stressMode = false;

  void _toggleStress(bool value) {
    final feed = context.read<MarketRepository>();
    setState(() => _stressMode = value);
    feed.setTicksPerSecondPerStock(
      value
          ? MarketFeedConfig.stressTicksPerSecondPerStock
          : MarketFeedConfig.ticksPerSecondPerStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          Row(
            children: [
              Text(
                _stressMode ? 'Stress' : 'Normal',
                style: TextStyle(
                  fontSize: 12,
                  color: _stressMode
                      ? AppColors.loss
                      : AppColors.textSecondary,
                ),
              ),
              Switch.adaptive(
                value: _stressMode,
                activeThumbColor: AppColors.loss,
                onChanged: _toggleStress,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            color: AppColors.background,
            child: Text(
              _stressMode
                  ? 'Stress: ${MarketFeedConfig.stressTicksPerSecondPerStock}/s per stock'
                  : 'Live mock feed · ${MarketFeedConfig.ticksPerSecondPerStock}/s per stock',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const StockPriceHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: Stocks.symbols.length,
              itemBuilder: (context, index) {
                final symbol = Stocks.symbols[index];
                return StockPriceRow(
                  // Stable key by symbol — binding stays correct under reorder.
                  key: ValueKey(symbol),
                  symbol: symbol,
                  showDivider: index != Stocks.symbols.length - 1,
                  onTap: () => openBuySellTicket(context, symbol: symbol),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

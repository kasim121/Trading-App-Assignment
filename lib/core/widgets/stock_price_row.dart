import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/price_tick.dart';
import '../../features/market/cubit/prices_cubit.dart';
import '../theme/app_theme.dart';
import '../theme/price_text_style.dart';
import 'price_flash.dart';

class StockPriceRow extends StatelessWidget {
  const StockPriceRow({
    super.key,
    required this.symbol,
    this.onTap,
    this.showDivider = true,
  });

  final String symbol;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PricesCubit, PricesState, PriceTick?>(
      selector: (state) => state.ticks[symbol],
      builder: (context, tick) {
        if (tick == null) {
          return const SizedBox(height: 56);
        }

        final changeColor =
            tick.isUpFromOpen ? AppColors.gain : AppColors.loss;

        final resolvedChangeColor =
            tick.change.isZero ? AppColors.textSecondary : changeColor;

        return PriceFlash(
          ltpPaise: tick.ltp.paise,
          direction: tick.tickDirection,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            tick.symbol,
                            style: priceTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            tick.ltp.format(),
                            textAlign: TextAlign.right,
                            style: priceTextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            tick.change.format(showSign: true),
                            textAlign: TextAlign.right,
                            style: priceTextStyle(
                              fontSize: 13,
                              color: resolvedChangeColor,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            formatChangePercent(tick.changePercent),
                            textAlign: TextAlign.right,
                            style: priceTextStyle(
                              fontSize: 13,
                              color: resolvedChangeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showDivider)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class StockPriceHeader extends StatelessWidget {
  const StockPriceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('SYMBOL', style: style)),
          Expanded(
            flex: 3,
            child: Text('LTP', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text('CHG', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('CHG%', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/price_text_style.dart';
import '../../../core/widgets/price_flash.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/price_tick.dart';
import '../../market/cubit/prices_cubit.dart';
import '../../portfolio/cubit/portfolio_cubit.dart';
import '../cubit/ticket_cubit.dart';
import 'order_confirmation_page.dart';

Future<void> _openConfirmationAfterKeyboard(
  BuildContext context,
  Order order,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (!context.mounted) return;
  await Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => OrderConfirmationPage(order: order),
    ),
  );
}

class TicketPage extends StatelessWidget {
  const TicketPage({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketCubit, TicketState>(
      listenWhen: (p, c) => p.placedOrder != c.placedOrder && c.placedOrder != null,
      listener: (context, state) {
        final order = state.placedOrder!;
        _openConfirmationAfterKeyboard(context, order);
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text('$symbol · Order'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LiveLtpCard(symbol: symbol),
              const SizedBox(height: 16),
              _SideToggle(
                side: state.side,
                onChanged: context.read<TicketCubit>().setSide,
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  errorText: state.quantityError,
                ),
                onChanged: context.read<TicketCubit>().setQuantityText,
              ),
              const SizedBox(height: 12),
              BlocBuilder<PortfolioCubit, PortfolioState>(
                builder: (context, portfolio) {
                  return Text(
                    state.side == OrderSide.buy
                        ? 'Available: ${portfolio.balance.format()}'
                        : 'Holdings: ${portfolio.quantityHeld(symbol)} shares',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              BlocSelector<PricesCubit, PricesState, PriceTick?>(
                selector: (s) => s.ticks[symbol],
                builder: (context, tick) {
                  final qty = state.parsedQuantity ?? 0;
                  final ltp = tick?.ltp;
                  final value =
                      (ltp != null && qty > 0) ? ltp.times(qty) : null;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Order value',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          value?.format() ?? '—',
                          style: priceTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (state.submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.submitError!,
                  style: const TextStyle(color: AppColors.loss, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              BlocSelector<PricesCubit, PricesState, PriceTick?>(
                selector: (s) => s.ticks[symbol],
                builder: (context, tick) {
                  final isBuy = state.side == OrderSide.buy;
                  return FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isBuy ? AppColors.gain : AppColors.loss,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: state.submitting || tick == null
                        ? null
                        : () => context.read<TicketCubit>().submit(tick.ltp),
                    child: state.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isBuy ? 'Buy' : 'Sell'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveLtpCard extends StatelessWidget {
  const _LiveLtpCard({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PricesCubit, PricesState, PriceTick?>(
      selector: (s) => s.ticks[symbol],
      builder: (context, tick) {
        if (tick == null) {
          return const SizedBox(height: 72);
        }
        final changeColor = tick.change.isZero
            ? AppColors.textSecondary
            : (tick.isUpFromOpen ? AppColors.gain : AppColors.loss);

        return PriceFlash(
          ltpPaise: tick.ltp.paise,
          direction: tick.tickDirection,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: priceTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live LTP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tick.ltp.format(),
                      style: priceTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${tick.change.format(showSign: true)}  ${formatChangePercent(tick.changePercent)}',
                      style: priceTextStyle(fontSize: 12, color: changeColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SideToggle extends StatelessWidget {
  const _SideToggle({required this.side, required this.onChanged});

  final OrderSide side;
  final ValueChanged<OrderSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OrderSide>(
      segments: const [
        ButtonSegment(value: OrderSide.buy, label: Text('Buy')),
        ButtonSegment(value: OrderSide.sell, label: Text('Sell')),
      ],
      selected: {side},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return AppColors.surface;
          }
          return side == OrderSide.buy ? AppColors.gain : AppColors.loss;
        }),
      ),
    );
  }
}

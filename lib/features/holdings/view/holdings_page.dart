import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/price_text_style.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/price_flash.dart';
import '../../../domain/entities/holding.dart';
import '../../../domain/entities/price_tick.dart';
import '../../market/cubit/prices_cubit.dart';
import '../../portfolio/cubit/portfolio_cubit.dart';
import '../../ticket/ticket_navigation.dart';
import '../holdings_sort.dart';

class HoldingsPage extends StatefulWidget {
  const HoldingsPage({super.key});

  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> {
  HoldingsSort _sort = HoldingsSort.pnlDesc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          PopupMenuButton<HoldingsSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: HoldingsSort.pnlDesc,
                child: Text('P&L (high → low)'),
              ),
              PopupMenuItem(
                value: HoldingsSort.pnlAsc,
                child: Text('P&L (low → high)'),
              ),
              PopupMenuItem(
                value: HoldingsSort.symbolAsc,
                child: Text('Symbol (A → Z)'),
              ),
              PopupMenuItem(
                value: HoldingsSort.valueDesc,
                child: Text('Current value'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, portfolio) {
          if (portfolio.holdings.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No holdings',
              message:
                  'Place a Buy order from Watchlist or Market to build your portfolio.',
            );
          }

          return BlocBuilder<PricesCubit, PricesState>(
            buildWhen: (prev, next) {
      
              if (prev.lastUpdatedSymbol == null) return true;
              return portfolio.holdings.containsKey(next.lastUpdatedSymbol);
            },
            builder: (context, prices) {
              final rows = _sortedHoldings(portfolio.holdings, prices.ticks);
              final summary = _aggregate(rows, prices.ticks);

              return Column(
                children: [
                  _SummaryHeader(summary: summary),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'STOCK',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'LTP',
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'P&L',
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final holding = rows[index];
                        return _HoldingRow(
                          key: ValueKey(holding.symbol),
                          holding: holding,
                          tick: prices.ticks[holding.symbol],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Holding> _sortedHoldings(
    Map<String, Holding> holdings,
    Map<String, PriceTick> ticks,
  ) {
    final list = holdings.values.toList();
    int cmpMoney(Money a, Money b) => b.compareTo(a);

    list.sort((a, b) {
      final ltpA = ticks[a.symbol]?.ltp ?? Money.zero;
      final ltpB = ticks[b.symbol]?.ltp ?? Money.zero;
      switch (_sort) {
        case HoldingsSort.pnlDesc:
          return cmpMoney(a.pnl(ltpA), b.pnl(ltpB));
        case HoldingsSort.pnlAsc:
          return a.pnl(ltpA).compareTo(b.pnl(ltpB));
        case HoldingsSort.symbolAsc:
          return a.symbol.compareTo(b.symbol);
        case HoldingsSort.valueDesc:
          return cmpMoney(a.currentValue(ltpA), b.currentValue(ltpB));
      }
    });
    return list;
  }

  _Summary _aggregate(
    List<Holding> rows,
    Map<String, PriceTick> ticks,
  ) {
    var invested = Money.zero;
    var current = Money.zero;
    for (final h in rows) {
      final ltp = ticks[h.symbol]?.ltp ?? h.avgCost;
      invested += h.invested;
      current += h.currentValue(ltp);
    }
    final pnl = current - invested;
    final pct = invested.isZero ? 0.0 : (pnl.paise * 10000 / invested.paise) / 100.0;
    return _Summary(
      invested: invested,
      current: current,
      pnl: pnl,
      pnlPercent: pct,
    );
  }
}

class _Summary {
  const _Summary({
    required this.invested,
    required this.current,
    required this.pnl,
    required this.pnlPercent,
  });

  final Money invested;
  final Money current;
  final Money pnl;
  final double pnlPercent;
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final _Summary summary;

  @override
  Widget build(BuildContext context) {
    final pnlColor = summary.pnl.isNegative
        ? AppColors.loss
        : summary.pnl.isZero
            ? AppColors.textSecondary
            : AppColors.gain;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Total P&L',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              BlocBuilder<PortfolioCubit, PortfolioState>(
                builder: (context, state) {
                  return Text(
                    'Cash ${state.balance.format()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.pnl.format(showSign: true)}  (${formatChangePercent(summary.pnlPercent)})',
            style: priceTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: pnlColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Invested', summary.invested.format()),
              _metric('Current', summary.current.format()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(value, style: priceTextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    super.key,
    required this.holding,
    required this.tick,
  });

  final Holding holding;
  final PriceTick? tick;

  @override
  Widget build(BuildContext context) {
    final ltp = tick?.ltp ?? holding.avgCost;
    final pnl = holding.pnl(ltp);
    final pnlColor = pnl.isNegative
        ? AppColors.loss
        : pnl.isZero
            ? AppColors.textSecondary
            : AppColors.gain;

    final body = InkWell(
      onTap: () => openBuySellTicket(context, symbol: holding.symbol),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.symbol,
                        style: priceTextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty ${holding.quantity} · Avg ${holding.avgCost.format()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ltp.format(),
                        style: priceTextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        holding.currentValue(ltp).format(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pnl.format(showSign: true),
                        style: priceTextStyle(
                          fontWeight: FontWeight.w600,
                          color: pnlColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        formatChangePercent(holding.pnlPercent(ltp)),
                        style: priceTextStyle(fontSize: 12, color: pnlColor),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
          ],
        ),
      ),
    );

    if (tick == null) return body;

    return PriceFlash(
      ltpPaise: tick!.ltp.paise,
      direction: tick!.tickDirection,
      child: body,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order.dart';
import '../portfolio/cubit/portfolio_cubit.dart';
import '../ticket/cubit/ticket_cubit.dart';
import '../ticket/view/ticket_page.dart';

Future<void> openBuySellTicket(
  BuildContext context, {
  required String symbol,
  OrderSide side = OrderSide.buy,
}) {
  final portfolio = context.read<PortfolioCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => TicketCubit(
          portfolio: portfolio,
          symbol: symbol,
          initialSide: side,
        ),
        child: TicketPage(symbol: symbol),
      ),
    ),
  );
}

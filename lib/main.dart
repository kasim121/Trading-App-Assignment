import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'data/local/trading_local_store.dart';
import 'data/market/mock_market_feed.dart';
import 'data/repositories/market_repository_impl.dart';
import 'data/repositories/portfolio_repository_impl.dart';
import 'data/repositories/watchlist_repository_impl.dart';
import 'domain/repositories/market_repository.dart';
import 'domain/repositories/portfolio_repository.dart';
import 'domain/repositories/watchlist_repository.dart';
import 'domain/usecases/place_order.dart';
import 'features/market/cubit/prices_cubit.dart';
import 'features/portfolio/cubit/portfolio_cubit.dart';
import 'features/watchlist/bloc/watchlist_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final store = await TradingLocalStore.open();
  final marketFeed = MockMarketFeed()..start();

  // Data → Domain contracts (presentation depends only on these interfaces).
  final marketRepository = MarketRepositoryImpl(marketFeed);
  final watchlistRepository = WatchlistRepositoryImpl(store);
  final portfolioRepository = PortfolioRepositoryImpl(store);

  runApp(
    TradingApp(
      marketRepository: marketRepository,
      watchlistRepository: watchlistRepository,
      portfolioRepository: portfolioRepository,
    ),
  );
}

class TradingApp extends StatelessWidget {
  const TradingApp({
    super.key,
    required this.marketRepository,
    required this.watchlistRepository,
    required this.portfolioRepository,
  });

  final MarketRepository marketRepository;
  final WatchlistRepository watchlistRepository;
  final PortfolioRepository portfolioRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MarketRepository>.value(value: marketRepository),
        RepositoryProvider<WatchlistRepository>.value(
          value: watchlistRepository,
        ),
        RepositoryProvider<PortfolioRepository>.value(
          value: portfolioRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => PricesCubit(marketRepository)),
          BlocProvider(
            create: (_) => PortfolioCubit(
              portfolioRepository,
              placeOrderUseCase: const PlaceOrderUseCase(),
            ),
          ),
          BlocProvider(
            create: (_) =>
                WatchlistBloc(watchlistRepository)..add(const WatchlistStarted()),
          ),
        ],
        child: MaterialApp(
          title: 'Trade',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const AppShell(),
        ),
      ),
    );
  }
}

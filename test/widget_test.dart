import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trade/core/constants/stocks.dart';
import 'package:trade/core/money/money.dart';
import 'package:trade/data/local/trading_local_store.dart';
import 'package:trade/data/market/mock_market_feed.dart';
import 'package:trade/data/repositories/market_repository_impl.dart';
import 'package:trade/data/repositories/portfolio_repository_impl.dart';
import 'package:trade/data/repositories/watchlist_repository_impl.dart';
import 'package:trade/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Money arithmetic stays exact in paise', () {
    final a = Money.fromRupees(10.10);
    final b = Money.fromRupees(0.20);
    expect((a + b).paise, 1030);
    expect(Money(100).times(3).paise, 300);
  });

  testWidgets('App boots with Market symbols available', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await TradingLocalStore.open();
    final feed = MockMarketFeed()..start();

    await tester.pumpWidget(
      TradingApp(
        marketRepository: MarketRepositoryImpl(feed),
        watchlistRepository: WatchlistRepositoryImpl(store),
        portfolioRepository: PortfolioRepositoryImpl(store),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Market'));
 
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('RELIANCE'), findsWidgets);
    expect(Stocks.symbols.length, 10);


    feed.dispose();
  });
}

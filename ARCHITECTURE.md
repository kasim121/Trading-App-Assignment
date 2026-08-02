# Architecture decisions (Trade)

**For reviewers / interviewers** — why the app is structured this way, and what we deliberately skipped.

This app uses **light Clean Architecture + BLoC**: enough structure to keep trading rules testable and data swappable, without ceremony a mock-feed assignment does not need.

## Layers

```
features/ (UI + BLoC)  →  domain/ (entities, contracts, use cases)  →  data/ (impls)
```

| Folder | Allowed to know about | Must not know about |
|--------|------------------------|---------------------|
| `features/` | Domain contracts, entities | `SharedPreferences`, `MockMarketFeed` internals |
| `domain/` | Pure Dart + `Money` | Flutter widgets, prefs, timers |
| `data/` | Domain + platform/IO | Feature widgets / BLoCs |
| `core/` | Shared UI + money helpers | Feature business rules |

## Why each abstraction exists

| Abstraction | Why it exists |
|-------------|---------------|
| `MarketRepository` | UI must not import the mock feed. Later: WebSocket impl, same BLoCs. |
| `WatchlistRepository` / `PortfolioRepository` | Persistence is an implementation detail. |
| `PlaceOrderUseCase` | Buy/sell rules (margin, avg cost, sell qty) are the core domain — unit-tested without Flutter. |
| `PricesCubit` + `BlocSelector` | One emit stream; only the changed symbol’s row rebuilds under stress ticks. |

## Deliberately **not** done (and why)

| Skipped | Reason |
|---------|--------|
| Use case per watchlist CRUD | Thin pass-through to the repository — adds files, not clarity. |
| Separate DTOs vs entities | Local JSON maps 1:1 to domain models; DTOs would be noise. |
| `get_it` / `injectable` | `MultiRepositoryProvider` in `main` is enough for this app size. |
| `freezed` / `json_serializable` | Hand-written models are short and easy to explain. |
| `go_router` | Three tabs + one push route; `Navigator` is fine. |

If this grew into a real brokerage app (auth, multiple feeds, remote portfolio), we would add more use cases and DI — not before.

## Money

All cash, LTP, order value, and P&L use **integer paise** (`Money`). Formatting to `₹` is display-only. This avoids classic float bugs (`0.1 + 0.2`).

## Live prices under load

1. `MockMarketFeed` emits ticks continuously (rate configurable; Market screen has Normal / Stress).
2. `PricesCubit` holds the latest map.
3. Rows use `BlocSelector` on one symbol + `ValueKey(symbol)` so reorder never attaches the wrong stream to a row.

## Ticket → confirmation

After Buy/Sell, the ticket dismisses the keyboard, then replaces the route with a scrollable confirmation page. Order rules stay in `PlaceOrderUseCase`; navigation is presentation-only.

## Dependency injection

Wired once in `main.dart`: store → repository impls → `RepositoryProvider` + `BlocProvider`. No service locator.

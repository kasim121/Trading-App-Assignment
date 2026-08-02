import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/stocks.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/stock_price_row.dart';
import '../../../domain/entities/watchlist.dart';
import '../../ticket/ticket_navigation.dart';
import '../bloc/watchlist_bloc.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, state) {
        if (state.lists.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final active = state.active;

        return Scaffold(
          appBar: AppBar(
            title: Text(active.name),
            actions: [
              IconButton(
                tooltip: 'Manage watchlists',
                icon: const Icon(Icons.folder_outlined),
                onPressed: () => _showManageSheet(context, state),
              ),
              IconButton(
                tooltip: 'Add stock',
                icon: const Icon(Icons.add),
                onPressed: () => _showStockPicker(context, active),
              ),
            ],
          ),
          body: Column(
            children: [
              _WatchlistChips(state: state),
              if (active.symbols.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Drag to reorder · Swipe to remove · Tap to trade',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              const StockPriceHeader(),
              Expanded(
                child: active.symbols.isEmpty
                    ? EmptyState(
                        icon: Icons.playlist_add,
                        title: 'No stocks yet',
                        message:
                            'Add from the 10 available symbols to start tracking live prices.',
                        action: FilledButton.tonal(
                          onPressed: () => _showStockPicker(context, active),
                          child: const Text('Add stocks'),
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: active.symbols.length,
                        onReorder: (oldIndex, newIndex) {
                          context.read<WatchlistBloc>().add(
                                WatchlistStockReordered(
                                  oldIndex: oldIndex,
                                  newIndex: newIndex,
                                ),
                              );
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: AppColors.surfaceElevated,
                            elevation: 2,
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final symbol = active.symbols[index];
                          // Key by symbol so reorder keeps the correct live price binding.
                          return Dismissible(
                            key: ValueKey(symbol),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: AppColors.loss.withValues(alpha: 0.25),
                              child: const Icon(
                                Icons.delete_outline,
                                color: AppColors.loss,
                              ),
                            ),
                            onDismissed: (_) {
                              context
                                  .read<WatchlistBloc>()
                                  .add(WatchlistStockRemoved(symbol));
                            },
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: StockPriceRow(
                                    symbol: symbol,
                                    showDivider:
                                        index != active.symbols.length - 1,
                                    onTap: () => openBuySellTicket(
                                      context,
                                      symbol: symbol,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStockPicker(BuildContext context, Watchlist active) async {
    final bloc = context.read<WatchlistBloc>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
       
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Add stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final symbol in Stocks.symbols)
                  ListTile(
                    title: Text(symbol),
                    trailing: active.symbols.contains(symbol)
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                    enabled: !active.symbols.contains(symbol),
                    onTap: active.symbols.contains(symbol)
                        ? null
                        : () {
                            bloc.add(WatchlistStockAdded(symbol));
                            Navigator.pop(ctx);
                          },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showManageSheet(
    BuildContext context,
    WatchlistState state,
  ) async {
    final bloc = context.read<WatchlistBloc>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                children: [
                  const ListTile(
                    title: Text(
                      'Watchlists',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  for (final list in state.lists)
                    ListTile(
                      selected: list.id == state.activeId,
                      title: Text(list.name),
                      subtitle: Text('${list.symbols.length} stocks'),
                      onTap: () {
                        bloc.add(WatchlistSelected(list.id));
                        Navigator.pop(ctx);
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'rename') {
                            final name = await _promptName(
                              ctx,
                              title: 'Rename watchlist',
                              initial: list.name,
                            );
                            if (name != null) {
                              bloc.add(
                                WatchlistRenamed(id: list.id, name: name),
                              );
                            }
                          } else if (value == 'delete') {
                            if (state.lists.length <= 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Keep at least one watchlist.'),
                                ),
                              );
                              return;
                            }
                            bloc.add(WatchlistDeleted(list.id));
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.accent),
                    title: const Text('Create watchlist'),
                    onTap: () async {
                      final name = await _promptName(
                        ctx,
                        title: 'New watchlist',
                        initial: 'Watchlist ${state.lists.length + 1}',
                      );
                      if (name != null) {
                        bloc.add(WatchlistCreated(name));
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _WatchlistChips extends StatelessWidget {
  const _WatchlistChips({required this.state});

  final WatchlistState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: state.lists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final list = state.lists[index];
          final selected = list.id == state.activeId;
          return ChoiceChip(
            label: Text(list.name),
            selected: selected,
            onSelected: (_) {
              context.read<WatchlistBloc>().add(WatchlistSelected(list.id));
            },
            selectedColor: AppColors.surfaceElevated,
            labelStyle: TextStyle(
              color: selected ? AppColors.accent : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            backgroundColor: AppColors.surface,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

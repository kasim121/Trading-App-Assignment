import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/watchlist.dart';
import '../../../domain/repositories/watchlist_repository.dart';



sealed class WatchlistEvent extends Equatable {
  const WatchlistEvent();
  @override
  List<Object?> get props => [];
}

class WatchlistStarted extends WatchlistEvent {
  const WatchlistStarted();
}

class WatchlistSelected extends WatchlistEvent {
  const WatchlistSelected(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class WatchlistCreated extends WatchlistEvent {
  const WatchlistCreated(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class WatchlistRenamed extends WatchlistEvent {
  const WatchlistRenamed({required this.id, required this.name});
  final String id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}

class WatchlistDeleted extends WatchlistEvent {
  const WatchlistDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class WatchlistStockAdded extends WatchlistEvent {
  const WatchlistStockAdded(this.symbol);
  final String symbol;
  @override
  List<Object?> get props => [symbol];
}

class WatchlistStockRemoved extends WatchlistEvent {
  const WatchlistStockRemoved(this.symbol);
  final String symbol;
  @override
  List<Object?> get props => [symbol];
}

class WatchlistStockReordered extends WatchlistEvent {
  const WatchlistStockReordered({required this.oldIndex, required this.newIndex});
  final int oldIndex;
  final int newIndex;
  @override
  List<Object?> get props => [oldIndex, newIndex];
}



class WatchlistState extends Equatable {
  const WatchlistState({
    required this.lists,
    required this.activeId,
  });

  final List<Watchlist> lists;
  final String activeId;

  Watchlist get active {
    return lists.firstWhere(
      (w) => w.id == activeId,
      orElse: () => lists.first,
    );
  }

  @override
  List<Object?> get props => [lists, activeId];
}



class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this._repository)
      : super(
          const WatchlistState(
            lists: [],
            activeId: '',
          ),
        ) {
    on<WatchlistStarted>(_onStarted);
    on<WatchlistSelected>(_onSelected);
    on<WatchlistCreated>(_onCreated);
    on<WatchlistRenamed>(_onRenamed);
    on<WatchlistDeleted>(_onDeleted);
    on<WatchlistStockAdded>(_onStockAdded);
    on<WatchlistStockRemoved>(_onStockRemoved);
    on<WatchlistStockReordered>(_onStockReordered);
  }

  final WatchlistRepository _repository;

  Future<void> _persist(WatchlistState next) async {
    await _repository.saveWatchlists(next.lists);
    await _repository.saveActiveWatchlistId(next.activeId);
  }

  Future<void> _onStarted(
    WatchlistStarted event,
    Emitter<WatchlistState> emit,
  ) async {
    final lists = _repository.loadWatchlists();
    final savedId = _repository.loadActiveWatchlistId();
    final activeId = lists.any((w) => w.id == savedId)
        ? savedId!
        : lists.first.id;
    emit(WatchlistState(lists: lists, activeId: activeId));
  }

  Future<void> _onSelected(
    WatchlistSelected event,
    Emitter<WatchlistState> emit,
  ) async {
    final next = WatchlistState(lists: state.lists, activeId: event.id);
    emit(next);
    await _persist(next);
  }

  Future<void> _onCreated(
    WatchlistCreated event,
    Emitter<WatchlistState> emit,
  ) async {
    final name = event.name.trim().isEmpty ? 'Watchlist' : event.name.trim();
    final created = Watchlist(
      id: _repository.newId(),
      name: name,
      symbols: const [],
    );
    final lists = [...state.lists, created];
    final next = WatchlistState(lists: lists, activeId: created.id);
    emit(next);
    await _persist(next);
  }

  Future<void> _onRenamed(
    WatchlistRenamed event,
    Emitter<WatchlistState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;
    final lists = state.lists
        .map((w) => w.id == event.id ? w.copyWith(name: name) : w)
        .toList();
    final next = WatchlistState(lists: lists, activeId: state.activeId);
    emit(next);
    await _persist(next);
  }

  Future<void> _onDeleted(
    WatchlistDeleted event,
    Emitter<WatchlistState> emit,
  ) async {
    if (state.lists.length <= 1) return;
    final lists = state.lists.where((w) => w.id != event.id).toList();
    final activeId =
        state.activeId == event.id ? lists.first.id : state.activeId;
    final next = WatchlistState(lists: lists, activeId: activeId);
    emit(next);
    await _persist(next);
  }

  Future<void> _onStockAdded(
    WatchlistStockAdded event,
    Emitter<WatchlistState> emit,
  ) async {
    final active = state.active;
    if (active.symbols.contains(event.symbol)) return;
    final updated = active.copyWith(
      symbols: [...active.symbols, event.symbol],
    );
    final lists =
        state.lists.map((w) => w.id == active.id ? updated : w).toList();
    final next = WatchlistState(lists: lists, activeId: state.activeId);
    emit(next);
    await _persist(next);
  }

  Future<void> _onStockRemoved(
    WatchlistStockRemoved event,
    Emitter<WatchlistState> emit,
  ) async {
    final active = state.active;
    final updated = active.copyWith(
      symbols: active.symbols.where((s) => s != event.symbol).toList(),
    );
    final lists =
        state.lists.map((w) => w.id == active.id ? updated : w).toList();
    final next = WatchlistState(lists: lists, activeId: state.activeId);
    emit(next);
    await _persist(next);
  }

  Future<void> _onStockReordered(
    WatchlistStockReordered event,
    Emitter<WatchlistState> emit,
  ) async {
    final active = state.active;
    final symbols = List<String>.from(active.symbols);
  
    var newIndex = event.newIndex;
    final oldIndex = event.oldIndex;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 ||
        oldIndex >= symbols.length ||
        newIndex < 0 ||
        newIndex >= symbols.length) {
      return;
    }
    final item = symbols.removeAt(oldIndex);
    symbols.insert(newIndex, item);
    final updated = active.copyWith(symbols: symbols);
    final lists =
        state.lists.map((w) => w.id == active.id ? updated : w).toList();
    final next = WatchlistState(lists: lists, activeId: state.activeId);
    emit(next);
    await _persist(next);
  }
}

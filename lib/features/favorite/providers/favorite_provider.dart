import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

import '../../../core/constants/api_constants.dart';

import '../../rooms/models/room_model.dart';

class FavoriteState {
  final List<RoomListItem> favorites;

  final bool isLoading;

  final String? error;

  FavoriteState({
    this.favorites = const [],

    this.isLoading = false,

    this.error,
  });

  FavoriteState copyWith({
    List<RoomListItem>? favorites,

    bool? isLoading,

    String? error,
  }) {
    return FavoriteState(
      favorites: favorites ?? this.favorites,

      isLoading: isLoading ?? this.isLoading,

      error: error,
    );
  }
}

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  final Ref _ref;

  FavoriteNotifier(this._ref) : super(FavoriteState()) {
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = _ref.read(dioProvider);

      final response = await dio.get(ApiConstants.favorites);

      final data = response.data;

      final dynamic payload = data is Map
          ? data['data'] ?? data['items'] ?? data
          : data;

      final List<dynamic> items = _extractItems(payload);

      final rooms = items
          .map(
            (e) => RoomListItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      state = state.copyWith(isLoading: false, favorites: rooms);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> toggleFavorite(String roomId) async {
    final dio = _ref.read(dioProvider);
    final isFav = state.favorites.any((r) => r.roomId == roomId);

    try {
      if (isFav) {
        // BE: DELETE /api/favorites/{roomId}
        await dio.delete('${ApiConstants.favorites}/$roomId');
        state = state.copyWith(
          favorites: state.favorites.where((r) => r.roomId != roomId).toList(),
        );
      } else {
        // BE: POST /api/favorites  body: { roomId: int }
        final roomIdInt = int.tryParse(roomId) ?? 0;
        await dio.post(ApiConstants.favorites, data: {'roomId': roomIdInt});
        await fetchFavorites();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> removeFavorite(String roomId) async {
    try {
      final dio = _ref.read(dioProvider);

      await dio.delete('${ApiConstants.favorites}/$roomId');

      state = state.copyWith(
        favorites: state.favorites.where((r) => r.roomId != roomId).toList(),
      );
    } catch (_) {}
  }

  bool isFavorite(String roomId) {
    return state.favorites.any((r) => r.roomId == roomId);
  }

  List<dynamic> _extractItems(dynamic value) {
    if (value is List) return value;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final nested = map['items'] ?? map['data'] ?? map['results'];

      if (nested is List) return nested;

      if (nested is Map) return _extractItems(nested);
    }

    return const [];
  }
}

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, FavoriteState>(
  (ref) {
    return FavoriteNotifier(ref);
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../rooms/models/room_model.dart';
import '../../rooms/providers/room_provider.dart';

class FavoriteState {
  final List<RoomModel> favorites;
  final bool isLoading;
  final String? error;

  FavoriteState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoriteState copyWith({
    List<RoomModel>? favorites,
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
  final Ref ref;
  final Dio _dio;

  FavoriteNotifier(this.ref)
      : _dio = ref.read(dioProvider),
        super(FavoriteState()) {
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Gọi API thực tế: final response = await _dio.get('/api/favorites');
      // final List<dynamic> data = response.data;
      // final rooms = data.map((e) => RoomModel.fromJson(e)).toList();

      // Giả lập dữ liệu có sẵn 2 phòng yêu thích
      await Future.delayed(const Duration(milliseconds: 800));
      
      final mockFavorites = [
        RoomModel(
          id: '0',
          name: 'Homestay Deluxe #0',
          description: 'Không gian sang trọng tại trung tâm.',
          location: 'Đà Lạt, Lâm Đồng',
          price: 500000.0,
          rating: 4.5,
          reviews: 120,
          imageUrl: 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=500&q=80',
          images: ['https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=500&q=80'],
          amenities: ['Wifi', 'Bếp', 'Điều hòa'],
        ),
        RoomModel(
          id: '1',
          name: 'Homestay Deluxe #1',
          description: 'View thung lũng cực đẹp.',
          location: 'Đà Lạt, Lâm Đồng',
          price: 600000.0,
          rating: 4.8,
          reviews: 85,
          imageUrl: 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&q=80',
          images: ['https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&q=80'],
          amenities: ['Wifi', 'Bếp', 'Bể bơi'],
        ),
      ];
      
      state = state.copyWith(isLoading: false, favorites: mockFavorites);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> toggleFavorite(RoomModel room) async {
    final isFav = isFavorite(room.id);
    try {
      if (isFav) {
        // DELETE /api/favorites/:id
        // await _dio.delete('/api/favorites/${room.id}');
        state = state.copyWith(
          favorites: state.favorites.where((r) => r.id != room.id).toList(),
        );
      } else {
        // POST /api/favorites { roomId }
        // await _dio.post('/api/favorites', data: {'roomId': room.id});
        state = state.copyWith(
          favorites: [...state.favorites, room],
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  bool isFavorite(String roomId) {
    return state.favorites.any((r) => r.id == roomId);
  }

  Future<void> removeFromFavorite(String roomId) async {
    try {
      // await _dio.delete('/api/favorites/$roomId');
      state = state.copyWith(
        favorites: state.favorites.where((r) => r.id != roomId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  return FavoriteNotifier(ref);
});

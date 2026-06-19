import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import 'room_list_provider.dart';
import '../../review/models/review_model.dart';

// RE-EXPOSE for compatibility
export 'room_list_provider.dart' show roomFilterProvider;

// --- Provider cho Chi tiết phòng ---
final roomDetailProvider = FutureProvider.autoDispose.family<RoomDetail, String>((
  ref,
  id,
) async {
  final roomService = ref.watch(roomServiceProvider);
  return await roomService.getRoomDetail(id);
});

final roomReviewsProvider = FutureProvider.autoDispose.family<List<ReviewModel>, String>((
  ref,
  roomId,
) async {
  final roomService = ref.watch(roomServiceProvider);
  return await roomService.getRoomReviews(roomId);
});

// --- Restore RoomNotifier for other screens ---
class RoomState {
  final List<RoomDetail> rooms;
  final bool isLoading;
  final bool isLoadMore;
  final int page;
  final bool hasMore;
  final String? error;

  RoomState({
    this.rooms = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  RoomState copyWith({
    List<RoomDetail>? rooms,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasMore,
    String? error,
  }) {
    return RoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final RoomService _roomService;
  final Ref _ref;

  RoomNotifier(this._roomService, this._ref) : super(RoomState()) {
    fetchRooms();
  }

  Future<void> fetchRooms({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        isLoading: true,
        page: 1,
        hasMore: true,
        rooms: [],
      );
    } else {
      if (!state.hasMore || state.isLoading || state.isLoadMore) return;
      state = state.rooms.isEmpty
          ? state.copyWith(isLoading: true)
          : state.copyWith(isLoadMore: true);
    }

    try {
      final filter = _ref.read(roomFilterProvider);
      final data = await _roomService.getRooms(
        searchTerm: filter.searchTerm,
        city: filter.city,
        roomTypeId: filter.roomTypeId,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        pageNumber: isRefresh ? 1 : state.page,
      );

      final List<RoomDetail> newRooms = data.items.map((e) {
        return RoomDetail.fromJson({
          'roomId': e.roomId,
          'name': e.name,
          'city': e.city,
          'description': '',
          'address': '',
          'pricePerNight': e.pricePerNight,
          'thumbnailUrl': e.thumbnailUrl,
          'ratingAvg': e.rating,
          'reviewCount': e.reviewCount,
          'images': [],
          'amenities': [],
          'host': {},
        });
      }).toList();

      final totalPages = data.totalPages;
      final currentPage = data.pageNumber;

      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        rooms: isRefresh ? newRooms : [...state.rooms, ...newRooms],
        page: currentPage + 1,
        hasMore: currentPage < totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async => await fetchRooms(isRefresh: true);
}

final roomNotifierProvider = StateNotifierProvider<RoomNotifier, RoomState>((
  ref,
) {
  final roomService = ref.watch(roomServiceProvider);
  return RoomNotifier(roomService, ref);
});

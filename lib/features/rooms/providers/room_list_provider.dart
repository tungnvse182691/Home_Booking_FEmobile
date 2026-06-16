import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

final roomServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return RoomService(dio);
});

class RoomListFilter {
  final String searchQuery;
  final String city;
  final String roomTypeId;
  final List<String> selectedAmenities;
  final double minPrice;
  final double maxPrice;

  RoomListFilter({
    this.searchQuery = '',
    this.city = '',
    this.roomTypeId = '',
    this.selectedAmenities = const [],
    this.minPrice = 0,
    this.maxPrice = 10000000,
  });

  // Alias for API
  String get searchTerm => searchQuery;

  RoomListFilter copyWith({
    String? searchQuery,
    String? city,
    String? roomTypeId,
    List<String>? selectedAmenities,
    double? minPrice,
    double? maxPrice,
    String? searchTerm, // Handle both
  }) {
    return RoomListFilter(
      searchQuery: searchQuery ?? searchTerm ?? this.searchQuery,
      city: city ?? this.city,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

final roomFilterProvider = StateProvider<RoomListFilter>(
  (ref) => RoomListFilter(),
);

class RoomListState {
  final List<RoomListItem> items;
  final bool isLoading;
  final bool isLoadMore;
  final int pageNumber;
  final bool hasMore;
  final String? error;

  RoomListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.pageNumber = 1,
    this.hasMore = true,
    this.error,
  });

  RoomListState copyWith({
    List<RoomListItem>? items,
    bool? isLoading,
    bool? isLoadMore,
    int? pageNumber,
    bool? hasMore,
    String? error,
  }) {
    return RoomListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      pageNumber: pageNumber ?? this.pageNumber,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class RoomListNotifier extends StateNotifier<RoomListState> {
  final RoomService _roomService;
  RoomListFilter _filters = RoomListFilter();

  RoomListFilter get filters => _filters;

  RoomListNotifier(this._roomService) : super(RoomListState()) {
    Future.microtask(() => fetchRooms());
  }

  Future<void> applyFilters(RoomListFilter filters) async {
    _filters = filters;
    await fetchRooms(isRefresh: true);
  }

  Future<void> fetchRooms({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(
        isLoading: true,
        pageNumber: 1,
        hasMore: true,
        items: [],
      );
    } else {
      if (!state.hasMore || state.isLoading || state.isLoadMore) return;
      state = state.items.isEmpty
          ? state.copyWith(isLoading: true)
          : state.copyWith(isLoadMore: true);
    }

    try {
      final data = await _roomService.getRooms(
        searchTerm: _filters.searchQuery,
        city: _filters.city,
        roomTypeId: _filters.roomTypeId,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        amenityIds: _filters.selectedAmenities,
        pageNumber: isRefresh ? 1 : state.pageNumber,
      );

      final newItems = data.items;
      final currentPage = data.pageNumber;
      final totalPages = data.totalPages;

      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        items: isRefresh ? newItems : [...state.items, ...newItems],
        pageNumber: currentPage + 1,
        hasMore: currentPage < totalPages,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await fetchRooms(isRefresh: true);
  }

  Future<void> loadMore() async {
    await fetchRooms();
  }
}

final roomListProvider = StateNotifierProvider<RoomListNotifier, RoomListState>(
  (ref) {
    final roomService = ref.watch(roomServiceProvider);
    return RoomListNotifier(roomService);
  },
);

final roomTypesProvider = FutureProvider<List<RoomType>>((ref) {
  return ref.watch(roomServiceProvider).getRoomTypes();
});

final amenitiesProvider = FutureProvider<List<Amenity>>((ref) {
  return ref.watch(roomServiceProvider).getAmenities();
});

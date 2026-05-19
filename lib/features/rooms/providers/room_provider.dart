import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';

// --- Providers cho Filter ---

class RoomFilter {
  final double minPrice;
  final double maxPrice;
  final List<String> selectedAmenities;
  final String searchQuery;

  RoomFilter({
    this.minPrice = 0,
    this.maxPrice = 5000000,
    this.selectedAmenities = const [],
    this.searchQuery = '',
  });

  RoomFilter copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? selectedAmenities,
    String? searchQuery,
  }) {
    return RoomFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final roomFilterProvider = StateProvider<RoomFilter>((ref) => RoomFilter());

// --- Provider cho Dio ---
final dioProvider = Provider((ref) => Dio(BaseOptions(baseUrl: 'https://api-mock-homestay.com'))); // Thay baseUrl thực tế

// --- Provider cho Pagination & Data ---

class RoomState {
  final List<RoomModel> rooms;
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
    List<RoomModel>? rooms,
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
  final Ref ref;
  Timer? _debounceTimer;

  RoomNotifier(this.ref) : super(RoomState()) {
    // Listen filter changes with debounce
    ref.listen(roomFilterProvider, (previous, next) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        refresh();
      });
    });
    fetchRooms();
  }

  Future<void> fetchRooms({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, page: 1, hasMore: true, rooms: []);
    } else {
      if (!state.hasMore || state.isLoadMore || state.isLoading) return;
      if (state.rooms.isNotEmpty) {
        state = state.copyWith(isLoadMore: true);
      } else {
        state = state.copyWith(isLoading: true);
      }
    }

    try {
      // Giả lập trễ mạng 1 giây
      await Future.delayed(const Duration(seconds: 1));
      
      // final dio = ref.read(dioProvider);
      // final filters = ref.read(roomFilterProvider);
      // final response = await dio.get('/api/rooms', ...);

      final List data = _getMockRooms(state.page); // Lấy dữ liệu giả lập
      
      final newRooms = data.map((e) => RoomModel.fromJson(e)).toList();

      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        rooms: [...state.rooms, ...newRooms],
        page: state.page + 1,
        hasMore: newRooms.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadMore: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await fetchRooms(isRefresh: true);
  }

  // Helper mock data
  List<Map<String, dynamic>> _getMockRooms(int page) {
    if (page > 3) return []; // Giới hạn 3 trang
    final List<String> roomImages = [
      'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=500&q=80',
      'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&q=80',
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=500&q=80',
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=500&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=500&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=500&q=80',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=500&q=80',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=500&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=500&q=80',
      'https://images.unsplash.com/photo-1416331108676-a22ccb276e35?w=500&q=80',
    ];

    return List.generate(10, (index) {
      int id = (page - 1) * 10 + index;
      return {
        'id': id,
        'name': 'Homestay Deluxe #$id',
        'description': 'Một không gian tuyệt vời cho gia đình bạn.',
        'location': 'Đà Lạt, Lâm Đồng',
        'price': 500000.0 + (id * 100000),
        'rating': 4.5,
        'reviews': 120,
        'imageUrl': roomImages[id % roomImages.length],
        'amenities': ['Wifi', 'Bếp', 'Điều hòa'],
      };
    });
  }
}

final roomNotifierProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(ref);
});

// --- Provider cho Chi tiết phòng ---
final roomDetailProvider = FutureProvider.family<RoomModel, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  
  try {
    // final response = await dio.get('/api/rooms/$id');
    // return RoomModel.fromJson(response.data);
    
    // Giả lập dữ liệu cho demo
    await Future.delayed(const Duration(seconds: 1));
    return RoomModel(
      id: id,
      name: 'StayEase Luxury Homestay #$id',
      description: 'Căn hộ rộng rãi, đầy đủ tiện nghi với tầm nhìn hướng biển tuyệt đẹp. Không gian được thiết kế theo phong cách tối giản, hiện đại mang lại cảm giác thư thái cho du khách. Phù hợp cho gia đình hoặc nhóm bạn đi du lịch nghỉ dưỡng.',
      location: 'Quận 1, TP. Hồ Chí Minh',
      price: 1200000,
      rating: 4.9,
      reviews: 85,
      imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
      images: [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&q=80',
      ],
      amenities: ['Wifi', 'Bếp', 'Bể bơi', 'Điều hòa', 'Máy giặt', 'Tivi'],
      blockedDates: [
        DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      ],
      host: HostModel(
        name: 'Nguyễn Văn A',
        avatar: 'https://i.pravatar.cc/150?u=$id',
        rating: 4.8,
      ),
      lat: 10.7769,
      lng: 106.7009,
    );
  } catch (e) {
    throw Exception('Không thể tải chi tiết phòng');
  }
});

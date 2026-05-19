import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rooms/models/room_model.dart';
import '../../rooms/providers/room_provider.dart';

class MapState {
  final List<RoomModel> rooms;
  final bool isLoading;
  final RoomModel? selectedRoom;

  MapState({
    this.rooms = const [],
    this.isLoading = false,
    this.selectedRoom,
  });

  MapState copyWith({
    List<RoomModel>? rooms,
    bool? isLoading,
    RoomModel? selectedRoom,
  }) {
    return MapState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      selectedRoom: selectedRoom ?? this.selectedRoom,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final Ref ref;

  MapNotifier(this.ref) : super(MapState()) {
    fetchMapRooms();
  }

  Future<void> fetchMapRooms() async {
    state = state.copyWith(isLoading: true);
    try {
      // Giả lập gọi API lấy danh sách phòng cho bản đồ
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data các phòng quanh khu vực trung tâm HCM
      final mockRooms = [
        RoomModel(
          id: 'm1',
          name: 'Phòng Studio Trung tâm Quận 1',
          description: 'Vị trí đắc địa, gần chợ Bến Thành.',
          location: 'Quận 1, TP. HCM',
          price: 950000,
          rating: 4.7,
          reviews: 120,
          imageUrl: 'https://picsum.photos/seed/m1/400/300',
          images: ['https://picsum.photos/seed/m1/400/300'],
          amenities: ['Wifi', 'Điều hòa'],
          lat: 10.7769,
          lng: 106.7009,
        ),
        RoomModel(
          id: 'm2',
          name: 'Căn hộ River View',
          description: 'View sông Sài Gòn cực đẹp.',
          location: 'Quận 4, TP. HCM',
          price: 1500000,
          rating: 4.9,
          reviews: 45,
          imageUrl: 'https://picsum.photos/seed/m2/400/300',
          images: ['https://picsum.photos/seed/m2/400/300'],
          amenities: ['Bể bơi', 'Wifi'],
          lat: 10.7620,
          lng: 106.7060,
        ),
        RoomModel(
          id: 'm3',
          name: 'Homestay Vintage',
          description: 'Phong cách cổ điển, ấm cúng.',
          location: 'Quận 3, TP. HCM',
          price: 700000,
          rating: 4.5,
          reviews: 80,
          imageUrl: 'https://picsum.photos/seed/m3/400/300',
          images: ['https://picsum.photos/seed/m3/400/300'],
          amenities: ['Bếp', 'Wifi'],
          lat: 10.7820,
          lng: 106.6850,
        ),
      ];

      state = state.copyWith(isLoading: false, rooms: mockRooms);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectRoom(RoomModel? room) {
    state = state.copyWith(selectedRoom: room);
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref);
});

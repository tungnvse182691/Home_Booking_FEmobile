import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rooms/models/room_model.dart';
import '../../../core/utils/response_utils.dart';
import '../../../core/network/dio_client.dart';

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
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/rooms');
      
      if (response.data['success'] == true) {
        final itemsData = extractItems(response.data['data']);
        final rooms = itemsData.map((json) => RoomModel.fromJson(json)).toList();
        state = state.copyWith(isLoading: false, rooms: rooms);
      } else {
        state = state.copyWith(isLoading: false);
      }
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

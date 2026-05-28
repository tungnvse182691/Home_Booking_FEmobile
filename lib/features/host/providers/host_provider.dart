import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/host_model.dart';
import '../services/host_service.dart';

final hostServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return HostService(dio);
});

// ─── Dashboard ───────────────────────────────────────────────────────────────
final hostDashboardProvider = FutureProvider<HostDashboardData>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) throw Exception('Chưa đăng nhập');
  return ref.read(hostServiceProvider).getDashboard();
});

// ─── Rooms ────────────────────────────────────────────────────────────────────
// Dung FutureProvider don gian, tranh dung StateNotifier + ref.listen trong
// constructor (gay crash / OOM tren emulator).
final hostRoomsProvider =
    StateNotifierProvider<HostRoomsNotifier, AsyncValue<List<HostRoomItem>>>(
  (ref) => HostRoomsNotifier(ref),
);

class HostRoomsNotifier extends StateNotifier<AsyncValue<List<HostRoomItem>>> {
  final Ref _ref;

  HostRoomsNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Goi fetchRooms sau khi provider duoc mount (post-frame safe)
    Future.microtask(fetchRooms);
  }

  Future<void> fetchRooms() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authStateProvider);
      if (user == null) {
        if (mounted) state = const AsyncValue.data([]);
        return;
      }
      final service = _ref.read(hostServiceProvider);
      final rooms = await service.getRooms(user.userId);
      if (mounted) state = AsyncValue.data(rooms);
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRoom(String id) async {
    final service = _ref.read(hostServiceProvider);
    await service.deleteRoom(id);
    await fetchRooms();
  }

  Future<void> updateRoom(String id, Map<String, dynamic> roomData) async {
    final service = _ref.read(hostServiceProvider);
    await service.updateRoom(id, roomData);
    await fetchRooms();
  }
}

// ─── Revenue ─────────────────────────────────────────────────────────────────
final hostRevenueProvider = FutureProvider<List<RevenueReportItem>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return ref.read(hostServiceProvider).getRevenueReport();
});

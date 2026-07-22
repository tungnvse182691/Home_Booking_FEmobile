import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/host_model.dart';
import '../services/host_service.dart';

/// Provider khởi tạo và cung cấp instance HostService
final hostServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return HostService(dio);
});

// ─── Dashboard Host ────────────────────────────────────────────────────────
/// FutureProvider tự động gọi API lấy dữ liệu chỉ số Dashboard cho Host
final hostDashboardProvider = FutureProvider<HostDashboardData>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) throw Exception('Chưa đăng nhập');
  return ref.read(hostServiceProvider).getDashboard();
});

// ─── Quản lý Phòng của Host (Rooms) ───────────────────────────────────────
/// StateNotifierProvider quản lý trạng thái danh sách phòng Homestay thuộc quản lý của Host
final hostRoomsProvider =
    StateNotifierProvider<HostRoomsNotifier, AsyncValue<List<HostRoomItem>>>(
  (ref) => HostRoomsNotifier(ref),
);

/// Class Notifier quản lý danh sách phòng của Host, hỗ trợ tải lại, cập nhật và xóa phòng
class HostRoomsNotifier extends StateNotifier<AsyncValue<List<HostRoomItem>>> {
  final Ref _ref;

  HostRoomsNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Gọi fetchRooms sau khi provider được khởi tạo (post-frame safe)
    Future.microtask(fetchRooms);
  }

  /// Tải danh sách phòng của Host hiện tại từ Backend API
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

  /// Xóa phòng Homestay theo ID và tự động làm mới danh sách
  Future<void> deleteRoom(String id) async {
    final service = _ref.read(hostServiceProvider);
    await service.deleteRoom(id);
    await fetchRooms();
  }

  /// Cập nhật thông tin phòng Homestay theo ID và tự động làm mới danh sách
  Future<void> updateRoom(String id, Map<String, dynamic> roomData) async {
    final service = _ref.read(hostServiceProvider);
    await service.updateRoom(id, roomData);
    await fetchRooms();
  }
}

// ─── Báo cáo Doanh thu Host (Revenue) ─────────────────────────────────────
/// FutureProvider lấy báo cáo thống kê doanh thu theo thời gian của Host
final hostRevenueProvider = FutureProvider<List<RevenueReportItem>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return ref.read(hostServiceProvider).getRevenueReport();
});


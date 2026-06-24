import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';
import '../../host/models/host_model.dart';
import '../../rooms/models/room_model.dart';
import '../../rooms/services/room_service.dart';
import '../../rooms/providers/room_list_provider.dart';
import '../../host/services/host_service.dart';
import '../../host/providers/host_provider.dart';

final adminServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AdminService(dio);
});

// ── Dashboard ─────────────────────────────────────────────────────────────
final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  return ref.watch(adminServiceProvider).getDashboard();
});

// ── Users ─────────────────────────────────────────────────────────────────
/// Filter state cho users
class AdminUsersFilter {
  final String search;
  final String role; // '' = all
  final String status; // '' = all

  const AdminUsersFilter({this.search = '', this.role = '', this.status = ''});

  AdminUsersFilter copyWith({String? search, String? role, String? status}) =>
      AdminUsersFilter(
        search: search ?? this.search,
        role: role ?? this.role,
        status: status ?? this.status,
      );
}

final adminUsersFilterProvider = StateProvider<AdminUsersFilter>(
  (_) => const AdminUsersFilter(),
);

final adminUsersProvider =
    StateNotifierProvider.autoDispose<AdminUsersNotifier, AsyncValue<List<AdminUserItem>>>((
      ref,
    ) {
      return AdminUsersNotifier(ref.watch(adminServiceProvider));
    });

class AdminUsersNotifier
    extends StateNotifier<AsyncValue<List<AdminUserItem>>> {
  final AdminService _service;

  // Lưu lại filter cuối cùng để re-apply sau khi update
  String? _lastSearch;
  String? _lastRole;
  String? _lastStatus;

  AdminUsersNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchUsers();
  }

  Future<void> fetchUsers({
    String? search,
    String? role,
    String? status,
  }) async {
    // Lưu lại filter hiện tại
    _lastSearch = search;
    _lastRole = role;
    _lastStatus = status;

    state = const AsyncValue.loading();
    try {
      final users = await _service.getUsers(
        search: search,
        role: role,
        status: status,
      );
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    await _service.updateUserStatus(id, status);
    // Re-fetch với filter cũ để danh sách không bị reset filter
    await fetchUsers(
      search: _lastSearch,
      role: _lastRole,
      status: _lastStatus,
    );
  }

  Future<void> updateRole(String id, String role) async {
    await _service.updateUserRole(id, role);
    // Re-fetch với filter cũ để danh sách không bị reset filter
    await fetchUsers(
      search: _lastSearch,
      role: _lastRole,
      status: _lastStatus,
    );
  }
}

// ── Payments ──────────────────────────────────────────────────────────────
/// Filter state cho payments
class AdminPaymentsFilter {
  final String status; // '' = all
  final String method; // '' = all

  const AdminPaymentsFilter({this.status = '', this.method = ''});

  AdminPaymentsFilter copyWith({String? status, String? method}) =>
      AdminPaymentsFilter(
        status: status ?? this.status,
        method: method ?? this.method,
      );
}

final adminPaymentsFilterProvider = StateProvider<AdminPaymentsFilter>(
  (_) => const AdminPaymentsFilter(),
);

final adminPaymentsProvider =
    StateNotifierProvider.autoDispose<
      AdminPaymentsNotifier,
      AsyncValue<List<AdminPaymentItem>>
    >((ref) {
      return AdminPaymentsNotifier(ref.watch(adminServiceProvider));
    });

class AdminPaymentsNotifier
    extends StateNotifier<AsyncValue<List<AdminPaymentItem>>> {
  final AdminService _service;

  AdminPaymentsNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchPayments();
  }

  Future<void> fetchPayments({String? status, String? method}) async {
    state = const AsyncValue.loading();
    try {
      final payments = await _service.getPayments(
        status: status,
        method: method,
      );
      state = AsyncValue.data(payments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// ── Revenue ───────────────────────────────────────────────────────────────
final adminRevenueProvider = FutureProvider<List<RevenueReportItem>>((
  ref,
) async {
  return ref.watch(adminServiceProvider).getRevenueReport();
});

// ── Rooms ─────────────────────────────────────────────────────────────────
/// Admin dùng public GET /api/rooms (không có admin-specific endpoint ở BE).
/// Xóa phòng dùng DELETE /api/host/rooms/{id} (BE cho phép ADMIN gọi endpoint này).
final adminRoomsProvider =
    StateNotifierProvider.autoDispose<AdminRoomsNotifier, AsyncValue<List<RoomListItem>>>((
      ref,
    ) {
      final roomService = ref.watch(roomServiceProvider);
      final hostService = ref.watch(hostServiceProvider);
      return AdminRoomsNotifier(roomService, hostService);
    });

class AdminRoomsNotifier extends StateNotifier<AsyncValue<List<RoomListItem>>> {
  final RoomService _roomService;
  final HostService _hostService;
  String? _lastSearchTerm;

  AdminRoomsNotifier(this._roomService, this._hostService)
    : super(const AsyncValue.loading()) {
    fetchRooms();
  }

  Future<void> fetchRooms({String? searchTerm}) async {
    _lastSearchTerm = searchTerm;
    state = const AsyncValue.loading();
    try {
      final result = await _roomService.getRooms(
        searchTerm: searchTerm,
        pageNumber: 1,
        pageSize: 100,
      );
      state = AsyncValue.data(result.items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRoom(String id) async {
    await _hostService.deleteRoom(id);
    await fetchRooms(searchTerm: _lastSearchTerm);
  }
}

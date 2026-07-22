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

/// Provider khởi tạo phiên AdminService kết nối với Dio HTTP Client
final adminServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AdminService(dio);
});

// ── 1. Thống kê Dashboard ───────────────────────────────────────────────────
/// Provider bất đồng bộ (FutureProvider) tự động tải dữ liệu Thống kê Dashboard cho Admin
final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  return ref.watch(adminServiceProvider).getDashboard();
});

// ── 2. Quản lý Người dùng (Users) ───────────────────────────────────────────
/// Class lưu trữ bộ lọc (Filter) hiện tại của danh sách Người dùng
class AdminUsersFilter {
  final String search; // Từ khóa tìm kiếm tên/email/sđt
  final String role;   // Vai trò cần lọc: '' (Tất cả), CUSTOMER, HOST, ADMIN
  final String status; // Trạng thái cần lọc: '' (Tất cả), ACTIVE, INACTIVE

  const AdminUsersFilter({this.search = '', this.role = '', this.status = ''});

  /// Sao chép bộ lọc mới khi có thay đổi từ UI
  AdminUsersFilter copyWith({String? search, String? role, String? status}) =>
      AdminUsersFilter(
        search: search ?? this.search,
        role: role ?? this.role,
        status: status ?? this.status,
      );
}

/// StateProvider lưu giữ trạng thái bộ lọc người dùng
final adminUsersFilterProvider = StateProvider<AdminUsersFilter>(
  (_) => const AdminUsersFilter(),
);

/// Provider quản lý State danh sách người dùng với khả năng tự giải phóng bộ nhớ (autoDispose)
final adminUsersProvider =
    StateNotifierProvider.autoDispose<AdminUsersNotifier, AsyncValue<List<AdminUserItem>>>((
      ref,
    ) {
      return AdminUsersNotifier(ref.watch(adminServiceProvider));
    });

/// Notifier quản lý logic tải, lọc, đổi vai trò và khóa tài khoản người dùng
class AdminUsersNotifier
    extends StateNotifier<AsyncValue<List<AdminUserItem>>> {
  final AdminService _service;

  // Giữ lại tham số bộ lọc cuối cùng để tự động nạp lại đúng danh sách sau khi Update
  String? _lastSearch;
  String? _lastRole;
  String? _lastStatus;

  AdminUsersNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchUsers(); // Tự động nạp danh sách người dùng khi màn hình mở ra
  }

  /// Lấy danh sách người dùng từ API theo từ khóa search, role và status
  Future<void> fetchUsers({
    String? search,
    String? role,
    String? status,
  }) async {
    // Lưu bộ lọc hiện tại
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

  /// Cập nhật trạng thái Khóa / Kích hoạt người dùng theo ID
  Future<void> updateStatus(String id, String status) async {
    await _service.updateUserStatus(id, status);
    // Tải lại danh sách theo đúng bộ lọc đang áp dụng
    await fetchUsers(
      search: _lastSearch,
      role: _lastRole,
      status: _lastStatus,
    );
  }

  /// Phân lại vai trò hệ thống cho người dùng (CUSTOMER, HOST, ADMIN)
  Future<void> updateRole(String id, String role) async {
    await _service.updateUserRole(id, role);
    // Tải lại danh sách theo đúng bộ lọc đang áp dụng
    await fetchUsers(
      search: _lastSearch,
      role: _lastRole,
      status: _lastStatus,
    );
  }
}

// ── 3. Quản lý Giao dịch Thanh toán (Payments) ──────────────────────────────
/// Class lưu bộ lọc trạng thái và phương thức thanh toán
class AdminPaymentsFilter {
  final String status; // Trạng thái: '' (Tất cả), SUCCESS, PENDING, FAILED
  final String method; // Phương thức: '' (Tất cả), VNPAY, CASH, E_WALLET

  const AdminPaymentsFilter({this.status = '', this.method = ''});

  AdminPaymentsFilter copyWith({String? status, String? method}) =>
      AdminPaymentsFilter(
        status: status ?? this.status,
        method: method ?? this.method,
      );
}

/// StateProvider lưu giữ filter thanh toán
final adminPaymentsFilterProvider = StateProvider<AdminPaymentsFilter>(
  (_) => const AdminPaymentsFilter(),
);

/// Provider quản lý danh sách thanh toán bất đồng bộ
final adminPaymentsProvider =
    StateNotifierProvider.autoDispose<
      AdminPaymentsNotifier,
      AsyncValue<List<AdminPaymentItem>>
    >((ref) {
      return AdminPaymentsNotifier(ref.watch(adminServiceProvider));
    });

/// Notifier điều khiển việc nạp danh sách lịch sử giao dịch thanh toán
class AdminPaymentsNotifier
    extends StateNotifier<AsyncValue<List<AdminPaymentItem>>> {
  final AdminService _service;

  AdminPaymentsNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchPayments(); // Tự động nạp danh sách giao dịch ban đầu
  }

  /// Tải danh sách giao dịch từ API dựa vào filter
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

// ── 4. Báo cáo Doanh thu Hệ thống (Revenue) ────────────────────────────────
/// FutureProvider nạp dữ liệu Báo cáo Doanh thu lũy kế toàn hệ thống
final adminRevenueProvider = FutureProvider<List<RevenueReportItem>>((
  ref,
) async {
  return ref.watch(adminServiceProvider).getRevenueReport();
});

// ── 5. Quản lý Phòng Homestay (Rooms) ───────────────────────────────────────
/// Provider hỗ trợ Admin xem toàn bộ danh sách phòng và thực hiện quyền Xóa / Ẩn phòng
final adminRoomsProvider =
    StateNotifierProvider.autoDispose<AdminRoomsNotifier, AsyncValue<List<RoomListItem>>>((
      ref,
    ) {
      final roomService = ref.watch(roomServiceProvider);
      final hostService = ref.watch(hostServiceProvider);
      return AdminRoomsNotifier(roomService, hostService);
    });

/// Notifier quản lý danh sách phòng cho Admin
class AdminRoomsNotifier extends StateNotifier<AsyncValue<List<RoomListItem>>> {
  final RoomService _roomService;
  final HostService _hostService;
  String? _lastSearchTerm;

  AdminRoomsNotifier(this._roomService, this._hostService)
    : super(const AsyncValue.loading()) {
    fetchRooms(); // Nạp danh sách phòng ban đầu
  }

  /// Lấy toàn bộ danh sách phòng Homestay có hỗ trợ tìm kiếm theo từ khóa
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

  /// Thực hiện quyền Admin xóa bài đăng Homestay bị vi phạm
  Future<void> deleteRoom(String id) async {
    await _hostService.deleteRoom(id);
    // Tải lại danh sách phòng sau khi xóa
    await fetchRooms(searchTerm: _lastSearchTerm);
  }
}


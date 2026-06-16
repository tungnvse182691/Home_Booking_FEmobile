import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/admin_model.dart';
import '../../host/models/host_model.dart'; // Reuse RevenueReportItem

class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  /// BE trả về PagedResult<T> = { total, page, pageSize, items: [...] }
  /// hoặc đôi khi wrap thêm { success, data: { total, page, pageSize, items } }
  List<dynamic> _extractItems(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      // PagedResult trực tiếp
      if (map.containsKey('items') && map['items'] is List) {
        return map['items'] as List;
      }
      // Wrapped trong data
      final nested = map['data'];
      if (nested is List) return nested;
      if (nested is Map) {
        final inner = Map<String, dynamic>.from(nested);
        if (inner.containsKey('items') && inner['items'] is List) {
          return inner['items'] as List;
        }
        if (inner.containsKey('data') && inner['data'] is List) {
          return inner['data'] as List;
        }
      }
    }
    return const [];
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<AdminDashboardData> getDashboard() async {
    final response = await _dio.get(ApiConstants.adminDashboard);
    final data = response.data['data'];
    return AdminDashboardData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ── Users ─────────────────────────────────────────────────────────────────
  /// BE: GET /api/admin/users?page&pageSize&search&role&status
  /// Returns PagedResult<AdminUserDto>
  Future<List<AdminUserItem>> getUsers({
    int page = 1,
    int pageSize = 100,
    String? search,
    String? role,
    String? status,
  }) async {
    final response = await _dio.get(
      ApiConstants.adminUsers,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final items = _extractItems(response.data['data']);
    return items
        .map((e) => AdminUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateUserStatus(String id, String status) async {
    await _dio.patch(
      '${ApiConstants.adminUsers}/$id/status',
      data: {'status': status},
    );
  }

  Future<void> updateUserRole(String id, String role) async {
    await _dio.patch(
      '${ApiConstants.adminUsers}/$id/role',
      data: {'role': role},
    );
  }

  // ── Payments ──────────────────────────────────────────────────────────────
  /// BE: GET /api/admin/payments?page&pageSize&status&method&userId
  /// Returns PagedResult<PaymentResponseDto>
  Future<List<AdminPaymentItem>> getPayments({
    int page = 1,
    int pageSize = 100,
    String? status,
    String? method,
  }) async {
    final response = await _dio.get(
      ApiConstants.adminPayments,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
        if (method != null && method.isNotEmpty) 'method': method,
      },
    );
    final items = _extractItems(response.data['data']);
    return items
        .map(
          (e) => AdminPaymentItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  // ── Rooms ─────────────────────────────────────────────────────────────────
  Future<void> updateRoom(String id, Map<String, dynamic> roomData) async {
    await _dio.put('${ApiConstants.adminRooms}/$id', data: roomData);
  }

  // ── Revenue ───────────────────────────────────────────────────────────────
  Future<List<RevenueReportItem>> getRevenueReport() async {
    final response = await _dio.get(ApiConstants.adminRevenue);
    final items = _extractItems(response.data['data']);
    return items
        .map(
          (e) =>
              RevenueReportItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}

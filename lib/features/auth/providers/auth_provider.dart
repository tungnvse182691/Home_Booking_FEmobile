import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

/// Provider cung cấp instance AuthService đã kết nối Dio Client

final authServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

/// Provider cung cấp StorageService quản lý lưu trữ JWT Token cục bộ
final storageServiceProvider = Provider((ref) => StorageService());

/// StateNotifier quản lý Trạng thái Xác thực (UserModel?) của toàn ứng dụng
class AuthStateNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthStateNotifier(this._authService, this._storageService) : super(null);

  /// Xử lý Đăng nhập: Gửi thông tin đăng nhập, lưu Auth Token & Role, cập nhật State
  Future<void> login(LoginRequest request) async {
    try {
      final response = await _authService.login(request);
      // Lưu JWT Token và vai trò người dùng vào bộ nhớ an toàn (Secure Storage / SharedPreferences)
      await _storageService.saveToken(response.accessToken);
      await _storageService.saveRole(response.user.role);
      state = response.user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  /// Xử lý Đăng xuất người dùng: Xóa Session và đặt State về null
  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }

  /// Gọi khi token hết hạn (HTTP 401) — Xóa sạch token lưu trong bộ nhớ mà không gọi API logout
  void forceLogout() {
    _storageService.clearAll();
    state = null;
  }

  /// Kiểm tra trạng thái đăng nhập tự động mỗi khi mở ứng dụng
  Future<void> checkAuth() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        // Lấy thông tin bản thân từ API /api/auth/me
        final user = await _authService.getMe();
        state = user;
      }
    } catch (e) {
      state = null;
    }
  }

  /// Cập nhật thông tin hồ sơ cá nhân (Họ tên, SĐT, Avatar, Email) và làm mới State
  Future<UserModel> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl,
    String email,
  ) async {
    final user = await _authService.updateProfile(fullName, phone, avatarUrl, email);
    state = user;
    return user;
  }
}

/// Provider chính quản lý Trạng thái Đăng nhập trên toàn dự án
final authStateProvider = StateNotifierProvider<AuthStateNotifier, UserModel?>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthStateNotifier(authService, storageService);
});


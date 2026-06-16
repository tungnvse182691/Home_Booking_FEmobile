import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

final storageServiceProvider = Provider((ref) => StorageService());

class AuthStateNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthStateNotifier(this._authService, this._storageService) : super(null);

  Future<void> login(LoginRequest request) async {
    try {
      final response = await _authService.login(request);
      await _storageService.saveToken(response.accessToken);
      await _storageService.saveRole(response.user.role);
      state = response.user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }

  /// Gọi khi token hết hạn (401) — xóa state mà không gọi API logout
  void forceLogout() {
    _storageService.clearAll();
    state = null;
  }

  Future<void> checkAuth() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final user = await _authService.getMe();
        state = user;
      }
    } catch (e) {
      state = null;
    }
  }

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

final authStateProvider = StateNotifierProvider<AuthStateNotifier, UserModel?>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthStateNotifier(authService, storageService);
});

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/response_utils.dart';
import '../models/auth_model.dart';

class AuthService {
  final Dio _dio;
  final StorageService _storageService = StorageService();

  AuthService(this._dio);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      if (response.data['success'] == true) {
        return AuthResponse.fromJson(extractDataMap(response.data));
      } else {
        throw Exception(response.data['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await _dio.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Gửi email thất bại');
    }
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await _dio.post(
      ApiConstants.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Đặt lại mật khẩu thất bại');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } finally {
      await _storageService.clearAll();
    }
  }

  Future<UserModel> getMe() async {
    // Prefer /api/auth/me as documented by backend; fallback to /api/profile if needed
    final endpoint = ApiConstants.authMe;
    final response = await _dio.get(endpoint);
    return UserModel.fromJson(extractDataMap(response.data));
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    return UserModel.fromJson(_extractUserData(response.data));
  }

  Future<UserModel> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl,
    String email,
  ) async {
    // Normalize phone number to match backend validation regex ^0\d{9}$
    // e.g., "+84 937 209 892" -> "0937209892"
    String normalizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalizedPhone.startsWith('+84')) {
      normalizedPhone = '0' + normalizedPhone.substring(3);
    } else if (normalizedPhone.startsWith('84') && normalizedPhone.length == 11) {
      normalizedPhone = '0' + normalizedPhone.substring(2);
    }

    try {
      final response = await _dio.put(
        ApiConstants.profile,
        data: {
          'fullName': fullName,
          'phone': normalizedPhone,
          'email': email.trim(),
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      if (response.data['success'] == true) {
        return UserModel.fromJson(_extractUserData(response.data));
      } else {
        throw Exception(response.data['message'] ?? 'Cập nhật thất bại');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Cập nhật thất bại';
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _extractUserData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return responseData;
    }
    if (responseData is Map) {
      final data = responseData['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return Map<String, dynamic>.from(responseData);
    }
    return <String, dynamic>{};
  }

  /// Đổi mật khẩu trực tiếp.
  /// Lưu ý: Endpoint POST /api/auth/change-password cần được xác nhận tồn tại ở Backend.
  /// Nếu Backend chưa có, luồng thay thế là dùng forgotPassword + resetPassword qua OTP email.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _dio.post(
      ApiConstants.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Đổi mật khẩu thất bại');
    }
  }
}

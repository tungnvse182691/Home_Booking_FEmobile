import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final dioProvider = Provider<Dio>((ref) {
  return DioClient(ref).dio;
});

class DioClient {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  DioClient(Ref ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;

          if (e.response != null) {
            switch (statusCode) {
              case 400:
                // Hiển thị message validation từ Backend
                // BE có thể trả về { message: "..." } hoặc { errors: { Field: [...] } }
                String msg400 = 'Dữ liệu không hợp lệ';
                if (responseData is Map) {
                  if (responseData['message'] != null) {
                    msg400 = responseData['message'].toString();
                  } else if (responseData['errors'] != null) {
                    final errors = responseData['errors'];
                    if (errors is Map) {
                      final msgs = <String>[];
                      errors.forEach((field, value) {
                        if (value is List && value.isNotEmpty) {
                          msgs.add('$field: ${value.first}');
                        } else {
                          msgs.add('$field: $value');
                        }
                      });
                      if (msgs.isNotEmpty) msg400 = msgs.join('\n');
                    }
                  }
                }
                _showSnackBar(msg400);
                break;

              case 401:
                // Xóa token khỏi storage.
                // GoRouter's redirect callback sẽ tự phát hiện authState = null
                // và đẩy người dùng về /login ở lần rebuild tiếp theo.
                await _storageService.clearAll();
                _showSnackBar(
                  'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
                );
                break;

              case 403:
                _showSnackBar('Bạn không có quyền truy cập tính năng này');
                break;

              case 404:
                final msg404 = responseData is Map
                    ? (responseData['message']?.toString() ??
                          'Không tìm thấy tài nguyên')
                    : 'Không tìm thấy tài nguyên';
                _showSnackBar(msg404);
                break;

              case 500:
                _showSnackBar('Có lỗi xảy ra từ máy chủ, vui lòng thử lại sau');
                break;

              default:
                final customMsg = responseData is Map
                    ? responseData['message']?.toString()
                    : null;
                _showSnackBar(customMsg ?? 'Đã xảy ra lỗi (${statusCode})');
                break;
            }
          } else {
            // Network error — không có response từ server
            _showSnackBar(
              'Không thể kết nối đến máy chủ. Kiểm tra kết nối mạng.',
            );
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  void _showSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

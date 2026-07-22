import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

/// Key toàn cục quản lý ScaffoldMessenger để hiển thị SnackBar thông báo từ Interceptor

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Provider cung cấp phiên Dio HTTP Client toàn cục
final dioProvider = Provider<Dio>((ref) {
  return DioClient(ref).dio;
});

/// Lớp cấu hình HTTP Client sử dụng Dio kết hợp Interceptors tự động
class DioClient {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  DioClient(Ref ref) {
    // 1. Cấu hình mặc định cho các Request HTTP
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,                    // Base URL của Backend API
        contentType: 'application/json',                 // Định dạng nội dung gửi đi
        connectTimeout: const Duration(seconds: 15),     // Thời gian chờ kết nối (15 giây)
        receiveTimeout: const Duration(seconds: 15),     // Thời gian chờ nhận phản hồi (15 giây)
      ),
    );

    // 2. Đăng ký Interceptor lắng nghe Request & Response
    _dio.interceptors.add(
      InterceptorsWrapper(
        // Tự động can thiệp trước khi gửi Request đi (onRequest)
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            // Tự động chèn Auth Bearer Token vào Request Header nếu đã đăng nhập
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        
        // Tự động bắt lỗi HTTP (onError) và hiển thị thông báo SnackBar
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;

          if (e.response != null) {
            switch (statusCode) {
              case 400:
                // Lỗi 400: Dữ liệu không hợp lệ (Bad Request)
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
                // Lỗi 401: Het hạn đăng nhập (Unauthorized) -> Xóa token và yêu cầu đăng nhập lại
                await _storageService.clearAll();
                _showSnackBar(
                  'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
                );
                break;

              case 403:
                // Lỗi 403: Không có quyền truy cập (Forbidden)
                _showSnackBar('Bạn không có quyền truy cập tính năng này');
                break;

              case 404:
                // Lỗi 404: Không tìm thấy trang/tài nguyên (Not Found)
                final msg404 = responseData is Map
                    ? (responseData['message']?.toString() ??
                          'Không tìm thấy tài nguyên')
                    : 'Không tìm thấy tài nguyên';
                _showSnackBar(msg404);
                break;

              case 500:
                // Lỗi 500: Lỗi hệ thống server (Internal Server Error)
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
            // Lỗi mạng hoặc Server không phản hồi
            _showSnackBar(
              'Không thể kết nối đến máy chủ. Kiểm tra kết nối mạng.',
            );
          }

          return handler.next(e);
        },
      ),
    );
  }

  /// Getter trả về phiên Dio đã cấu hình
  Dio get dio => _dio;

  /// Phương thức hiển thị thông báo SnackBar nổi ở phía dưới màn hình
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


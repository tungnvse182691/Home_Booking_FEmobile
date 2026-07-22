import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/host_booking_model.dart';

/// Service quản lý các yêu cầu HTTP liên quan đến đơn đặt phòng dành cho Host (Chủ nhà)
class HostBookingService {
  final Dio _dio;

  /// Khởi tạo HostBookingService với phiên DioClient đã được cấu hình Auth Token
  HostBookingService(this._dio);

  /// Trích xuất danh sách dữ liệu từ phản hồi API linh hoạt (bảo vệ lỗi định dạng trả về từ Backend)
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final d = data['data'];
      if (d is List) return d;
      if (d is Map) {
        final items = d['data'] ?? d['items'] ?? [];
        if (items is List) return items;
      }
    }
    return const [];
  }

  /// Lấy danh sách các đơn đặt phòng của Host (có thể lọc theo trạng thái status như PENDING, CONFIRMED, COMPLETED)
  Future<List<HostBookingItem>> getBookings({String? status}) async {
    // Gọi API GET /api/host/bookings kèm theo tham số status (nếu có)
    final response = await _dio.get(
      ApiConstants.hostBookings,
      queryParameters: status != null ? {'status': status} : null,
    );
    // Parse danh sách JSON trả về thành danh sách đối tượng HostBookingItem
    return _extractList(response.data)
        .map((e) => HostBookingItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Xác nhận (duyệt) đơn đặt phòng của khách hàng theo bookingId
  Future<void> confirmBooking(String bookingId) async {
    // Gọi API PATCH /api/host/bookings/{bookingId}/confirm
    await _dio.patch('${ApiConstants.hostBookings}/$bookingId/confirm');
  }

  /// Từ chối đơn đặt phòng của khách hàng kèm lý do từ chối (nếu có)
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    // Gọi API PATCH /api/host/bookings/{bookingId}/reject kèm lý do trong Body
    await _dio.patch(
      '${ApiConstants.hostBookings}/$bookingId/reject',
      data: reason != null ? {'reason': reason} : {},
    );
  }

  /// Đánh giá hoàn tất (Check-out) đơn đặt phòng
  Future<void> completeBooking(String bookingId) async {
    // Gọi API PATCH /api/host/bookings/{bookingId}/complete
    await _dio.patch('${ApiConstants.hostBookings}/$bookingId/complete');
  }
}


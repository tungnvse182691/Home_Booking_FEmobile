import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/booking_model.dart';

class BookingService {
  final Dio _dio;

  BookingService(this._dio);

  Future<BookingResponse> createBooking(BookingRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.bookings,
        data: request.toJson(),
      );

      final data = response.data;

      // BE trả về 2 dạng:
      // 1. Thành công: object trực tiếp { bookingId, bookingCode, totalAmount, status, ... }
      // 2. Thất bại:   { success: false, message: "..." }
      if (data is Map) {
        if (data['success'] == false) {
          throw Exception(data['message'] ?? 'Đặt phòng thất bại');
        }
        // Có bookingId → thành công trực tiếp
        if (data['bookingId'] != null) {
          return BookingResponse.fromJson(data as Map<String, dynamic>);
        }
        // Có success: true với data bên trong
        if (data['success'] == true && data['data'] != null) {
          return BookingResponse.fromJson(data['data'] as Map<String, dynamic>);
        }
      }

      // If response is successful but doesn't match expected shape, try to parse as object
      if (data is Map && data.isNotEmpty) {
        return BookingResponse.fromJson(data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      // If backend expects snake_case keys, retry once with alternative field names
      if (e.response?.statusCode == 400) {
        final altBody = {
          'room_id': request.roomId,
          'check_in_date': request.checkInDate,
          'check_out_date': request.checkOutDate,
          'payment_method': request.paymentMethod,
          if (request.specialRequest != null && request.specialRequest!.isNotEmpty)
            'special_request': request.specialRequest,
        };
        try {
          final retry = await _dio.post(ApiConstants.bookings, data: altBody);
          final data = retry.data;
          if (data is Map) {
            if (data['success'] == false) {
              throw Exception(data['message'] ?? 'Đặt phòng thất bại');
            }
            if (data['bookingId'] != null) {
              return BookingResponse.fromJson(data as Map<String, dynamic>);
            }
            if (data['success'] == true && data['data'] != null) {
              return BookingResponse.fromJson(data['data'] as Map<String, dynamic>);
            }
            return BookingResponse.fromJson(data as Map<String, dynamic>);
          }
        } catch (_) {
          // fallthrough to throw original
        }
      }
      rethrow;
    }

    throw Exception('Đặt phòng thất bại');
  }

  Future<PaymentResponse> createPayment(PaymentRequest request) async {
    final response = await _dio.post(
      ApiConstants.createPayment,
      data: request.toJson(),
    );
    final data = response.data;
    if (data is Map) {
      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Khởi tạo thanh toán thất bại');
      }
      if (data['success'] == true && data['data'] != null) {
        return PaymentResponse.fromJson(data['data'] as Map<String, dynamic>);
      }
      // Direct object
      if (data['transactionCode'] != null) {
        return PaymentResponse.fromJson(data as Map<String, dynamic>);
      }
    }
    throw Exception('Khởi tạo thanh toán thất bại');
  }

  Future<void> confirmPayment(PaymentConfirmRequest request) async {
    final response = await _dio.post(
      ApiConstants.confirmPayment,
      data: request.toJson(),
    );
    final data = response.data;
    if (data is Map && data['success'] == false) {
      throw Exception(data['message'] ?? 'Xác nhận thanh toán thất bại');
    }
  }

  Future<List<BookingHistoryItem>> getBookingHistory() async {
    final response = await _dio.get(ApiConstants.myHistory);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => BookingHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (data is Map) {
      if (data['success'] == true) {
        // BE trả về { total, data: [...] } — cần unwrap data bên trong
        final wrapper = data['data'];
        final List items = wrapper is Map
            ? (wrapper['data'] ?? wrapper['items'] ?? [])
            : (wrapper as List? ?? []);
        return items
            .map((e) => BookingHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data['data'] is List) {
        final List items = data['data'];
        return items
            .map((e) => BookingHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<void> cancelBooking(String id) async {
    final response = await _dio.patch('${ApiConstants.bookings}/$id/cancel');
    final data = response.data;
    if (data is Map && data['success'] == false) {
      throw Exception(data['message'] ?? 'Hủy đặt phòng thất bại');
    }
  }

  Future<void> changeBookingDate(
    String id,
    String checkIn,
    String checkOut,
  ) async {
    final response = await _dio.put(
      '${ApiConstants.bookings}/$id/change-date',
      data: {'checkInDate': checkIn, 'checkOutDate': checkOut},
    );
    final data = response.data;
    if (data is Map && data['success'] == false) {
      throw Exception(data['message'] ?? 'Đổi ngày thất bại');
    }
  }
}

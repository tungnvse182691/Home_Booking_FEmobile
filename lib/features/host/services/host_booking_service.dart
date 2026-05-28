import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/host_booking_model.dart';

class HostBookingService {
  final Dio _dio;
  HostBookingService(this._dio);

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

  Future<List<HostBookingItem>> getBookings({String? status}) async {
    final response = await _dio.get(
      ApiConstants.hostBookings,
      queryParameters: status != null ? {'status': status} : null,
    );
    return _extractList(response.data)
        .map((e) => HostBookingItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> confirmBooking(String bookingId) async {
    await _dio.patch('${ApiConstants.hostBookings}/$bookingId/confirm');
  }

  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    await _dio.patch(
      '${ApiConstants.hostBookings}/$bookingId/reject',
      data: reason != null ? {'reason': reason} : {},
    );
  }

  Future<void> completeBooking(String bookingId) async {
    await _dio.patch('${ApiConstants.hostBookings}/$bookingId/complete');
  }
}

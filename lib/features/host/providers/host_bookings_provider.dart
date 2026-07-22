import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/host_booking_model.dart';
import '../services/host_booking_service.dart';

/// Provider khởi tạo HostBookingService phục vụ quản lý đơn đặt phòng của Host
final hostBookingServiceProvider = Provider((ref) {
  return HostBookingService(ref.watch(dioProvider));
});

/// StateNotifierProvider quản lý danh sách và trạng thái các đơn đặt phòng của Host
final hostBookingsProvider =
    StateNotifierProvider<HostBookingsNotifier, AsyncValue<List<HostBookingItem>>>(
  (ref) => HostBookingsNotifier(ref.watch(hostBookingServiceProvider)),
);

/// Class Notifier quản lý các thao tác duyệt/từ chối/check-out đơn đặt phòng của Host
class HostBookingsNotifier
    extends StateNotifier<AsyncValue<List<HostBookingItem>>> {
  final HostBookingService _service;
  String? _currentStatus; // Trạng thái lọc hiện tại (PENDING, CONFIRMED, COMPLETED, CANCELLED)

  HostBookingsNotifier(this._service) : super(const AsyncValue.loading()) {
    Future.microtask(() => fetchBookings());
  }

  /// Tải danh sách các đơn đặt phòng (có thể lọc theo trạng thái status)
  Future<void> fetchBookings({String? status}) async {
    if (!mounted) return;
    _currentStatus = status;
    state = const AsyncValue.loading();
    try {
      final items = await _service.getBookings(status: status);
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Phê duyệt đơn đặt phòng theo bookingId và tự động tải lại danh sách
  Future<bool> confirmBooking(String bookingId) async {
    try {
      await _service.confirmBooking(bookingId);
      await fetchBookings(status: _currentStatus);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Từ chối đơn đặt phòng theo bookingId kèm lý do từ chối
  Future<bool> rejectBooking(String bookingId, {String? reason}) async {
    try {
      await _service.rejectBooking(bookingId, reason: reason);
      await fetchBookings(status: _currentStatus);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Đánh dấu hoàn thành đơn đặt phòng (Check-out)
  Future<bool> completeBooking(String bookingId) async {
    try {
      await _service.completeBooking(bookingId);
      await fetchBookings(status: _currentStatus);
      return true;
    } catch (_) {
      return false;
    }
  }
}


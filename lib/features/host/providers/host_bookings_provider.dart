import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/host_booking_model.dart';
import '../services/host_booking_service.dart';

final hostBookingServiceProvider = Provider((ref) {
  return HostBookingService(ref.watch(dioProvider));
});

final hostBookingsProvider =
    StateNotifierProvider<HostBookingsNotifier, AsyncValue<List<HostBookingItem>>>(
  (ref) => HostBookingsNotifier(ref.watch(hostBookingServiceProvider)),
);

class HostBookingsNotifier
    extends StateNotifier<AsyncValue<List<HostBookingItem>>> {
  final HostBookingService _service;
  String? _currentStatus;

  HostBookingsNotifier(this._service) : super(const AsyncValue.loading()) {
    Future.microtask(() => fetchBookings());
  }

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

  Future<bool> confirmBooking(String bookingId) async {
    try {
      await _service.confirmBooking(bookingId);
      await fetchBookings(status: _currentStatus);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, {String? reason}) async {
    try {
      await _service.rejectBooking(bookingId, reason: reason);
      await fetchBookings(status: _currentStatus);
      return true;
    } catch (_) {
      return false;
    }
  }

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

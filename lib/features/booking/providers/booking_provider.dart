import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

final bookingServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return BookingService(dio);
});

class BookingState {
  final bool isLoading;
  final String? error;

  BookingState({this.isLoading = false, this.error});

  BookingState copyWith({bool? isLoading, String? error}) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingService _service;

  BookingNotifier(this._service) : super(BookingState());

  Future<BookingResponse?> createBooking(BookingRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.createBooking(request);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      // Strip common Exception prefix for cleaner UI messages
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    }
  }

  Future<PaymentResponse?> createPayment(PaymentRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.createPayment(request);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    }
  }

  Future<bool> confirmPayment(PaymentConfirmRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.confirmPayment(request);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final service = ref.watch(bookingServiceProvider);
  return BookingNotifier(service);
});

final bookingHistoryProvider = StateNotifierProvider<BookingHistoryNotifier, AsyncValue<List<BookingHistoryItem>>>((ref) {
  final service = ref.watch(bookingServiceProvider);
  return BookingHistoryNotifier(service);
});

class BookingHistoryNotifier extends StateNotifier<AsyncValue<List<BookingHistoryItem>>> {
  final BookingService _service;

  BookingHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _service.getBookingHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      await _service.cancelBooking(id);
      await fetchHistory();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeDate(String id, String checkIn, String checkOut) async {
    try {
      await _service.changeBookingDate(id, checkIn, checkOut);
      await fetchHistory();
    } catch (e) {
      rethrow;
    }
  }
}

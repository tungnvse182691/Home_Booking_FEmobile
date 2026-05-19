import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import '../../rooms/providers/room_provider.dart';

class BookingState {
  final bool isLoading;
  final String? error;
  final String? lastBookingId;

  BookingState({this.isLoading = false, this.error, this.lastBookingId});

  BookingState copyWith({bool? isLoading, String? error, String? lastBookingId}) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastBookingId: lastBookingId ?? this.lastBookingId,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final Ref ref;

  BookingNotifier(this.ref) : super(BookingState());

  Future<bool> createBooking(BookingModel booking) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      
      // await dio.post('/api/bookings', data: booking.toJson());
      
      // Giả lập thành công
      await Future.delayed(const Duration(seconds: 2));
      
      final String fakeId = 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      state = state.copyWith(isLoading: false, lastBookingId: fakeId);
      return true;
    } on DioException catch (e) {
      String message = 'Đã xảy ra lỗi khi đặt phòng';
      if (e.response?.statusCode == 409) {
        message = 'Phòng đã có người đặt trong khoảng thời gian này';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref);
});

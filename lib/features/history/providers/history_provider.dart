import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_history_model.dart';
import '../../booking/providers/booking_provider.dart';

class HistoryState {
  final List<BookingHistoryModel> bookings;
  final bool isLoading;
  final String? error;

  HistoryState({this.bookings = const [], this.isLoading = false, this.error});

  HistoryState copyWith({
    List<BookingHistoryModel>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref ref;

  HistoryNotifier(this.ref) : super(HistoryState()) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bookingService = ref.read(bookingServiceProvider);
      final historyItems = await bookingService.getBookingHistory();

      // Chuyển đổi từ BookingHistoryItem (API) sang BookingHistoryModel (UI)
      final List<BookingHistoryModel> models = historyItems.map((item) {
        return BookingHistoryModel(
          id: item.bookingId,
          roomId: item.roomId,
          roomName: item.roomName,
          thumbnailUrl: item.thumbnailUrl,
          checkInDate: DateTime.parse(item.checkInDate),
          checkOutDate: DateTime.parse(item.checkOutDate),
          nights: DateTime.parse(
            item.checkOutDate,
          ).difference(DateTime.parse(item.checkInDate)).inDays,
          totalAmount: item.totalAmount,
          status: _parseStatus(item.status),
          rating: item.rating?.toDouble(),
        );
      }).toList();

      state = state.copyWith(isLoading: false, bookings: models);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  BookingStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return BookingStatus.PENDING;
      case 'CONFIRMED':
        return BookingStatus.CONFIRMED;
      case 'COMPLETED':
        return BookingStatus.COMPLETED;
      case 'CANCELED':
        return BookingStatus.CANCELED;
      default:
        return BookingStatus.PENDING;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.cancelBooking(bookingId);
      await fetchHistory();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  return HistoryNotifier(ref);
});

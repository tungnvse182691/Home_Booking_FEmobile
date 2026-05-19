import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/booking_history_model.dart';
import '../../rooms/providers/room_provider.dart';
import '../../rooms/models/room_model.dart';

class HistoryState {
  final List<BookingHistoryModel> bookings;
  final bool isLoading;
  final String? error;

  HistoryState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

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
      // Giả lập gọi API
      await Future.delayed(const Duration(seconds: 1));
      
      final mockData = [
        BookingHistoryModel(
          id: 'BK123456',
          roomId: '1',
          roomName: 'Cozy Forest House',
          location: 'Đà Lạt, Lâm Đồng',
          thumbnailUrl: 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=500&q=80',
          checkInDate: DateTime.now().add(const Duration(days: 5)),
          checkOutDate: DateTime.now().add(const Duration(days: 8)),
          nights: 3,
          totalAmount: 2400000,
          status: BookingStatus.CONFIRMED,
          host: HostModel(name: 'Nguyễn Văn A', avatar: 'https://i.pravatar.cc/150?u=a', rating: 4.8),
        ),
        BookingHistoryModel(
          id: 'BK123457',
          roomId: '2',
          roomName: 'Ocean View Villa',
          location: 'Vũng Tàu, Bà Rịa',
          thumbnailUrl: 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&q=80',
          checkInDate: DateTime.now().subtract(const Duration(days: 10)),
          checkOutDate: DateTime.now().subtract(const Duration(days: 7)),
          nights: 3,
          totalAmount: 7500000,
          status: BookingStatus.COMPLETED,
          rating: 5.0,
          review: 'Tuyệt vời!',
        ),
        BookingHistoryModel(
          id: 'BK123458',
          roomId: '3',
          roomName: 'Modern City Studio',
          location: 'Quận 1, TP. HCM',
          thumbnailUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=500&q=80',
          checkInDate: DateTime.now().subtract(const Duration(days: 20)),
          checkOutDate: DateTime.now().subtract(const Duration(days: 18)),
          nights: 2,
          totalAmount: 1700000,
          status: BookingStatus.CANCELED,
          canceledAt: DateTime.now().subtract(const Duration(days: 21)),
        ),
      ];

      state = state.copyWith(isLoading: false, bookings: mockData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      // await ref.read(dioProvider).patch('/api/bookings/$bookingId/cancel');
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        bookings: state.bookings.map((b) {
          if (b.id == bookingId) {
            return b.copyWith(status: BookingStatus.CANCELED, canceledAt: DateTime.now());
          }
          return b;
        }).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

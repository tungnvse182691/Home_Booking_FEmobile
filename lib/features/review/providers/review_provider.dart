import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rooms/providers/room_provider.dart';
import '../models/review_model.dart';

class ReviewState {
  final List<ReviewModel> reviews;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  ReviewState copyWith({
    List<ReviewModel>? reviews,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final Ref ref;

  ReviewNotifier(this.ref) : super(ReviewState());

  Future<void> fetchRoomReviews(String roomId) async {
    state = state.copyWith(isLoading: true);
    try {
      // Giả lập API
      await Future.delayed(const Duration(seconds: 1));
      
      final mockReviews = [
        ReviewModel(
          id: 'r1',
          bookingId: 'b1',
          roomId: roomId,
          userName: 'Nguyễn Thu Trang',
          userAvatar: 'https://i.pravatar.cc/150?u=r1',
          overallRating: 5,
          quickTags: ['Sạch sẽ', 'View đẹp'],
          comment: 'Phòng rất đẹp, chủ nhà nhiệt tình chu đáo. Sẽ quay lại lần sau!',
          images: ['https://picsum.photos/seed/rv1/400/300', 'https://picsum.photos/seed/rv2/400/300'],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ReviewModel(
          id: 'r2',
          bookingId: 'b2',
          roomId: roomId,
          userName: 'Trần Văn Bình',
          userAvatar: 'https://i.pravatar.cc/150?u=r2',
          overallRating: 4,
          quickTags: ['Vị trí tốt'],
          comment: 'Vị trí rất gần trung tâm, đi lại thuận tiện. Tuy nhiên phòng hơi nhỏ một chút so với ảnh.',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
      ];

      state = state.copyWith(isLoading: false, reviews: mockReviews);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitReview({
    required String bookingId,
    required String roomId,
    required double overallRating,
    required double cleanliness,
    required double location,
    required double service,
    required double value,
    required List<String> tags,
    String? comment,
    List<String> images = const [],
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final dio = ref.read(dioProvider);
      
      // await dio.post('/api/reviews', data: { ... });
      
      // Giả lập thành công
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(ref);
});

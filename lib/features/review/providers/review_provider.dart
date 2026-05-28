import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/response_utils.dart';
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
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/rooms/$roomId/reviews');
      if (response.data['success'] == true) {
        final items = extractItems(response.data['data']);
        final reviews = items.map((json) => ReviewModel.fromJson(json)).toList();
        state = state.copyWith(isLoading: false, reviews: reviews);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMyReviews() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/reviews/my-reviews');
      if (response.data['success'] == true) {
        final items = extractItems(response.data['data']);
        final reviews = items.map((json) => ReviewModel.fromJson(json)).toList();
        state = state.copyWith(isLoading: false, reviews: reviews);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitReview({
    required String bookingId,
    required String roomId,
    required double rating,
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

      final int ratingInt = rating.round().clamp(1, 5);
      final int cleanlinessInt = cleanliness.round().clamp(1, 5);
      final int locationInt = location.round().clamp(1, 5);
      final int serviceInt = service.round().clamp(1, 5);
      final int valueInt = value.round().clamp(1, 5);

      final Map<String, dynamic> body = {
        'bookingId': int.tryParse(bookingId) ?? 0,
        'rating': ratingInt,
        'cleanliness': cleanlinessInt,
        'location': locationInt,
        'service': serviceInt,
        'value': valueInt,
        if (tags.isNotEmpty) 'tags': tags,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      };

      final response = await dio.post('/api/reviews', data: body);

      final data = response.data;
      final isSuccess = (data is Map && data['success'] == true) ||
          (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300);

      state = state.copyWith(isSubmitting: false);
      return isSuccess;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateReview({
    required String reviewId,
    required double rating,
    required double cleanliness,
    required double location,
    required double service,
    required double value,
    required List<String> tags,
    String? comment,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final dio = ref.read(dioProvider);

      final Map<String, dynamic> body = {
        'rating': rating.round().clamp(1, 5),
        'cleanliness': cleanliness.round().clamp(1, 5),
        'location': location.round().clamp(1, 5),
        'service': service.round().clamp(1, 5),
        'value': value.round().clamp(1, 5),
        'tags': tags,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      };

      final response = await dio.put('/api/reviews/$reviewId', data: body);
      final isSuccess = response.data is Map && response.data['success'] == true;

      if (isSuccess) {
        // Cap nhat lai local state
        final updated = state.reviews.map((r) {
          if (r.reviewId == reviewId) {
            return ReviewModel.fromJson({
              ...response.data['data'],
              'reviewer': {'userId': r.userId, 'fullName': r.userName, 'avatarUrl': r.avatarUrl},
            });
          }
          return r;
        }).toList();
        state = state.copyWith(isSubmitting: false, reviews: updated);
      } else {
        state = state.copyWith(isSubmitting: false);
      }
      return isSuccess;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.delete('/api/reviews/$reviewId');
      final isSuccess = response.data is Map && response.data['success'] == true;

      if (isSuccess) {
        final updated = state.reviews.where((r) => r.reviewId != reviewId).toList();
        state = state.copyWith(isSubmitting: false, reviews: updated);
      } else {
        state = state.copyWith(isSubmitting: false);
      }
      return isSuccess;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/response_utils.dart';
import '../models/review_model.dart';

/// Lớp đại diện cho Trạng thái (State) của Quản lý Đánh giá Review

class ReviewState {
  final List<ReviewModel> reviews; // Danh sách các bài đánh giá
  final bool isLoading;            // Cờ đang tải dữ liệu danh sách
  final bool isSubmitting;         // Cờ đang gửi yêu cầu tạo/sửa/xóa đánh giá
  final String? error;             // Thông tin lỗi (nếu có)

  ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  /// Hàm hỗ trợ sao chép state với các giá trị mới
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

/// Lớp Notifier chịu trách nhiệm quản lý state và tương tác với API Đánh giá
class ReviewNotifier extends StateNotifier<ReviewState> {
  final Ref ref;

  ReviewNotifier(this.ref) : super(ReviewState());

  /// Lấy danh sách đánh giá của một phòng homestay theo roomId
  Future<void> fetchRoomReviews(String roomId) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      // Gọi API GET /api/rooms/{roomId}/reviews
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

  /// Lấy danh sách đánh giá cá nhân do chính người dùng hiện tại đã tạo
  Future<void> fetchMyReviews() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      // Gọi API GET /api/reviews/my-reviews
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

  /// Gửi tạo bài đánh giá mới cho đơn đặt phòng
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

      // Quy đổi điểm đánh giá từ double sang int (giới hạn từ 1 đến 5 sao)
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

      // Gọi API POST /api/reviews để gửi đánh giá
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

  /// Cập nhật bài đánh giá đã có theo reviewId
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

      // Gọi API PUT /api/reviews/{reviewId}
      final response = await dio.put('/api/reviews/$reviewId', data: body);
      final isSuccess = response.data is Map && response.data['success'] == true;

      if (isSuccess) {
        // Cập nhật lại local state danh sách reviews
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

  /// Xóa bài đánh giá theo reviewId
  Future<bool> deleteReview(String reviewId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final dio = ref.read(dioProvider);
      // Gọi API DELETE /api/reviews/{reviewId}
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

/// Provider toàn cục quản lý State của Review
final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(ref);
});


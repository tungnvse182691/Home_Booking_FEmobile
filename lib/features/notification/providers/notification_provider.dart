import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

/// Provider toàn cục quản lý trạng thái danh sách thông báo và số lượng chưa đọc bằng Riverpod

final notificationProvider =
    StateNotifierProvider<
      NotificationNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      return NotificationNotifier(ref);
    });

/// Lớp Notifier chịu trách nhiệm quản lý state và thực hiện gọi API tương tác thông báo
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;

  /// Khởi tạo Notifier và tự động tải danh sách thông báo lần đầu
  NotificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  /// Gọi API lấy danh sách thông báo từ hệ thống
  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      // Gọi API GET /api/notifications
      final response = await dio.get('/api/notifications');
      final data = response.data;
      
      // Trường hợp 1: API trả về một mảng JSON trực tiếp
      if (data is List) {
        final list = data
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = AsyncValue.data(list);
        return;
      }
      
      // Trường hợp 2: API trả về bọc đối tượng Map { success: true, data: ... }
      if (data is Map) {
        if (data['success'] == true) {
          // BE trả về { items: [...], page, limit, total, totalPages }
          final wrapper = data['data'];
          final List items = wrapper is Map
              ? (wrapper['items'] ?? wrapper['data'] ?? [])
              : (wrapper as List? ?? []);
          final list = items
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          state = AsyncValue.data(list);
        } else if (data['data'] is List) {
          final items = data['data'] as List;
          final list = items
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          state = AsyncValue.data(list);
        } else {
          state = AsyncValue.error(
            data['message'] ?? 'Lỗi tải thông báo',
            StackTrace.current,
          );
        }
        return;
      }
      state = AsyncValue.error('Lỗi tải thông báo', StackTrace.current);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Đánh dấu một thông báo là "Đã đọc" theo notificationId
  Future<void> markAsRead(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      // Gọi API PATCH /api/notifications/{id}/read
      await dio.patch('/api/notifications/$id/read');

      // Cập nhật lại state trực tiếp trên ứng dụng mà không cần fetch lại từ đầu
      final currentData = state.value;
      if (currentData != null) {
        state = AsyncValue.data(
          currentData
              .map((n) => n.notificationId == id ? _markRead(n) : n)
              .toList(),
        );
      }
    } catch (e) {
      // Xử lý lỗi nảy sinh khi đánh dấu đã đọc
    }
  }

  /// Helper đổi thuộc tính isRead = true cho thông báo
  NotificationModel _markRead(NotificationModel n) {
    return NotificationModel(
      notificationId: n.notificationId,
      title: n.title,
      body: n.body,
      isRead: true,
      createdAt: n.createdAt,
    );
  }

  /// Getter trả về số lượng thông báo chưa đọc để hiển thị badge icon trên thanh điều hướng
  int get unreadCount {
    return state.value?.where((n) => !n.isRead).length ?? 0;
  }
}


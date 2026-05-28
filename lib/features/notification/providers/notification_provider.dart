import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

final notificationProvider =
    StateNotifierProvider<
      NotificationNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      return NotificationNotifier(ref);
    });

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/api/notifications');
      final data = response.data;
      if (data is List) {
        final list = data
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = AsyncValue.data(list);
        return;
      }
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

  Future<void> markAsRead(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.patch('/api/notifications/$id/read');

      final currentData = state.value;
      if (currentData != null) {
        state = AsyncValue.data(
          currentData
              .map((n) => n.notificationId == id ? _markRead(n) : n)
              .toList(),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  NotificationModel _markRead(NotificationModel n) {
    return NotificationModel(
      notificationId: n.notificationId,
      title: n.title,
      body: n.body,
      isRead: true,
      createdAt: n.createdAt,
    );
  }

  int get unreadCount {
    return state.value?.where((n) => !n.isRead).length ?? 0;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../rooms/providers/room_provider.dart';

enum NotificationType { booking, payment, system }

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final String? relatedId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.relatedId,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
      relatedId: relatedId,
    );
  }
}

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;
  NotificationNotifier(this.ref) : super(NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Giả lập gọi API: GET /api/notifications
      await Future.delayed(const Duration(seconds: 1));
      
      final mockData = [
        NotificationModel(
          id: '1',
          title: 'Đặt phòng thành công',
          content: 'Bạn đã đặt thành công phòng Cozy Center Home.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          type: NotificationType.booking,
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          title: 'Thanh toán hoàn tất',
          content: 'Giao dịch cho mã đặt phòng #BK123 đã được xác nhận.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.payment,
          isRead: true,
        ),
        NotificationModel(
          id: '3',
          title: 'Chào mừng bạn',
          content: 'Chào mừng bạn đến với HomeBooking. Khám phá ngay các ưu đãi mới nhất!',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.system,
          isRead: true,
        ),
      ];

      state = state.copyWith(isLoading: false, notifications: mockData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // PATCH /api/notifications/read-all
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      // DELETE /api/notifications/:id
      final updated = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

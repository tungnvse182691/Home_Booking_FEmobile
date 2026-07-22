import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';
import '../providers/notification_provider.dart';

/// ============================================================================
/// MÀN HÌNH DANH SÁCH THÔNG BÁO PUSH NOTIFICATION (FE)
/// Cho phép người dùng xem tất cả thông báo hệ thống, trạng thái đã đọc/chưa đọc,
/// vuốt để làm mới và nhấn vào để đánh dấu thông báo là đã đọc.
/// ============================================================================

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi danh sách thông báo bất đồng bộ từ notificationProvider
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Thông báo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        // Kéo vuốt màn hình xuống để tự động nạp lại danh sách thông báo mới nhất
        onRefresh: () =>
            ref.read(notificationProvider.notifier).fetchNotifications(),
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Lỗi: $err',
              style: GoogleFonts.dmSans(color: Colors.red),
            ),
          ),
          data: (notifications) {

            if (notifications.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_off_outlined,
                          size: 88,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Không có thông báo nào',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chúng tôi sẽ gửi cho bạn các thông tin cập nhật tại đây.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return AnimationLimiter(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: ListTile(
                          tileColor: notification.isRead
                              ? null
                              : AppTheme.primary.withValues(alpha: 0.06),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          title: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                notification.body,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!notification.isRead) {
                              ref
                                  .read(notificationProvider.notifier)
                                  .markAsRead(notification.notificationId);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

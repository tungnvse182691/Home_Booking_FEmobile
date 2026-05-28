import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/booking_history_model.dart';
import '../providers/history_provider.dart';
import 'status_badge.dart';
import 'cancel_dialog.dart';
import '../../../utils/app_theme.dart';

class BookingItemCard extends ConsumerWidget {
  final BookingHistoryModel booking;

  const BookingItemCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: booking.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: booking.thumbnailUrl!,
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[100]),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey[100],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (booking.location != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.location!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${dateFormat.format(booking.checkInDate)} → ${dateFormat.format(booking.checkOutDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${booking.nights} đêm',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: booking.status),
                Text(
                  currencyFormat.format(booking.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    switch (booking.status) {
      case BookingStatus.PENDING:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(
                  '/booking-detail/${booking.id}',
                  extra: booking,
                ),
                child: const Text('Xem chi tiết'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleCancel(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  elevation: 0,
                ),
                child: const Text(
                  'Hủy phòng',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        );
      case BookingStatus.CONFIRMED:
        final canCancel =
            booking.checkInDate.difference(DateTime.now()).inHours > 24;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(
                  '/booking-detail/${booking.id}',
                  extra: booking,
                ),
                child: const Text('Xem chi tiết'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: canCancel
                  ? ElevatedButton(
                      onPressed: () => _handleCancel(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hủy phòng',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Không thể hủy (dưới 24h)',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
            ),
          ],
        );
      case BookingStatus.COMPLETED:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/room-detail/${booking.roomId}'),
                child: const Text('Đặt lại'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: booking.rating != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Đã đánh giá (${booking.rating})',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final success = await context.push(
                          '/review',
                          extra: {
                            'bookingId': booking.id,
                            'roomId': booking.roomId,
                            'roomName': booking.roomName,
                            'thumbnailUrl': booking.thumbnailUrl,
                          },
                        );
                        if (success == true) {
                          ref.read(historyProvider.notifier).fetchHistory();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Đánh giá',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ],
        );
      case BookingStatus.CANCELED:
        final canceledDate = booking.canceledAt != null
            ? DateFormat('dd/MM HH:mm').format(booking.canceledAt!)
            : 'N/A';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đã hủy lúc',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  Text(
                    canceledDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: OutlinedButton(
                onPressed: () => context.push('/room-detail/${booking.roomId}'),
                child: const Text('Đặt lại'),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const CancelDialog(),
    );

    if (confirmed == true) {
      final success = await ref
          .read(historyProvider.notifier)
          .cancelBooking(booking.id);
      if (success) {
        Fluttertoast.showToast(
          msg: "Đã hủy đặt phòng thành công",
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Có lỗi xảy ra, vui lòng thử lại",
          backgroundColor: Colors.red,
        );
      }
    }
  }
}

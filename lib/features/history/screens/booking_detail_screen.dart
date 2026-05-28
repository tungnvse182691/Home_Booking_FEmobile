import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/booking_history_model.dart';
import '../widgets/status_badge.dart';
import '../../../utils/app_theme.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingHistoryModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Chi tiết đặt phòng #${booking.id.substring(booking.id.length - 6)}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa
            if (booking.thumbnailUrl != null &&
                booking.thumbnailUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: booking.thumbnailUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: const Icon(Icons.home, size: 60, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: booking.status),
                      Text(
                        '#${booking.id}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    booking.roomName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (booking.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.location!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                  const Divider(height: 48),

                  const Text(
                    'THÔNG TIN LƯU TRÚ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Ngày nhận phòng',
                    dateFormat.format(booking.checkInDate),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Ngày trả phòng',
                    dateFormat.format(booking.checkOutDate),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số đêm nghỉ', '${booking.nights} đêm'),

                  const Divider(height: 48),

                  const Text(
                    'THANH TOÁN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Phương thức', 'Thẻ ngân hàng'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Tổng số tiền',
                    currencyFormat.format(booking.totalAmount),
                    isBold: true,
                  ),

                  if (booking.host != null) ...[
                    const Divider(height: 48),
                    const Text(
                      'CHỦ NHÀ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: booking.host!.avatarUrl != null &&
                                  booking.host!.avatarUrl!.isNotEmpty
                              ? (booking.host!.avatarUrl!.startsWith('http')
                                  ? NetworkImage(booking.host!.avatarUrl!)
                                  : FileImage(File(booking.host!.avatarUrl!)) as ImageProvider)
                              : null,
                          child: booking.host!.avatarUrl == null ||
                                  booking.host!.avatarUrl!.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.host!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'Chủ nhà siêu cấp',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.phone_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (booking.status == BookingStatus.CONFIRMED ||
                      booking.status == BookingStatus.PENDING)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          '/reschedule/${booking.id}',
                          extra: {
                            'roomId': booking.roomId,
                            'roomName': booking.roomName,
                            'currentCheckIn': booking.checkInDate,
                            'currentCheckOut': booking.checkOutDate,
                            'pricePerNight':
                                booking.totalAmount / booking.nights,
                            'blockedDates': [], // Sẽ lấy từ API trong thực tế
                          },
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đổi ngày đặt phòng',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
            color: isBold ? AppTheme.primary : Colors.black,
          ),
        ),
      ],
    );
  }
}

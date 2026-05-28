import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_theme.dart';
import '../../review/providers/review_provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  final Set<String> _reviewedBookingIds = {};
  bool _loadedReviews = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyReviews());
  }

  Future<void> _loadMyReviews() async {
    if (_loadedReviews) return;
    _loadedReviews = true;
    await ref.read(reviewProvider.notifier).fetchMyReviews();
    if (!mounted) return;
    setState(() {
      _reviewedBookingIds
        ..clear()
        ..addAll(
          ref
              .read(reviewProvider)
              .reviews
              .map((review) => review.bookingId)
              .where((bookingId) => bookingId.isNotEmpty),
        );
    });
  }

  Future<void> _refreshHistory() async {
    _loadedReviews = false;
    await ref.read(bookingHistoryProvider.notifier).fetchHistory();
    await _loadMyReviews();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(bookingHistoryProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử đặt phòng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Center(child: Text('Lỗi: $err')),
            ),
          ),
          data: (history) {
            if (history.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_online_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Bạn chưa có đặt phòng nào',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final booking = history[index];
                return _BookingCard(
                  booking: booking,
                  currencyFormat: currencyFormat,
                  reviewedBookingIds: _reviewedBookingIds,
                  onCancel: () => _cancelBooking(context, booking.bookingId),
                  onChangeDate: () => _changeBookingDate(context, booking),
                  onReview: () => _openReview(context, booking),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt phòng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(bookingHistoryProvider.notifier).cancelBooking(bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đặt phòng thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _changeBookingDate(
    BuildContext context,
    BookingHistoryItem booking,
  ) async {
    final checkIn = DateTime.tryParse(booking.checkInDate);
    final checkOut = DateTime.tryParse(booking.checkOutDate);
    if (checkIn == null || checkOut == null) return;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: checkIn, end: checkOut),
    );

    if (picked == null || !context.mounted) return;

    try {
      await ref
          .read(bookingHistoryProvider.notifier)
          .changeDate(
            booking.bookingId,
            DateFormat('yyyy-MM-dd').format(picked.start),
            DateFormat('yyyy-MM-dd').format(picked.end),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ngày thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _openReview(BuildContext context, BookingHistoryItem booking) {
    final roomId = booking.roomId;
    if (roomId == null || roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu roomId để mở màn hình đánh giá')),
      );
      return;
    }

    if (_reviewedBookingIds.contains(booking.bookingId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã đánh giá booking này rồi')),
      );
      return;
    }

    context.push(
      '/review',
      extra: {
        'bookingId': booking.bookingId,
        'roomId': roomId,
        'roomName': booking.roomName,
        'thumbnailUrl': booking.thumbnailUrl ?? '',
        'checkOutDate': booking.checkOutDate,
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingHistoryItem booking;
  final NumberFormat currencyFormat;
  final Set<String> reviewedBookingIds;
  final VoidCallback onCancel;
  final VoidCallback onChangeDate;
  final VoidCallback onReview;

  const _BookingCard({
    required this.booking,
    required this.currencyFormat,
    required this.reviewedBookingIds,
    required this.onCancel,
    required this.onChangeDate,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final checkIn = DateTime.tryParse(booking.checkInDate);
    final checkOut = DateTime.tryParse(booking.checkOutDate);
    final status = booking.status.toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final canManage = status == 'PENDING' || status == 'CONFIRMED';
    final canReview =
        isCompleted &&
        booking.roomId != null &&
        booking.roomId!.isNotEmpty &&
        !reviewedBookingIds.contains(booking.bookingId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    booking.roomName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${checkIn != null ? DateFormat('dd/MM/yyyy').format(checkIn) : booking.checkInDate} → ${checkOut != null ? DateFormat('dd/MM/yyyy').format(checkOut) : booking.checkOutDate}',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  currencyFormat.format(booking.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (canManage)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Hủy đặt phòng',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onChangeDate,
                    child: const Text('Đổi ngày'),
                  ),
                ],
              )
            else if (canReview)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onReview,
                  child: const Text('Đánh giá'),
                ),
              )
            else if (isCompleted)
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Đã đánh giá',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING':
        color = Colors.amber;
        label = 'Chờ xử lý';
        break;
      case 'CONFIRMED':
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'CANCELED':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case 'COMPLETED':
        color = Colors.blue;
        label = 'Hoàn thành';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

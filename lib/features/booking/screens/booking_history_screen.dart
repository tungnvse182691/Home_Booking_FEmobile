import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
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
              'Lịch sử đặt phòng',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
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
              child: Center(
                child: Text(
                  'Lỗi: $err',
                  style: GoogleFonts.dmSans(color: Colors.red),
                ),
              ),
            ),
          ),
          data: (history) {
            if (history.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.book_online_outlined,
                          size: 88,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bạn chưa có đặt phòng nào',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy tìm kiếm homestay và lên kế hoạch\ncho chuyến đi tiếp theo của bạn nhé!',
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
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final booking = history[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _BookingCard(
                          booking: booking,
                          currencyFormat: currencyFormat,
                          reviewedBookingIds: _reviewedBookingIds,
                          onCancel: () => _cancelBooking(context, booking.bookingId),
                          onChangeDate: () => _changeBookingDate(context, booking),
                          onReview: () => _openReview(context, booking),
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

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Xác nhận hủy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đặt phòng này không?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Không',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Đồng ý',
              style: GoogleFonts.dmSans(
                color: const Color(0xFFE57373),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(bookingHistoryProvider.notifier).cancelBooking(bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã hủy đặt phòng thành công',
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.dmSans(),
            ),
          ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
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
          SnackBar(
            content: Text(
              'Đã cập nhật ngày thành công',
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    }
  }

  void _openReview(BuildContext context, BookingHistoryItem booking) {
    final roomId = booking.roomId;
    if (roomId == null || roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thiếu roomId để mở màn hình đánh giá',
            style: GoogleFonts.dmSans(),
          ),
        ),
      );
      return;
    }

    if (_reviewedBookingIds.contains(booking.bookingId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn đã đánh giá booking này rồi',
            style: GoogleFonts.dmSans(),
          ),
        ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF3F4F6), width: 1),
      ),
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
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
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${checkIn != null ? DateFormat('dd/MM/yyyy').format(checkIn) : booking.checkInDate} → ${checkOut != null ? DateFormat('dd/MM/yyyy').format(checkOut) : booking.checkOutDate}',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  currencyFormat.format(booking.totalAmount),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF3F4F6)),
            if (canManage)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE57373),
                      side: const BorderSide(color: Color(0xFFEF9A9A)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Hủy đặt phòng',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onChangeDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Đổi ngày',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            else if (canReview)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Đánh giá',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else if (isCompleted)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Đã đánh giá',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
        color = const Color(0xFFFFB74D);
        label = 'Chờ xử lý';
        break;
      case 'CONFIRMED':
        color = AppTheme.primary;
        label = 'Đã xác nhận';
        break;
      case 'CANCELED':
        color = const Color(0xFFE57373);
        label = 'Đã hủy';
        break;
      case 'COMPLETED':
        color = AppTheme.success;
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
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

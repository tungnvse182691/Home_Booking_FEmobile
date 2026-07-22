import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/host_booking_model.dart';
import '../providers/host_bookings_provider.dart';
import '../../../utils/app_theme.dart';

/// Màn hình Quản lý đơn đặt phòng Homestay của Host (Chủ nhà)
class HostBookingsScreen extends ConsumerStatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  ConsumerState<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends ConsumerState<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Điều khiển chuyển đổi giữa các Tab trạng thái đơn

  // Các Tab trạng thái đơn đặt phòng tương ứng với mã status từ Backend
  static const _tabs = [
    ('Chờ duyệt', 'PENDING'),
    ('Đã xác nhận', 'CONFIRMED'),
    ('Hoàn thành', 'COMPLETED'),
    ('Đã hủy', 'CANCELED'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Khi thay đổi Tab -> Tự động gọi API tải danh sách đơn đặt phòng theo status tương ứng
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(hostBookingsProvider.notifier)
            .fetchBookings(status: _tabs[_tabController.index].$2);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Đọc trạng thái đơn đặt phòng từ hostBookingsProvider của Riverpod
    final bookingsAsync = ref.watch(hostBookingsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,

        surfaceTintColor: Colors.transparent,
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
              'Quản lý đặt phòng',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            tooltip: 'Làm mới',
            onPressed: () => ref
                .read(hostBookingsProvider.notifier)
                .fetchBookings(status: _tabs[_tabController.index].$2),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return bookingsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFE57373)),
                  const SizedBox(height: 12),
                  Text(
                    'Có lỗi xảy ra',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: const Color(0xFFE57373), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(hostBookingsProvider.notifier)
                        .fetchBookings(status: tab.$2),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            data: (items) {
              final filtered = items
                  .where((b) => b.status.toUpperCase() == tab.$2)
                  .toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 72, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text(
                        'Không có booking ${tab.$1.toLowerCase()}',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () => ref
                    .read(hostBookingsProvider.notifier)
                    .fetchBookings(status: tab.$2),
                child: AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: _BookingCard(
                            booking: filtered[i],
                            currencyFormat: currencyFormat,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final HostBookingItem booking;
  final NumberFormat currencyFormat;

  const _BookingCard({required this.booking, required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final status = booking.status.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: mã booking + trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingCode,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),

            // Tên phòng
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.roomName,
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Thông tin khách
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  booking.customerName,
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                if (booking.customerPhone != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    booking.customerPhone!,
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Ngày check-in / check-out
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${dateFormat.format(booking.checkInDate)} → ${dateFormat.format(booking.checkOutDate)}',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${booking.numberOfNights} đêm)',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tổng tiền
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  currencyFormat.format(booking.totalAmount),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // Yêu cầu đặc biệt
            if (booking.specialRequest != null &&
                booking.specialRequest!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_outlined, size: 14, color: Color(0xFFEF6C00)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.specialRequest!,
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFEF6C00)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Lý do hủy
            if (booking.cancelReason != null &&
                booking.cancelReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lý do: ${booking.cancelReason}',
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFD32F2F)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Nút hành động
            if (status == 'PENDING') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, ref),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE57373),
                        side: const BorderSide(color: Color(0xFFE57373)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAction(context, ref),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (status == 'CONFIRMED') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeAction(context, ref),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Đánh dấu hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xác nhận đặt phòng', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(
          'Xác nhận booking ${booking.bookingCode} của khách ${booking.customerName}?',
          style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text('Xác nhận', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success = await ref
          .read(hostBookingsProvider.notifier)
          .confirmBooking(booking.bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            success
                ? 'Đã xác nhận booking ${booking.bookingCode}'
                : 'Có lỗi xảy ra, vui lòng thử lại',
          ),
          backgroundColor: success ? AppTheme.success : const Color(0xFFE57373),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Từ chối đặt phòng', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Từ chối booking ${booking.bookingCode} của khách ${booking.customerName}?',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text('Từ chối', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      final success = await ref
          .read(hostBookingsProvider.notifier)
          .rejectBooking(
            booking.bookingId,
            reason: result.isEmpty ? null : result,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            success
                ? 'Đã từ chối booking ${booking.bookingCode}'
                : 'Có lỗi xảy ra, vui lòng thử lại',
          ),
          backgroundColor: success ? const Color(0xFFFFB74D) : const Color(0xFFE57373),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _completeAction(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hoàn thành đặt phòng', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(
          'Đánh dấu booking ${booking.bookingCode} là đã hoàn thành?\n\n'
          'Khách sẽ có thể viết đánh giá sau khi hoàn thành.',
          style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text('Hoàn thành', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success = await ref
          .read(hostBookingsProvider.notifier)
          .completeBooking(booking.bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            success
                ? 'Đã hoàn thành booking ${booking.bookingCode}'
                : 'Có lỗi xảy ra, vui lòng thử lại',
          ),
          backgroundColor: success ? AppTheme.primary : const Color(0xFFE57373),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case 'PENDING':
        bg = const Color(0xFFFFB74D).withValues(alpha: 0.15);
        fg = const Color(0xFFFFB74D);
        label = 'Chờ duyệt';
        break;
      case 'CONFIRMED':
        bg = AppTheme.primary.withValues(alpha: 0.1);
        fg = AppTheme.primary;
        label = 'Đã xác nhận';
        break;
      case 'COMPLETED':
        bg = AppTheme.success.withValues(alpha: 0.12);
        fg = AppTheme.success;
        label = 'Hoàn thành';
        break;
      case 'CANCELED':
        bg = const Color(0xFFE57373).withValues(alpha: 0.1);
        fg = const Color(0xFFE57373);
        label = 'Đã hủy';
        break;
      default:
        bg = AppTheme.textSecondary.withValues(alpha: 0.12);
        fg = AppTheme.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
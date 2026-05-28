import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/host_booking_model.dart';
import '../providers/host_bookings_provider.dart';
import '../../../utils/app_theme.dart';

class HostBookingsScreen extends ConsumerStatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  ConsumerState<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends ConsumerState<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // (label hiển thị, status gửi lên API)
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
    final bookingsAsync = ref.watch(hostBookingsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý đặt phòng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => ref
                .read(hostBookingsProvider.notifier)
                .fetchBookings(status: _tabs[_tabController.index].$2),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(hostBookingsProvider.notifier)
                        .fetchBookings(status: tab.$2),
                    icon: const Icon(Icons.refresh),
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
                      const Icon(Icons.inbox_outlined,
                          size: 72, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'Không có booking ${tab.$1.toLowerCase()}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref
                    .read(hostBookingsProvider.notifier)
                    .fetchBookings(status: tab.$2),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _BookingCard(
                    booking: filtered[i],
                    currencyFormat: currencyFormat,
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

// ─────────────────────────────────────────────────────────────────────────────
// Card hiển thị từng booking
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends ConsumerWidget {
  final HostBookingItem booking;
  final NumberFormat currencyFormat;

  const _BookingCard({required this.booking, required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final status = booking.status.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: mã booking + trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingCode,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),

            // Tên phòng
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.roomName,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                const Icon(Icons.person_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(booking.customerName,
                    style: const TextStyle(fontSize: 13)),
                if (booking.customerPhone != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.phone_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(
                    booking.customerPhone!,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Ngày check-in / check-out
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${dateFormat.format(booking.checkInDate)} → ${dateFormat.format(booking.checkOutDate)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${booking.numberOfNights} đêm)',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tổng tiền
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  currencyFormat.format(booking.totalAmount),
                  style: const TextStyle(
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
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.specialRequest!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Lý do hủy
            if (booking.cancelReason != null &&
                booking.cancelReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lý do: ${booking.cancelReason}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.red),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // ── Nút hành động ──────────────────────────────────────────────
            // PENDING → Từ chối | Xác nhận
            if (status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, ref),
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                      label: const Text('Từ chối',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAction(context, ref),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // CONFIRMED → Đánh dấu hoàn thành (sau khi khách checkout)
            if (status == 'CONFIRMED') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeAction(context, ref),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Đánh dấu hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Xác nhận booking ───────────────────────────────────────────────────────
  Future<void> _confirmAction(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đặt phòng'),
        content: Text(
          'Xác nhận booking ${booking.bookingCode} của khách ${booking.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
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
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    }
  }

  // ── Từ chối booking ────────────────────────────────────────────────────────
  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối đặt phòng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Từ chối booking ${booking.bookingCode} của khách ${booking.customerName}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
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
          backgroundColor: success ? Colors.orange : Colors.red,
        ));
      }
    }
  }

  // ── Đánh dấu hoàn thành ───────────────────────────────────────────────────
  Future<void> _completeAction(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành đặt phòng'),
        content: Text(
          'Đánh dấu booking ${booking.bookingCode} là đã hoàn thành?\n\n'
          'Khách sẽ có thể viết đánh giá sau khi hoàn thành.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
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
          backgroundColor: success ? Colors.blue : Colors.red,
        ));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip trạng thái
// ─────────────────────────────────────────────────────────────────────────────
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
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case 'CONFIRMED':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'COMPLETED':
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue;
        label = 'Hoàn thành';
        break;
      case 'CANCELED':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        label = 'Đã hủy';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/host_provider.dart';
import '../models/host_model.dart';

class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(hostDashboardProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Host Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(hostDashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Tổng phòng',
                        value: data.totalRooms.toString(),
                        icon: Icons.apartment_outlined,
                        color: Colors.blue,
                        onTap: () => context.push('/host/rooms'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Tổng booking',
                        value: data.totalBookings.toString(),
                        icon: Icons.event_note_outlined,
                        color: Colors.green,
                        onTap: () => context.push('/host/bookings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _StatCard(
                  title: 'Tổng doanh thu',
                  value: currencyFormat.format(data.totalRevenue),
                  icon: Icons.payments_outlined,
                  color: Colors.orange,
                  onTap: () => context.push('/host/revenue'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đơn đặt phòng gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildRecentBookings(context, data.recentBookings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookings(BuildContext context, List<RecentBooking> bookings) {
    if (bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Không có đơn đặt phòng nào gần đây',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(b.customerName),
          subtitle: Text(
            b.roomName.isNotEmpty ? b.roomName : 'Mã: ${b.bookingCode}',
          ),
          trailing: _buildStatusBadge(b.status),
          onTap: () => context.push('/host/bookings'),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toUpperCase();
    Color backgroundColor;
    Color foregroundColor;
    String label;

    if (normalized.contains('CANCEL')) {
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      foregroundColor = Colors.red;
      label = 'Đã hủy';
    } else if (normalized.contains('DONE') || normalized.contains('COMPLETE')) {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      foregroundColor = Colors.green;
      label = 'Hoàn thành';
    } else if (normalized.contains('PENDING') || normalized.contains('WAIT')) {
      backgroundColor = Colors.orange.withValues(alpha: 0.12);
      foregroundColor = Colors.orange;
      label = 'Chờ duyệt';
    } else if (normalized.contains('CONFIRM')) {
      backgroundColor = Colors.blue.withValues(alpha: 0.1);
      foregroundColor = Colors.blue;
      label = 'Đã xác nhận';
    } else {
      backgroundColor = Colors.grey.withValues(alpha: 0.12);
      foregroundColor = Colors.grey;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: foregroundColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/host_provider.dart';
import '../models/host_model.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/animated_pressable_card.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Bảng điều khiển Host',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.refresh(hostDashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFE57373)),
                const SizedBox(height: 12),
                Text(
                  'Không thể tải dữ liệu',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(hostDashboardProvider.future),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                        color: AppTheme.primary,
                        onTap: () => context.push('/host/rooms'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Tổng booking',
                        value: data.totalBookings.toString(),
                        icon: Icons.event_note_outlined,
                        color: AppTheme.primary,
                        onTap: () => context.push('/host/bookings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Tổng doanh thu',
                  value: currencyFormat.format(data.totalRevenue),
                  icon: Icons.payments_outlined,
                  color: AppTheme.primary,
                  onTap: () => context.push('/host/revenue'),
                ),
                const SizedBox(height: 28),
                Text(
                  'Đơn đặt phòng gần đây',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Không có đơn đặt phòng nào gần đây',
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primary,
              child: const Icon(Icons.person_outline_rounded),
            ),
            title: Text(
              b.customerName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              b.roomName.isNotEmpty ? b.roomName : 'Mã: ${b.bookingCode}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            trailing: _buildStatusBadge(b.status),
            onTap: () => context.push('/host/bookings'),
          ),
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
      backgroundColor = const Color(0xFFE57373).withValues(alpha: 0.1);
      foregroundColor = const Color(0xFFE57373);
      label = 'Đã hủy';
    } else if (normalized.contains('DONE') || normalized.contains('COMPLETE')) {
      backgroundColor = AppTheme.success.withValues(alpha: 0.1);
      foregroundColor = AppTheme.success;
      label = 'Hoàn thành';
    } else if (normalized.contains('PENDING') || normalized.contains('WAIT')) {
      backgroundColor = const Color(0xFFFFB74D).withValues(alpha: 0.12);
      foregroundColor = const Color(0xFFFFB74D);
      label = 'Chờ duyệt';
    } else if (normalized.contains('CONFIRM')) {
      backgroundColor = AppTheme.primary.withValues(alpha: 0.1);
      foregroundColor = AppTheme.primary;
      label = 'Đã xác nhận';
    } else {
      backgroundColor = AppTheme.textSecondary.withValues(alpha: 0.12);
      foregroundColor = AppTheme.textSecondary;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableCard(
      onTap: onTap,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 18),
        ],
      ),
    );
  }
}
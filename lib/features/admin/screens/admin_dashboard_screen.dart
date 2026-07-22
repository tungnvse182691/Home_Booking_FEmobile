import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/animated_pressable_card.dart';

/// ============================================================================
/// MÀN HÌNH BẢNG ĐIỀU KHIỂN QUẢN TRỊ (ADMIN DASHBOARD SCREEN)
/// Hiển thị thống kê chỉ số hệ thống, lối tắt điều hướng (Drawer) và các đơn đặt phòng mới nhất
/// ============================================================================

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy dữ liệu thống kê bất đồng bộ từ adminDashboardProvider
    final statsAsync = ref.watch(adminDashboardProvider);
    // Khởi tạo công cụ định dạng tiền tệ (VD: 100.000.000 ₫)
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bảng điều khiển',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Tổng quan hệ thống',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const _AdminDrawer(),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.refresh(adminDashboardProvider.future),
        child: statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Không thể tải dữ liệu', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(err.toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(adminDashboardProvider.future),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (data) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── KPI Grid ────────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    _KpiCard(
                      label: 'Người dùng',
                      value: _formatCompact(data.totalUsers),
                      icon: Icons.people_alt_outlined,
                      onTap: () => context.push('/admin/users'),
                    ),
                    _KpiCard(
                      label: 'Phòng cho thuê',
                      value: _formatCompact(data.totalRooms),
                      icon: Icons.home_outlined,
                      onTap: () => context.push('/admin/rooms'),
                    ),
                    _KpiCard(
                      label: 'Đặt phòng',
                      value: _formatCompact(data.totalBookings),
                      icon: Icons.calendar_month_outlined,
                      onTap: () => context.push('/admin/payments'),
                    ),
                    _KpiCard(
                      label: 'Doanh thu',
                      value: _formatRevenue(data.totalRevenue),
                      icon: Icons.trending_up_rounded,
                      isHighlight: true,
                      onTap: () => context.push('/admin/reports'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Quick Navigation ─────────────────────────────────────
                Text(
                  'Quản lý',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _NavCard(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Quản lý người dùng',
                  subtitle: '${data.totalUsers} tài khoản',
                  onTap: () => context.push('/admin/users'),
                ),
                _NavCard(
                  icon: Icons.home_work_outlined,
                  title: 'Quản lý phòng',
                  subtitle: '${data.totalRooms} phòng đang hoạt động',
                  onTap: () => context.push('/admin/rooms'),
                ),
                _NavCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Quản lý giao dịch',
                  subtitle: '${data.totalBookings} đơn đặt phòng',
                  onTap: () => context.push('/admin/payments'),
                ),
                _NavCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo doanh thu',
                  subtitle: currencyFormat.format(data.totalRevenue),
                  onTap: () => context.push('/admin/reports'),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  String _formatRevenue(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B₫';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M₫';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K₫';
    return '${value.toStringAsFixed(0)}₫';
  }
}

// ── KPI Card ───────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableCard(
      onTap: onTap,
      color: isHighlight ? AppTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      shadows: [
        BoxShadow(
          color: isHighlight
              ? AppTheme.primary.withOpacity(0.25)
              : Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight
                  ? Colors.white.withOpacity(0.2)
                  : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isHighlight ? Colors.white : AppTheme.primary,
            ),
          ),
          // Value + Label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isHighlight ? Colors.white : AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isHighlight
                      ? Colors.white.withOpacity(0.85)
                      : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav Card ───────────────────────────────────────────────────────────────
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin Drawer ───────────────────────────────────────────────────────────
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  'StayEase Admin',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Bảng điều khiển quản trị',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Menu items
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.people_outline_rounded,
            label: 'Người dùng',
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/users');
            },
          ),
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Phòng',
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/rooms');
            },
          ),
          _DrawerItem(
            icon: Icons.receipt_long_outlined,
            label: 'Thanh toán',
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/payments');
            },
          ),
          _DrawerItem(
            icon: Icons.bar_chart_outlined,
            label: 'Báo cáo',
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/reports');
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

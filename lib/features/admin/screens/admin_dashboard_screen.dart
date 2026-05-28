import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      drawer: _AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashboardProvider.future),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _statCard(
                      'Người dùng',
                      data.totalUsers.toString(),
                      Icons.people,
                      Colors.blue,
                      () => context.push('/admin/users'),
                    ),
                    _statCard(
                      'Phòng',
                      data.totalRooms.toString(),
                      Icons.home,
                      Colors.orange,
                      () => context.push('/admin/rooms'),
                    ),
                    _statCard(
                      'Đặt phòng',
                      data.totalBookings.toString(),
                      Icons.book_online,
                      Colors.green,
                      () => context.push('/admin/payments'),
                    ),
                    _statCard(
                      'Doanh thu',
                      currencyFormat.format(data.totalRevenue),
                      Icons.payments,
                      Colors.red,
                      () => context.push('/admin/reports'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _menuTile(
                  context,
                  'Quản lý Người dùng',
                  Icons.person_search,
                  '/admin/users',
                ),
                _menuTile(
                  context,
                  'Quản lý Phòng',
                  Icons.home_work_outlined,
                  '/admin/rooms',
                ),
                _menuTile(
                  context,
                  'Quản lý Giao dịch',
                  Icons.receipt_long,
                  '/admin/payments',
                ),
                _menuTile(
                  context,
                  'Báo cáo Doanh thu',
                  Icons.bar_chart,
                  '/admin/reports',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Admin Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Người dùng'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_work_outlined),
            title: const Text('Phòng'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/rooms');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Thanh toán'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/payments');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Báo cáo'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/profile_provider.dart';
import '../../../utils/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final user = state.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: state.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: AppTheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.primary, Color(0xFFD32F2F)],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 47,
                                  backgroundImage: user?.avatar != null ? CachedNetworkImageProvider(user!.avatar!) : null,
                                  child: user?.avatar == null ? const Icon(Icons.person, size: 50) : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => context.push('/edit-profile'),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit, color: AppTheme.primary, size: 16),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.name ?? 'Khách hàng',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.phone ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Stats Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('12', 'Đặt phòng'),
                              _buildDivider(),
                              _buildStatItem('5', 'Yêu thích'),
                              _buildDivider(),
                              _buildStatItem('8', 'Đánh giá'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Menu List
                        _buildMenuSection(context, user),
                        const SizedBox(height: 32),
                        // Logout
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _showLogoutDialog(context, ref),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildMenuSection(BuildContext context, UserModel? user) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildMenuItem(Icons.person_outline, 'Thông tin cá nhân', () => context.push('/edit-profile')),
          _buildMenuItem(Icons.lock_outline, 'Đổi mật khẩu', () => context.push('/change-password')),
          _buildMenuItem(Icons.favorite_border, 'Phòng yêu thích', () => context.push('/favorite')),
          _buildMenuItem(Icons.notifications_none, 'Thông báo', () => context.push('/notifications')),
          _buildMenuItem(Icons.star_border, 'Đánh giá của tôi', () => context.push('/my-reviews')),
          if (user?.role == 'HOST')
            _buildMenuItem(Icons.home_work_outlined, 'Quản lý phòng', () => context.push('/my-rooms')),
          _buildMenuItem(Icons.info_outline, 'Về ứng dụng', () {}, isLast: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isLast = false}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
      shape: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade50)),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await ref.read(profileProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

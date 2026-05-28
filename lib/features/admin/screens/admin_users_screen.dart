import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/admin_model.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = '';
  String _selectedStatus = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter() async {
    ref
        .read(adminUsersProvider.notifier)
        .fetchUsers(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          role: _selectedRole.isEmpty ? null : _selectedRole,
          status: _selectedStatus.isEmpty ? null : _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _applyFilter),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email, SĐT...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyFilter(),
                  onChanged: (v) {
                    setState(() {});
                    if (v.isEmpty) _applyFilter();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Vai trò',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(
                            value: 'CUSTOMER',
                            child: Text('Customer'),
                          ),
                          DropdownMenuItem(value: 'HOST', child: Text('Host')),
                          DropdownMenuItem(
                            value: 'ADMIN',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedRole = v ?? '');
                          _applyFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(
                            value: 'ACTIVE',
                            child: Text('Hoạt động'),
                          ),
                          DropdownMenuItem(
                            value: 'BANNED',
                            child: Text('Bị khóa'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedStatus = v ?? '');
                          _applyFilter();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── User list ────────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _applyFilter,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy người dùng',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _applyFilter,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _UserTile(user: users[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AdminUserItem user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? (user.avatarUrl!.startsWith('http')
                  ? NetworkImage(user.avatarUrl!)
                  : FileImage(File(user.avatarUrl!)) as ImageProvider)
            : null,
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              )
            : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (user.phone.isNotEmpty)
            Text(
              user.phone,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              _badge(
                user.role,
                user.role == 'ADMIN'
                    ? Colors.purple
                    : user.role == 'HOST'
                    ? Colors.orange
                    : Colors.blue,
              ),
              const SizedBox(width: 6),
              _badge(
                user.status,
                user.status == 'ACTIVE' ? Colors.green : Colors.red,
              ),
              if (user.createdAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  'Tham gia: ${dateFormat.format(user.createdAt!)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleAction(context, ref, value),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'status',
            child: Row(
              children: [
                Icon(
                  user.status == 'ACTIVE' ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: user.status == 'ACTIVE' ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(user.status == 'ACTIVE' ? 'Khóa tài khoản' : 'Kích hoạt'),
              ],
            ),
          ),
          if (user.role != 'ADMIN')
            PopupMenuItem(
              value: 'role',
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    user.role == 'CUSTOMER'
                        ? 'Nâng lên HOST'
                        : 'Hạ xuống CUSTOMER',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final title = action == 'status'
        ? (user.status == 'ACTIVE' ? 'Khóa tài khoản' : 'Kích hoạt tài khoản')
        : 'Thay đổi vai trò';
    final content = action == 'status'
        ? 'Bạn có chắc chắn muốn ${user.status == 'ACTIVE' ? 'khóa' : 'kích hoạt'} tài khoản "${user.fullName}"?'
        : 'Chuyển "${user.fullName}" sang ${user.role == 'CUSTOMER' ? 'HOST' : 'CUSTOMER'}?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (action == 'status') {
                final newStatus = user.status == 'ACTIVE' ? 'BANNED' : 'ACTIVE';
                await ref
                    .read(adminUsersProvider.notifier)
                    .updateStatus(user.userId, newStatus);
              } else {
                final newRole = user.role == 'CUSTOMER' ? 'HOST' : 'CUSTOMER';
                await ref
                    .read(adminUsersProvider.notifier)
                    .updateRole(user.userId, newRole);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'status' && user.status == 'ACTIVE'
                  ? Colors.red
                  : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

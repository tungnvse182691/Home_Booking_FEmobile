import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/admin_model.dart';
import '../../../utils/app_theme.dart';

/// ============================================================================
/// MÀN HÌNH QUẢN LÝ NGƯỜI DÙNG (DÀNH CHO ADMIN)
/// Cung cấp tính năng: Tìm kiếm (Search Debounce), Lọc theo Role & Trạng thái,
/// Phân vai trò (Customer/Host/Admin) và Khóa/Kích hoạt tài khoản người dùng.
/// ============================================================================

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  // Controller quản lý ô nhập từ khóa tìm kiếm
  final _searchController = TextEditingController();
  String _selectedRole = '';   // Role được chọn lọc: '' (Tất cả), CUSTOMER, HOST, ADMIN
  String _selectedStatus = ''; // Trạng thái được chọn lọc: '' (Tất cả), ACTIVE, INACTIVE
  Timer? _searchDebounce;      // Timer hoãn nạp dữ liệu khi đang gõ chữ (Debounce 350ms)

  @override
  void initState() {
    super.initState();
    // Tự động gọi hàm nạp danh sách ngay sau khi Widget dựng xong khung
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  @override
  void dispose() {
    // Hủy Timer debounce và giải phóng bộ nhớ của Controller khi thoát màn hình
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Áp dụng bộ lọc và kích hoạt Provider nạp lại dữ liệu từ Backend
  Future<void> _applyFilter() async {
    ref.read(adminUsersProvider.notifier).fetchUsers(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      role: _selectedRole.isEmpty ? null : _selectedRole,
      status: _selectedStatus.isEmpty ? null : _selectedStatus,
    );
  }

  /// Xử lý sự kiện gõ phím ô Tìm kiếm với Debounce (chờ 350ms ngừng gõ mới tìm)
  void _onSearchChanged(String v) {
    setState(() {});
    _searchDebounce?.cancel(); // Hủy Timer cũ nếu người dùng tiếp tục gõ
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _applyFilter(); // Tìm kiếm tự động sau 350ms
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final theme = Theme.of(context);


    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
            const Text(
              'Quản lý người dùng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _applyFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email, SĐT...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              _applyFilter();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) {
                    _searchDebounce?.cancel();
                    _applyFilter();
                  },
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 10),
                // Filter dropdowns
                Row(
                  children: [
                    // Role filter
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Vai trò',
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(
                            value: 'CUSTOMER',
                            child: Text('Khách hàng'),
                          ),
                          DropdownMenuItem(value: 'HOST', child: Text('Chủ phòng')),
                          DropdownMenuItem(
                            value: 'ADMIN',
                            child: Text('Quản trị'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedRole = v ?? '');
                          _applyFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Status filter
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Trạng thái',
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(
                            value: 'ACTIVE',
                            child: Text('Hoạt động'),
                          ),
                          DropdownMenuItem(
                            value: 'INACTIVE',
                            child: Text('Chưa kích hoạt'),
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
                // Active filter chips
                if (_selectedRole.isNotEmpty || _selectedStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Đang lọc:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        if (_selectedRole.isNotEmpty)
                          _ActiveChip(
                            label: _roleLabel(_selectedRole),
                            onRemove: () {
                              setState(() => _selectedRole = '');
                              _applyFilter();
                            },
                          ),
                        if (_selectedStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _ActiveChip(
                              label: _statusLabel(_selectedStatus),
                              onRemove: () {
                                setState(() => _selectedStatus = '');
                                _applyFilter();
                              },
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = '';
                              _selectedStatus = '';
                            });
                            _applyFilter();
                          },
                          child: const Text(
                            'Xóa lọc',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── User list ────────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể tải dữ liệu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _applyFilter,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy người dùng',
                          style: TextStyle(color: Colors.grey[500], fontSize: 15),
                        ),
                        if (_selectedRole.isNotEmpty || _selectedStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedRole = '';
                                  _selectedStatus = '';
                                });
                                _applyFilter();
                              },
                              child: const Text('Xóa bộ lọc'),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _applyFilter,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) =>
                          AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 350),
                        child: SlideAnimation(
                          verticalOffset: 36,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _UserCard(
                                user: users[index],
                                currentRole: _selectedRole,
                                currentStatus: _selectedStatus,
                                onActionDone: _applyFilter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'CUSTOMER':
        return 'Khách hàng';
      case 'HOST':
        return 'Chủ phòng';
      case 'ADMIN':
        return 'Quản trị';
      default:
        return role;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Hoạt động';
      case 'INACTIVE':
        return 'Chưa kích hoạt';
      case 'BANNED':
        return 'Bị khóa';
      default:
        return status;
    }
  }
}

// ── Filter Dropdown Widget ──────────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: hasValue
            ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
            : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasValue
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: hasValue ? 1.5 : 0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hasValue
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            items: items,
            onChanged: onChanged,
            hint: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Active Filter Chip ──────────────────────────────────────────────────────
class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────────────────────
class _UserCard extends ConsumerWidget {
  final AdminUserItem user;
  final String currentRole;
  final String currentStatus;
  final VoidCallback onActionDone;

  const _UserCard({
    required this.user,
    required this.currentRole,
    required this.currentStatus,
    required this.onActionDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + menu
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildMenu(context, ref),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Email
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Phone
                  if (user.phone.isNotEmpty)
                    Text(
                      user.phone,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 6),
                  // Badges row
                  Row(
                    children: [
                      _roleBadge(user.role),
                      const SizedBox(width: 6),
                      _statusBadge(user.status),
                      const Spacer(),
                      if (user.createdAt != null)
                        Text(
                          dateFormat.format(user.createdAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final color = user.role == 'ADMIN'
        ? Colors.purple
        : user.role == 'HOST'
            ? Colors.orange
            : Colors.blue;

    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withOpacity(0.15),
      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? (user.avatarUrl!.startsWith('http')
                ? NetworkImage(user.avatarUrl!)
                : FileImage(File(user.avatarUrl!)) as ImageProvider)
          : null,
      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
          ? Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleAction(context, ref, value),
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(
                user.status == 'ACTIVE' ? Icons.lock_outline : Icons.lock_open,
                size: 16,
                color: user.status == 'ACTIVE' ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 10),
              Text(
                user.status == 'ACTIVE' ? 'Khóa tài khoản' : 'Kích hoạt',
                style: TextStyle(
                  color: user.status == 'ACTIVE' ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (user.role != 'ADMIN')
          PopupMenuItem(
            value: 'role',
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, size: 16),
                const SizedBox(width: 10),
                Text(
                  user.role == 'CUSTOMER' ? 'Nâng lên HOST' : 'Hạ xuống CUSTOMER',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _roleBadge(String role) {
    final (label, color) = switch (role) {
      'ADMIN' => ('Quản trị', Colors.purple),
      'HOST' => ('Chủ phòng', Colors.orange),
      _ => ('Khách hàng', Colors.blue),
    };
    return _Badge(label: label, color: color);
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'ACTIVE' => ('Hoạt động', Colors.green),
      'BANNED' => ('Bị khóa', Colors.red),
      _ => ('Chưa kích hoạt', Colors.grey),
    };
    return _Badge(label: label, color: color);
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final title = action == 'status'
        ? (user.status == 'ACTIVE' ? 'Khóa tài khoản' : 'Kích hoạt tài khoản')
        : 'Thay đổi vai trò';
    final content = action == 'status'
        ? 'Bạn có chắc muốn ${user.status == 'ACTIVE' ? 'khóa' : 'kích hoạt'} tài khoản "${user.fullName}"?'
        : 'Chuyển "${user.fullName}" sang ${user.role == 'CUSTOMER' ? 'HOST' : 'CUSTOMER'}?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                final newStatus =
                    user.status == 'ACTIVE' ? 'BANNED' : 'ACTIVE';
                await ref
                    .read(adminUsersProvider.notifier)
                    .updateStatus(user.userId, newStatus);
              } else {
                final newRole =
                    user.role == 'CUSTOMER' ? 'HOST' : 'CUSTOMER';
                await ref
                    .read(adminUsersProvider.notifier)
                    .updateRole(user.userId, newRole);
              }
              // Re-apply filter after action to keep current filter state
              onActionDone();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == 'status' && user.status == 'ACTIVE'
                      ? Colors.red
                      : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

// ── Badge Widget ────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../../../utils/app_theme.dart';

class MyRoomsScreen extends ConsumerWidget {
  const MyRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trong thực tế sẽ dùng một provider riêng cho host rooms
    // final rooms = ref.watch(hostRoomsProvider); 
    final roomState = ref.watch(roomNotifierProvider);
    final rooms = roomState.rooms; // Tạm thời dùng chung danh sách để demo

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Phòng của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => context.push('/create-room'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: rooms.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return _buildDismissibleCard(context, ref, room);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Bạn chưa có phòng nào', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/create-room'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Tạo phòng ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(BuildContext context, WidgetRef ref, RoomModel room) {
    return Dismissible(
      key: Key(room.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirm(context),
      onDismissed: (direction) {
        // ref.read(roomNotifierProvider.notifier).deleteRoom(room.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phòng')));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: _MyRoomCard(room: room),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phòng?'),
        content: const Text('Bạn có chắc chắn muốn xóa phòng này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MyRoomCard extends StatelessWidget {
  final RoomModel room;

  const _MyRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Giả lập trạng thái vì RoomModel chưa có status
    const String status = 'ACTIVE'; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: room.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatusBadge(status),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${room.rating}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${room.reviews})',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currencyFormat.format(room.price)} / đêm',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(icon: Icons.edit_outlined, label: 'Sửa', onTap: () => context.push('/edit-room/${room.id}')),
              _ActionButton(icon: Icons.calendar_today_outlined, label: 'Lịch', onTap: () => context.push('/room-calendar/${room.id}', extra: room.name)),
              _ActionButton(
                icon: status == 'ACTIVE' ? Icons.pause_circle_outline : Icons.play_circle_outline,
                label: status == 'ACTIVE' ? 'Tạm dừng' : 'Bật lại',
                color: status == 'ACTIVE' ? Colors.orange : Colors.green,
                onTap: () {},
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'ACTIVE':
        color = Colors.green;
        text = 'Đang hoạt động';
        break;
      case 'INACTIVE':
        color = Colors.red;
        text = 'Tạm dừng';
        break;
      default:
        color = Colors.orange;
        text = 'Chờ duyệt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color ?? AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

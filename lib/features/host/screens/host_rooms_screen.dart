import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/host_provider.dart';
import '../models/host_model.dart';
import '../../../utils/app_theme.dart';

class HostRoomsScreen extends ConsumerWidget {
  const HostRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(hostRoomsProvider);
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
              'Quản lý phòng',
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
            tooltip: 'Tải lại',
            onPressed: () => ref.read(hostRoomsProvider.notifier).fetchRooms(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(hostRoomsProvider.notifier).fetchRooms(),
        child: roomsAsync.when(
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
                  'Có lỗi xảy ra',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.read(hostRoomsProvider.notifier).fetchRooms(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (rooms) => rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_outlined, size: 72, color: AppTheme.textHint),
                      const SizedBox(height: 16),
                      Text(
                        'Bạn chưa có phòng nào',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn nút bên dưới để tạo phòng mới',
                        style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: _buildRoomCard(
                              context,
                              ref,
                              room,
                              currencyFormat,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-room'),
        backgroundColor: AppTheme.primary,
        shape: const CircleBorder(),
        tooltip: 'Tạo phòng mới',
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    WidgetRef ref,
    HostRoomItem room,
    NumberFormat currencyFormat,
  ) {
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
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: room.thumbnailUrl != null && room.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: room.thumbnailUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 14),

            // Thông tin phòng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${currencyFormat.format(room.price)} / đêm',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (room.city.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            room.city,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _specIcon(Icons.bed_outlined, '${room.bedrooms} PN'),
                      const SizedBox(width: 8),
                      _specIcon(Icons.bathtub_outlined, '${room.bathrooms} PT'),
                      const SizedBox(width: 8),
                      _specIcon(Icons.people_outline, '${room.maxGuests} khách'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusChip(status: room.status),
                      if (room.reviewCount > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${room.ratingAvg.toStringAsFixed(1)} (${room.reviewCount})',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Nút hành động
            Column(
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Sửa phòng',
                  onPressed: () => context.push('/edit-room/${room.id}'),
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.calendar_month_outlined,
                  tooltip: 'Lịch phòng',
                  onPressed: () => context.push(
                    '/room-calendar/${room.id}',
                    extra: room.name,
                  ),
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Xóa phòng',
                  color: const Color(0xFFE57373),
                  onPressed: () => _showDeleteDialog(context, ref, room),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _specIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.home_outlined, color: AppTheme.textHint, size: 32),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    HostRoomItem room,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xác nhận xóa',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa phòng "${room.name}"?',
          style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(hostRoomsProvider.notifier).deleteRoom(room.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: themeColor,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    Color bg = AppTheme.success.withValues(alpha: 0.12);
    Color fg = AppTheme.success;
    String label = 'Hoạt động';

    if (normalized.contains('INACTIVE') || normalized.contains('DISABLE')) {
      bg = AppTheme.textSecondary.withValues(alpha: 0.12);
      fg = AppTheme.textSecondary;
      label = 'Tạm ngưng';
    } else if (normalized.contains('PENDING')) {
      bg = const Color(0xFFFFB74D).withValues(alpha: 0.12);
      fg = const Color(0xFFFFB74D);
      label = 'Chờ duyệt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
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
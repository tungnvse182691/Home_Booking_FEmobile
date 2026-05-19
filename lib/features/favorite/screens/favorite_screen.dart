import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/favorite_provider.dart';
import '../../rooms/providers/room_provider.dart';
import '../../rooms/widgets/room_card.dart';
import '../../rooms/widgets/skeleton_room_card.dart';
import '../../../utils/app_theme.dart';

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteProvider);
    final favorites = state.favorites;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Phòng yêu thích ${favorites.isNotEmpty ? "(${favorites.length})" : ""}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(favoriteProvider.notifier).fetchFavorites(),
        child: _buildContent(context, ref, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, FavoriteState state) {
    if (state.isLoading && state.favorites.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => const SkeletonRoomCard(),
      );
    }

    if (state.favorites.isEmpty) {
      final roomState = ref.watch(roomNotifierProvider);
      final suggestedRooms = roomState.rooms.take(4).toList();

      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(Icons.favorite_border, size: 100, color: Colors.grey[300]),
                const SizedBox(height: 24),
                const Text(
                  'Danh sách yêu thích trống',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lưu lại những chỗ nghỉ mà bạn yêu thích\nđể xem lại sau này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Khám phá ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 60),
                if (suggestedRooms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gợi ý cho bạn',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('Xem thêm', style: TextStyle(color: AppTheme.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          if (suggestedRooms.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final room = suggestedRooms[index];
                    return RoomCard(
                      room: room,
                      isFavorite: false,
                      onTap: () => context.push('/room-detail/${room.id}'),
                      onFavoriteToggle: () => ref.read(favoriteProvider.notifier).toggleFavorite(room),
                    );
                  },
                  childCount: suggestedRooms.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6, // Điều chỉnh cho phù hợp với RoomCard trong grid
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.favorites.length,
      itemBuilder: (context, index) {
        final room = state.favorites[index];
        return RoomCard(
          room: room,
          isFavorite: true, // Chắc chắn là true vì ở trong màn hình Favorite
          onTap: () => context.push('/room-detail/${room.id}'),
          onFavoriteToggle: () => _showRemoveDialog(context, ref, room),
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref, dynamic room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi yêu thích?'),
        content: const Text('Bạn có chắc muốn bỏ phòng này khỏi danh sách yêu thích?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(favoriteProvider.notifier).removeFromFavorite(room.id);
              Navigator.pop(context);
            },
            child: const Text('Xác nhận', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

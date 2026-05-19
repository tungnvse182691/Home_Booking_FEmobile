import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../providers/history_provider.dart';
import '../models/booking_history_model.dart';
import '../widgets/booking_item_card.dart';
import '../../../utils/app_theme.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    
    final upcoming = historyState.bookings.where((b) => b.status == BookingStatus.CONFIRMED).toList();
    final completed = historyState.bookings.where((b) => b.status == BookingStatus.COMPLETED).toList();
    final canceled = historyState.bookings.where((b) => b.status == BookingStatus.CANCELED).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Lịch sử đặt phòng', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            tabs: [
              _buildTab('Sắp đi', upcoming.length),
              _buildTab('Hoàn thành', completed.length),
              _buildTab('Đã hủy', canceled.length),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingList(context, ref, upcoming, 'Bạn chưa có chuyến đi nào', true),
            _buildBookingList(context, ref, completed, 'Chưa có chuyến đi nào hoàn thành', false),
            _buildBookingList(context, ref, canceled, 'Không có đặt phòng nào bị hủy', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, WidgetRef ref, List<BookingHistoryModel> list, String emptyMsg, bool showExplore) {
    final historyState = ref.watch(historyProvider);

    if (historyState.isLoading) {
      return _buildShimmerLoading();
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
            if (showExplore) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, elevation: 0),
                child: const Text('Khám phá ngay', style: TextStyle(color: Colors.white)),
              ),
            ]
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(historyProvider.notifier).fetchHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) => BookingItemCard(booking: list[index]),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 180,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

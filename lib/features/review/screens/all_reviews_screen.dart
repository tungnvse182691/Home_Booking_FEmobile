import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_summary.dart';
import '../providers/review_provider.dart';
import '../../../utils/app_theme.dart';

class AllReviewsScreen extends ConsumerStatefulWidget {
  final String roomId;

  const AllReviewsScreen({super.key, required this.roomId});

  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  String _selectedFilter = "Tất cả";
  final List<String> _filters = ["Tất cả", "5 ⭐", "4 ⭐", "3 ⭐", "Có ảnh"];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reviewProvider.notifier).fetchRoomReviews(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${state.reviews.length} đánh giá', style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(reviewProvider.notifier).fetchRoomReviews(widget.roomId),
        child: Column(
          children: [
            // Filter
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedFilter = filter),
                      selectedColor: AppTheme.textPrimary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      backgroundColor: Colors.grey[100],
                    ),
                  );
                },
              ),
            ),
            
            Expanded(
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.reviews.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: RatingSummary(overallRating: 4.8, totalReviews: state.reviews.length),
                        );
                      }
                      return ReviewCard(review: state.reviews[index - 1]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

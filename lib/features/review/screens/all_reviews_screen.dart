import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text(
          '${state.reviews.length} đánh giá',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                      selectedColor: AppTheme.primary,
                      showCheckmark: false,
                      labelStyle: GoogleFonts.dmSans(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: const Color(0xFFF3F4F6),
                      shape: const StadiumBorder(side: BorderSide.none),
                    ),
                  );
                },
              ),
            ),
            
            Expanded(
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : AnimationLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.reviews.length + 1,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: index == 0
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                                      child: RatingSummary(
                                        rating: 4.8,
                                        totalReviews: state.reviews.length,
                                      ),
                                    )
                                  : ReviewCard(review: state.reviews[index - 1]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

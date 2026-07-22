import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_summary.dart';
import '../providers/review_provider.dart';
import '../../../utils/app_theme.dart';

/// Màn hình Hiển thị toàn bộ Đánh giá của một phòng Homestay (dành cho Khách xem)
class AllReviewsScreen extends ConsumerStatefulWidget {
  final String roomId; // ID của phòng Homestay cần xem đánh giá

  const AllReviewsScreen({super.key, required this.roomId});

  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  // Bộ lọc đánh giá mặc định
  String _selectedFilter = "Tất cả";
  final List<String> _filters = ["Tất cả", "5 ⭐", "4 ⭐", "3 ⭐", "Có ảnh"];

  @override
  void initState() {
    super.initState();
    // Khởi tạo tải danh sách đánh giá của phòng từ API backend khi màn hình được tạo
    Future.microtask(() => ref.read(reviewProvider.notifier).fetchRoomReviews(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    // Lọc danh sách bài đánh giá theo tiêu chí số sao được chọn (5 sao, 4 sao, 3 sao...)
    final filteredReviews = state.reviews.where((review) {
      if (_selectedFilter == "Tất cả") return true;
      if (_selectedFilter == "5 ⭐") return review.rating.round() == 5;
      if (_selectedFilter == "4 ⭐") return review.rating.round() == 4;
      if (_selectedFilter == "3 ⭐") return review.rating.round() == 3;
      if (_selectedFilter == "Có ảnh") return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Đánh giá (${state.reviews.length})',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(reviewProvider.notifier).fetchRoomReviews(widget.roomId),
        child: Column(

          children: [
            // Filter
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 8),
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
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (filter.contains('⭐')) ...[
                            Text(
                              filter.replaceAll(' ⭐', ''),
                              style: GoogleFonts.dmSans(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.amber,
                            ),
                          ] else ...[
                            Text(
                              filter,
                              style: GoogleFonts.dmSans(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (v) {
                        if (v) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                      selectedColor: AppTheme.primary,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : const Color(0xFFEEEEEE),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
                      itemCount: filteredReviews.isEmpty ? 2 : filteredReviews.length + 1,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: index == 0
                                  ? Container(
                                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFEEEEEE),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: RatingSummary(
                                        reviews: state.reviews,
                                      ),
                                    )
                                  : (filteredReviews.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.rate_review_outlined,
                                                  size: 48,
                                                  color: AppTheme.textHint,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Không có đánh giá nào phù hợp',
                                                  style: GoogleFonts.dmSans(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ReviewCard(review: filteredReviews[index - 1])),
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

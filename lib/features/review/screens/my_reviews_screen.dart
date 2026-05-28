import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/review_model.dart';
import '../providers/review_provider.dart';
import '../screens/edit_review_screen.dart';
import '../../../utils/app_theme.dart';

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reviewProvider.notifier).fetchMyReviews());
  }

  Future<void> _confirmDelete(BuildContext context, ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(reviewProvider.notifier).deleteReview(review.reviewId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Đã xóa đánh giá' : 'Xóa thất bại, vui lòng thử lại')),
    );
  }

  Future<void> _openEdit(BuildContext context, ReviewModel review) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditReviewScreen(review: review)),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá đã được cập nhật')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đánh giá của tôi', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(reviewProvider.notifier).fetchMyReviews(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.reviews.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Bạn chưa có đánh giá nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.reviews.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final review = state.reviews[index];
                      return _MyReviewCard(
                        review: review,
                        onEdit: () => _openEdit(context, review),
                        onDelete: () => _confirmDelete(context, review),
                      );
                    },
                  ),
      ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyReviewCard({
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ten phong
          if (review.roomName != null && review.roomName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Thumbnail phong
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: review.roomThumbnailUrl != null && review.roomThumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: review.roomThumbnailUrl!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: Colors.grey[200],
                              child: const Icon(Icons.home, color: Colors.grey, size: 24),
                            ),
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.home, color: Colors.grey, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.roomName!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đã đánh giá ngày ${DateFormat('dd/MM/yyyy').format(review.createdAt)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Edit + Delete buttons
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                    tooltip: 'Sửa đánh giá',
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'Xóa đánh giá',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          else
            // Fallback neu khong co ten phong: hien thi header don gian
            Row(
              children: [
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  )),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(review.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

          // Stars (khi co ten phong thi hien o day)
          if (review.roomName != null && review.roomName!.isNotEmpty)
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                )),
                const SizedBox(width: 8),
                Text(
                  _ratingLabel(review.rating),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(review.comment!, style: const TextStyle(height: 1.5, color: Colors.black87)),

          // Tags
          if (review.tags != null && review.tags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: review.tags!.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
              )).toList(),
            ),
          ],

          // Sub-ratings
          if (review.cleanliness != null) ...[
            const SizedBox(height: 8),
            _SubRatingRow(label: 'Vệ sinh', value: review.cleanliness!),
            _SubRatingRow(label: 'Vị trí', value: review.location ?? 0),
            _SubRatingRow(label: 'Dịch vụ', value: review.service ?? 0),
            _SubRatingRow(label: 'Giá trị', value: review.value ?? 0),
          ],
        ],
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating <= 1) return 'Rất tệ';
    if (rating <= 2) return 'Tệ';
    if (rating <= 3) return 'Bình thường';
    if (rating <= 4) return 'Tốt';
    return 'Xuất sắc';
  }
}

class _SubRatingRow extends StatelessWidget {
  final String label;
  final double value;

  const _SubRatingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const SizedBox(width: 8),
          Row(
            children: List.generate(5, (i) => Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 14,
            )),
          ),
        ],
      ),
    );
  }
}

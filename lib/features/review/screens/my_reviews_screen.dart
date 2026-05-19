import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/review_model.dart';
import '../widgets/review_card.dart';
import '../../../utils/app_theme.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Giả lập dữ liệu đánh giá của tôi
    final List<ReviewModel> myReviews = [
      ReviewModel(
        id: '1',
        bookingId: 'BK123457',
        roomId: '2',
        userName: 'Nguyễn Văn A',
        overallRating: 5.0,
        comment: 'Tuyệt vời! Phòng rất đẹp và gần biển. Sẽ quay lại lần sau.',
        quickTags: ['Sạch sẽ', 'Thoải mái'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        images: ['https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&q=80'],
      ),
      ReviewModel(
        id: '2',
        bookingId: 'BK123450',
        roomId: '5',
        userName: 'Nguyễn Văn A',
        overallRating: 4.0,
        comment: 'Vị trí thuận lợi, phòng sạch sẽ nhưng hơi ồn vào ban đêm.',
        quickTags: ['Vị trí tốt'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đánh giá của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: myReviews.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: myReviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => ReviewCard(review: myReviews[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có đánh giá nào',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

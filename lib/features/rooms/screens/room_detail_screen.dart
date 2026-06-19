import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/room_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/amenity_grid.dart';
import '../widgets/sticky_booking_footer.dart';
import '../../review/widgets/rating_summary.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../review/models/review_model.dart';
import '../../../utils/app_theme.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final reviewsAsync = ref.watch(roomReviewsProvider(roomId));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final favoriteState = ref.watch(favoriteProvider);
    final user = ref.watch(authStateProvider);

    return roomAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Lỗi: $err')),
      ),
      data: (room) => Scaffold(
        appBar: AppBar(
          title: Text(
            room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          elevation: 0,
          actions: [
            if (user?.role == 'CUSTOMER')
              IconButton(
                icon: Icon(
                  favoriteState.favorites.any((item) => item.roomId == roomId)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: favoriteState.favorites.any((item) => item.roomId == roomId)
                      ? Colors.red
                      : null,
                ),
                onPressed: () async {
                  if (user == null) {
                    context.push('/login');
                    return;
                  }
                  await ref.read(favoriteProvider.notifier).toggleFavorite(roomId);
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'room_image_${room.roomId}',
                        child: ImageCarousel(images: room.images),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${room.rating} • ${room.reviewCount} đánh giá',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '•',
                                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
                                ),
                                Text(
                                  'Tối đa ${room.maxGuests} khách',
                                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 20),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    room.address.isNotEmpty ? room.address : room.city,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${currencyFormat.format(room.pricePerNight)} / đêm',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Divider(height: 32),
                            Text(
                              'Tiện ích có sẵn',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AmenityGrid(amenities: room.amenityNames),
                            const Divider(height: 32),
                            Text(
                              'Mô tả phòng',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              room.description,
                              style: GoogleFonts.dmSans(
                                height: 1.5,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Divider(height: 32),
                            if (user?.role == 'CUSTOMER')
                              _buildReviewsSection(
                                context,
                                ref,
                                reviewsAsync,
                                room.rating,
                                room.reviewCount,
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (user?.role == 'CUSTOMER') StickyBookingFooter(room: room),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ReviewModel>> reviewsAsync,
    double rating,
    int count,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đánh giá từ khách hàng',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/all-reviews', extra: roomId),
              child: Text(
                'Xem tất cả',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Không thể tải đánh giá: $err'),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Text(
                'Chưa có đánh giá nào.',
                style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
              );
            }
            final topReviews = reviews.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingSummary(reviews: reviews),
                const SizedBox(height: 24),
                ...topReviews.map((review) => _buildReviewItem(review)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                    ? (review.avatarUrl!.startsWith('http')
                        ? NetworkImage(review.avatarUrl!)
                        : FileImage(File(review.avatarUrl!)) as ImageProvider)
                    : null,
                child: review.avatarUrl == null || review.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.createdAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: index < review.rating ? Colors.amber : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../providers/room_provider.dart';
import '../widgets/image_carousel.dart';
import '../widgets/amenity_grid.dart';
import '../widgets/host_info_card.dart';
import '../widgets/sticky_booking_footer.dart';
import '../../review/widgets/rating_summary.dart';
import '../../../utils/app_theme.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  Widget _buildMiniReview(String name, String comment, int rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (index) => Icon(
                  Icons.star, 
                  size: 12, 
                  color: index < rating ? Colors.amber : Colors.grey[300]
                )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return roomAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Lỗi: $err'))),
      data: (room) => Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carousel Ảnh
                    ImageCarousel(images: room.images),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên và Rating
                          Text(
                            room.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${room.rating} • ${room.reviews} đánh giá',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  room.location,
                                  style: const TextStyle(decoration: TextDecoration.underline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${currencyFormat.format(room.price)} / đêm',
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 32),

                          // Tiện ích
                          const Text(
                            'Tiện ích có sẵn',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          AmenityGrid(amenities: room.amenities),
                          const Divider(height: 32),

                          // Mô tả
                          const Text(
                            'Mô tả phòng',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            room.description,
                            style: const TextStyle(height: 1.5, color: Colors.black87),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Xem thêm', style: TextStyle(color: AppTheme.primary)),
                          ),
                          const Divider(height: 32),

                          // Vị trí trên bản đồ
                          const Text(
                            'Vị trí',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(room.lat, room.lng),
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.home_booking',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(room.lat, room.lng),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.location_on, color: AppTheme.primary, size: 40),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 32),

                          // Đánh giá từ khách hàng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Đánh giá từ khách hàng',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () => context.push('/all-reviews', extra: roomId),
                                child: const Text('Xem tất cả', style: TextStyle(color: AppTheme.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RatingSummary(overallRating: room.rating, totalReviews: room.reviews),
                          const SizedBox(height: 24),
                          // Hiển thị 2 review mẫu
                          _buildMiniReview('Nguyễn Thu Trang', 'Phòng rất đẹp, sạch sẽ. Chủ nhà hỗ trợ nhiệt tình.', 5),
                          _buildMiniReview('Trần Văn Bình', 'Vị trí thuận lợi, gần trung tâm.', 4),
                          const Divider(height: 32),

                          // Thông tin chủ nhà
                          if (room.host != null) HostInfoCard(host: room.host!),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            StickyBookingFooter(room: room),
          ],
        ),
      ),
    );
  }
}

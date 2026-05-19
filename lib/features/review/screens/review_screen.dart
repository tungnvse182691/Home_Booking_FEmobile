import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/star_rating_input.dart';
import '../widgets/rating_criteria_row.dart';
import '../widgets/quick_tags_selector.dart';
import '../providers/review_provider.dart';
import '../../../utils/app_theme.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String roomId;
  final String roomName;
  final String? thumbnailUrl;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.roomId,
    required this.roomName,
    this.thumbnailUrl,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _overallRating = 0;
  double _cleanliness = 5;
  double _location = 5;
  double _service = 5;
  double _value = 5;
  List<String> _selectedTags = [];
  final _commentController = TextEditingController();
  List<XFile> _images = [];

  final List<String> _availableTags = [
    "Sạch sẽ", "View đẹp", "Chủ nhà thân thiện",
    "Vị trí tốt", "Yên tĩnh", "Đáng tiền",
    "Tiện nghi đầy đủ", "Dễ tìm"
  ];

  String get _ratingLabel {
    if (_overallRating == 0) return "";
    if (_overallRating <= 1) return "Rất tệ";
    if (_overallRating <= 2) return "Tệ";
    if (_overallRating <= 3) return "Bình thường";
    if (_overallRating <= 4) return "Tốt";
    return "Xuất sắc";
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đánh giá phòng', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin phòng
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.thumbnailUrl != null
                          ? CachedNetworkImage(imageUrl: widget.thumbnailUrl!, width: 70, height: 70, fit: BoxFit.cover)
                          : Container(color: Colors.grey[200], width: 70, height: 70),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Hoàn thành tháng 06/2025', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Rating tổng quan
                const Center(child: Text('Trải nghiệm của bạn như thế nào?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(height: 16),
                StarRatingInput(
                  rating: _overallRating,
                  onRatingChanged: (val) => setState(() => _overallRating = val),
                ),
                if (_overallRating > 0)
                  Center(child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_ratingLabel, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  )),
                
                const Divider(height: 48),
                
                // Tiêu chí chi tiết
                const Text('Đánh giá chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                RatingCriteriaRow(label: 'Vệ sinh', rating: _cleanliness, onRatingChanged: (v) => setState(() => _cleanliness = v)),
                RatingCriteriaRow(label: 'Vị trí', rating: _location, onRatingChanged: (v) => setState(() => _location = v)),
                RatingCriteriaRow(label: 'Dịch vụ', rating: _service, onRatingChanged: (v) => setState(() => _service = v)),
                RatingCriteriaRow(label: 'Giá trị', rating: _value, onRatingChanged: (v) => setState(() => _value = v)),
                
                const Divider(height: 48),

                // Tags
                const Text('Điều bạn thích nhất?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                QuickTagsSelector(
                  availableTags: _availableTags,
                  selectedTags: _selectedTags,
                  onToggle: (tag) => setState(() => _selectedTags.contains(tag) ? _selectedTags.remove(tag) : _selectedTags.add(tag)),
                ),

                const Divider(height: 48),

                // Nhận xét
                const Text('Nhận xét chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ trải nghiệm của bạn để giúp những du khách khác...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),

                const SizedBox(height: 24),

                // Upload ảnh
                const Text('Thêm hình ảnh (không bắt buộc)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length < 3 ? _images.length + 1 : 3,
                    itemBuilder: (context, index) {
                      if (index == _images.length && _images.length < 3) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primary),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: FileImage(File(_images[index].path)), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4, right: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(index)),
                              child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          
          // Footer
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _overallRating == 0 || state.isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: state.isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Gửi đánh giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _images = [..._images, ...images].take(3).toList();
      });
    }
  }

  Future<void> _handleSubmit() async {
    final success = await ref.read(reviewProvider.notifier).submitReview(
      bookingId: widget.bookingId,
      roomId: widget.roomId,
      overallRating: _overallRating,
      cleanliness: _cleanliness,
      location: _location,
      service: _service,
      value: _value,
      tags: _selectedTags,
      comment: _commentController.text,
      images: _images.map((i) => i.path).toList(),
    );

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cảm ơn bạn! 🙏'),
          content: const Text('Đánh giá của bạn đã được ghi lại và sẽ giúp ích rất nhiều cho cộng đồng du khách.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
                Navigator.pop(context, true); // Quay về HistoryScreen với kết quả thành công
              },
              child: const Text('Đóng', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }
}

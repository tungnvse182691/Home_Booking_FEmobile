import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_provider.dart';
import '../models/review_model.dart';
import '../../../utils/app_theme.dart';

/// Màn hình Chỉnh sửa bài Đánh giá đã gửi của Khách hàng
class EditReviewScreen extends ConsumerStatefulWidget {
  final ReviewModel review; // Bài đánh giá ban đầu cần chỉnh sửa

  const EditReviewScreen({super.key, required this.review});

  @override
  ConsumerState<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends ConsumerState<EditReviewScreen> {
  late double _rating;                       // Số sao tổng thể (1 - 5)
  late double _cleanliness;                  // Số sao Độ sạch sẽ
  late double _location;                     // Số sao Vị trí
  late double _service;                      // Số sao Dịch vụ & Phục vụ
  late double _value;                        // Số sao Giá trị tương xứng
  late List<String> _selectedTags;           // Các thẻ Tag đánh giá nhanh đã chọn
  late TextEditingController _commentController; // Bộ điều khiển nội dung nhận xét bằng văn bản

  // Danh sách gợi ý thẻ đánh giá nhanh
  final List<String> _availableTags = [
    'Sạch sẽ', 'View đẹp', 'Chủ nhà thân thiện',
    'Vị trí tốt', 'Yên tĩnh', 'Đáng tiền',
    'Tiện nghi đầy đủ', 'Dễ tìm',
  ];

  @override
  void initState() {
    super.initState();
    // Nạp dữ liệu đánh giá cũ vào các biến trạng thái
    _rating = widget.review.rating;
    _cleanliness = widget.review.cleanliness ?? 5;
    _location = widget.review.location ?? 5;
    _service = widget.review.service ?? 5;
    _value = widget.review.value ?? 5;
    _selectedTags = List<String>.from(widget.review.tags ?? []);
    _commentController = TextEditingController(text: widget.review.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }


  Widget _buildStarRow(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          ...List.generate(5, (i) {
            return GestureDetector(
              onTap: () => onChanged((i + 1).toDouble()),
              child: Icon(
                i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 28,
              ),
            );
          }),
          const SizedBox(width: 8),
          Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá')),
      );
      return;
    }

    final success = await ref.read(reviewProvider.notifier).updateReview(
      reviewId: widget.review.reviewId,
      rating: _rating,
      cleanliness: _cleanliness,
      location: _location,
      service: _service,
      value: _value,
      tags: _selectedTags,
      comment: _commentController.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật đánh giá thành công')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thất bại, vui lòng thử lại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sửa đánh giá', style: TextStyle(color: AppTheme.textPrimary)),
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ten phong (neu co)
                if (widget.review.roomName != null && widget.review.roomName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      widget.review.roomName!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                // Danh gia tong quan
                const Text('Đánh giá tổng quan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = (i + 1).toDouble()),
                      child: Icon(
                        i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),

                const Divider(height: 40),

                // Tieu chi chi tiet
                const Text('Đánh giá chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildStarRow('Vệ sinh', _cleanliness, (v) => setState(() => _cleanliness = v)),
                _buildStarRow('Vị trí', _location, (v) => setState(() => _location = v)),
                _buildStarRow('Dịch vụ', _service, (v) => setState(() => _service = v)),
                _buildStarRow('Giá trị', _value, (v) => setState(() => _value = v)),

                const Divider(height: 40),

                // Tags
                const Text('Điều bạn thích nhất?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        selected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                      }),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppTheme.primary,
                    );
                  }).toList(),
                ),

                const Divider(height: 40),

                // Nhan xet
                const Text('Nhận xét chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ trải nghiệm của bạn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),

          // Footer button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

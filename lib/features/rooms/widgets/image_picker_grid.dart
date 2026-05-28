import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/app_theme.dart';

/// Grid hiển thị ảnh — hỗ trợ cả ảnh URL (từ server) và ảnh local (XFile).
/// - [existingUrls]: danh sách URL ảnh đã có trên server
/// - [newImages]: danh sách ảnh mới chọn từ thiết bị
/// - [onPick]: callback khi ấn nút thêm ảnh
/// - [onRemoveUrl]: callback xóa ảnh URL (index trong existingUrls)
/// - [onRemoveNew]: callback xóa ảnh mới (index trong newImages)
class ImagePickerGrid extends StatelessWidget {
  final List<XFile> images;
  final List<String> existingUrls;
  final VoidCallback onPick;
  final Function(int) onRemove;
  final Function(int)? onRemoveUrl;

  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onPick,
    required this.onRemove,
    this.existingUrls = const [],
    this.onRemoveUrl,
  });

  @override
  Widget build(BuildContext context) {
    final totalExisting = existingUrls.length;
    final totalNew = images.length;
    final totalImages = totalExisting + totalNew;
    final maxImages = 5;
    final showAddButton = totalImages < maxImages;
    final itemCount = totalImages + (showAddButton ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Nút thêm ảnh
        if (index == totalImages && showAddButton) {
          return GestureDetector(
            onTap: onPick,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppTheme.primary,
              ),
            ),
          );
        }

        // Ảnh URL từ server
        if (index < totalExisting) {
          final url = existingUrls[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemoveUrl?.call(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Ảnh mới từ thiết bị
        final newIndex = index - totalExisting;
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(images[newIndex].path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(newIndex),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

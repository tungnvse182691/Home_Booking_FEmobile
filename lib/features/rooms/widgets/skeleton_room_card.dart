import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonRoomCard extends StatelessWidget {
  const SkeletonRoomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 20, width: 200, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 16, width: 150, color: Colors.white),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 20, width: 100, color: Colors.white),
                Container(height: 20, width: 60, color: Colors.white),
              ],
            )
          ],
        ),
      ),
    );
  }
}

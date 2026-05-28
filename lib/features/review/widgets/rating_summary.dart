import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class RatingSummary extends StatelessWidget {
  final double rating;
  final int totalReviews;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rating.toString(),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating.floor() ? Icons.star_rounded : Icons.star_half_rounded,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text('($totalReviews đánh giá)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            children: [
              _buildProgressRow('Vệ sinh', 4.9),
              _buildProgressRow('Vị trí', 4.6),
              _buildProgressRow('Dịch vụ', 4.8),
              _buildProgressRow('Giá trị', 4.7),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: score / 5,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(score.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

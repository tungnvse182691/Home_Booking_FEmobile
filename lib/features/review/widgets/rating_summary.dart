import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/review_model.dart';
import '../../../utils/app_theme.dart';

class RatingSummary extends StatelessWidget {
  final List<ReviewModel> reviews;

  const RatingSummary({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    final totalReviews = reviews.length;
    final avgRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

    double sumCleanliness = 0;
    double sumLocation = 0;
    double sumService = 0;
    double sumValue = 0;
    int countCleanliness = 0;
    int countLocation = 0;
    int countService = 0;
    int countValue = 0;

    for (final r in reviews) {
      if (r.cleanliness != null) {
        sumCleanliness += r.cleanliness!;
        countCleanliness++;
      }
      if (r.location != null) {
        sumLocation += r.location!;
        countLocation++;
      }
      if (r.service != null) {
        sumService += r.service!;
        countService++;
      }
      if (r.value != null) {
        sumValue += r.value!;
        countValue++;
      }
    }

    final avgCleanliness = countCleanliness > 0 ? sumCleanliness / countCleanliness : avgRating;
    final avgLocation = countLocation > 0 ? sumLocation / countLocation : avgRating;
    final avgService = countService > 0 ? sumService / countService : avgRating;
    final avgValue = countValue > 0 ? sumValue / countValue : avgRating;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              avgRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Row(
              children: List.generate(5, (index) {
                if (index < avgRating.floor()) {
                  return const Icon(Icons.star_rounded, color: Colors.amber, size: 20);
                } else if (index < avgRating && avgRating - index >= 0.25) {
                  return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 20);
                } else {
                  return const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 20);
                }
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '($totalReviews đánh giá)',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            children: [
              _buildProgressRow('Vệ sinh', avgCleanliness),
              _buildProgressRow('Vị trí', avgLocation),
              _buildProgressRow('Dịch vụ', avgService),
              _buildProgressRow('Giá trị', avgValue),
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
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: score / 5,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

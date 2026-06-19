import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/review_model.dart';
import '../../../utils/app_theme.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage:
                      review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                      ? (review.avatarUrl!.startsWith('http')
                            ? NetworkImage(review.avatarUrl!)
                            : FileImage(File(review.avatarUrl!)) as ImageProvider)
                      : null,
                  child: review.avatarUrl == null || review.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
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
                        DateFormat('MM/yyyy').format(review.createdAt),
                        style: GoogleFonts.dmSans(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    if (index < review.rating.floor()) {
                      return const Icon(Icons.star_rounded, color: Colors.amber, size: 16);
                    } else if (index < review.rating && review.rating - index >= 0.25) {
                      return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 16);
                    } else {
                      return const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 16);
                    }
                  }),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: GoogleFonts.dmSans(
                  height: 1.5,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

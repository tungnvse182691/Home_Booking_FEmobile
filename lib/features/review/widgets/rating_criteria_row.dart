import 'package:flutter/material.dart';

class RatingCriteriaRow extends StatelessWidget {
  final String label;
  final double rating;
  final Function(double) onRatingChanged;

  const RatingCriteriaRow({
    super.key,
    required this.label,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= rating;
              return GestureDetector(
                onTap: () => onRatingChanged(starIndex.toDouble()),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? Colors.amber : Colors.grey[300],
                  size: 24,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  final double rating;
  final Function(double) onRatingChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= rating;
        
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 100),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: isSelected ? scale : 1.0,
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : Colors.grey[300],
                    size: size,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

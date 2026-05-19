import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class PriceMarker extends StatelessWidget {
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  const PriceMarker({
    super.key,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format giá gọn: 950000 -> 950k
    final String priceText = price >= 1000000 
        ? '${(price / 1000000).toStringAsFixed(1)}tr'
        : '${(price / 1000).toInt()}k';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Center(
          child: Text(
            priceText,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';

class AmenityGrid extends StatelessWidget {
  final List<String> amenities;

  const AmenityGrid({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) {
        IconData icon = Icons.check_circle_outline_rounded;
        if (a == 'Wifi') icon = Icons.wifi_rounded;
        if (a == 'Bếp') icon = Icons.kitchen_rounded;
        if (a == 'Điều hòa') icon = Icons.ac_unit_rounded;
        if (a == 'Bể bơi') icon = Icons.pool_rounded;
        if (a == 'Máy giặt') icon = Icons.local_laundry_service_rounded;
        if (a == 'Tivi') icon = Icons.tv_rounded;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                a,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

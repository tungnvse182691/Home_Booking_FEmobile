import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class AmenityGrid extends StatelessWidget {
  final List<String> amenities;

  const AmenityGrid({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 40,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        final a = amenities[index];
        IconData icon = Icons.check_circle_outline;
        if (a == 'Wifi') icon = Icons.wifi;
        if (a == 'Bếp') icon = Icons.kitchen;
        if (a == 'Điều hòa') icon = Icons.ac_unit;
        if (a == 'Bể bơi') icon = Icons.pool;
        if (a == 'Máy giặt') icon = Icons.local_laundry_service;
        if (a == 'Tivi') icon = Icons.tv;

        return Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(a, style: const TextStyle(fontSize: 14)),
          ],
        );
      },
    );
  }
}

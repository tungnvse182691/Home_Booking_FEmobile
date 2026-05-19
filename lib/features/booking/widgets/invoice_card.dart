import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/app_theme.dart';

class InvoiceCard extends StatelessWidget {
  final String roomName;
  final String? thumbnailUrl;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final double totalAmount;
  final double pricePerNight;

  const InvoiceCard({
    super.key,
    required this.roomName,
    this.thumbnailUrl,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.totalAmount,
    required this.pricePerNight,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: thumbnailUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[200], width: 80, height: 80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roomName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text('TP. Hồ Chí Minh', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildRow('Check-in', dateFormat.format(checkIn)),
            const SizedBox(height: 8),
            _buildRow('Check-out', dateFormat.format(checkOut)),
            const SizedBox(height: 8),
            _buildRow('Số đêm', '$nights đêm'),
            const SizedBox(height: 8),
            _buildRow('Giá/đêm', currencyFormat.format(pricePerNight)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TỔNG CỘNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  currencyFormat.format(totalAmount),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

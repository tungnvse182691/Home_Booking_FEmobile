import 'package:flutter/material.dart';
import '../models/booking_history_model.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.PENDING:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        text = 'Chờ xác nhận';
        break;
      case BookingStatus.CONFIRMED:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        text = 'Sắp đi';
        break;
      case BookingStatus.COMPLETED:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        text = 'Hoàn thành';
        break;
      case BookingStatus.CANCELED:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

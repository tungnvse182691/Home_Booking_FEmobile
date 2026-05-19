import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class CancelDialog extends StatelessWidget {
  const CancelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận hủy'),
      content: const Text(
        'Bạn có chắc muốn hủy đặt phòng này? Hành động này không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            elevation: 0,
          ),
          child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

enum PaymentMethod { BANK_CARD, E_WALLET, CASH }

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final Function(PaymentMethod) onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildOption(
          'Thẻ ngân hàng',
          Icons.account_balance,
          PaymentMethod.BANK_CARD,
        ),
        _buildOption(
          'Ví điện tử',
          Icons.account_balance_wallet,
          PaymentMethod.E_WALLET,
        ),
        _buildOption(
          'Tiền mặt',
          Icons.payments_outlined,
          PaymentMethod.CASH,
        ),
      ],
    );
  }

  Widget _buildOption(String title, IconData icon, PaymentMethod value) {
    return RadioListTile<PaymentMethod>(
      value: value,
      groupValue: selected,
      onChanged: (v) => v != null ? onChanged(v) : null,
      activeColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 24),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}

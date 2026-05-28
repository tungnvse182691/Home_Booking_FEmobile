import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import 'vnpay_webview_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String bookingCode;
  final String paymentMethod;
  final double totalAmount;
  final String roomName;
  final DateTime checkIn;
  final DateTime checkOut;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.bookingCode,
    required this.paymentMethod,
    required this.totalAmount,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  Future<void> _handlePayment() async {
    final bookingId = widget.bookingId;
    final paymentMethod = widget.paymentMethod;

    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(bookingProvider.notifier);

      // Step 1: Create Payment
      final paymentResponse = await notifier.createPayment(
        PaymentRequest(bookingId: bookingId, paymentMethod: paymentMethod),
      );

      if (paymentResponse == null) throw Exception('Không thể tạo thanh toán');

      final paymentUrl = paymentResponse.paymentUrl?.trim();

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        if (!mounted) return;

        // Open payment gateway inside the app via WebView
        final result = await Navigator.of(context).push<VnPayResult>(
          MaterialPageRoute(
            builder: (_) => VnPayWebViewScreen(paymentUrl: paymentUrl),
          ),
        );

        if (!mounted) return;

        if (result != null && result.success) {
          // Payment succeeded – navigate to success screen
          context.go(
            '/booking/success',
            extra: {
              'bookingId': widget.bookingId,
              'bookingCode': widget.bookingCode,
              'paymentMethod': widget.paymentMethod,
              'totalAmount': widget.totalAmount,
              'roomName': widget.roomName,
              'checkIn': widget.checkIn,
              'checkOut': widget.checkOut,
              'transactionCode': result.transactionCode,
            },
          );
        } else {
          // Payment failed or cancelled
          final msg = result?.message ?? 'Thanh toán không thành công.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else if (mounted) {
        // Non-VNPay (CASH, etc.) – go to success directly
        context.go(
          '/booking/success',
          extra: {
            'bookingId': widget.bookingId,
            'bookingCode': widget.bookingCode,
            'paymentMethod': widget.paymentMethod,
            'totalAmount': widget.totalAmount,
            'roomName': widget.roomName,
            'checkIn': widget.checkIn,
            'checkOut': widget.checkOut,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingCode = widget.bookingCode;
    final paymentMethod = widget.paymentMethod;
    final totalAmount = widget.totalAmount;
    final isVnPay = paymentMethod == 'VNPAY';
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005BAC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF005BAC),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tóm tắt đơn hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Phòng', widget.roomName),
                  _buildInfoRow('Mã đặt phòng', bookingCode),
                  _buildInfoRow('Nhận phòng', dateFormat.format(widget.checkIn)),
                  _buildInfoRow('Trả phòng', dateFormat.format(widget.checkOut)),
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Phương thức',
                    isVnPay ? 'VNPay' : paymentMethod,
                    valueColor: isVnPay ? const Color(0xFF005BAC) : Colors.black87,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // VNPay info banner
            if (isVnPay)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF005BAC).withValues(alpha: 0.08),
                      const Color(0xFF005BAC).withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF005BAC).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: const Color(0xFF005BAC).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cổng thanh toán VNPay sẽ được mở ngay trong ứng dụng. Bạn có thể thanh toán qua thẻ ngân hàng hoặc QR code.',
                        style: TextStyle(
                          height: 1.5,
                          fontSize: 13,
                          color: Color(0xFF005BAC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isVnPay) const SizedBox(height: 20),

            // Pay button
            if (_isProcessing)
              Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF005BAC).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đang khởi tạo thanh toán...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _handlePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isVnPay ? const Color(0xFF005BAC) : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isVnPay ? Icons.account_balance : Icons.payments,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isVnPay ? 'Thanh toán qua VNPay' : 'Thanh toán ngay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

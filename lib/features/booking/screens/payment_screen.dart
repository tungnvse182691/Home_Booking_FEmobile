import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/invoice_card.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/loading_overlay.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../../utils/app_theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentScreen({super.key, required this.bookingData});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.BANK_CARD;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Xác nhận thanh toán', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TÓM TẮT ĐẶT PHÒNG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                InvoiceCard(
                  roomName: widget.bookingData['roomName'],
                  thumbnailUrl: widget.bookingData['thumbnailUrl'],
                  checkIn: widget.bookingData['checkIn'],
                  checkOut: widget.bookingData['checkOut'],
                  nights: widget.bookingData['nights'],
                  totalAmount: widget.bookingData['totalAmount'],
                  pricePerNight: widget.bookingData['pricePerNight'],
                ),
                const SizedBox(height: 32),
                PaymentMethodSelector(
                  selected: _selectedMethod,
                  onChanged: (m) => setState(() => _selectedMethod = m),
                ),
                const SizedBox(height: 24),
                const Text('GHI CHÚ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ghi chú cho host (không bắt buộc)',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Sticky Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Xác nhận thanh toán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
          
          if (state.isLoading) const LoadingOverlay(message: 'Đang xử lý thanh toán...'),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    final booking = BookingModel(
      roomId: widget.bookingData['roomId'],
      roomName: widget.bookingData['roomName'],
      checkInDate: widget.bookingData['checkIn'],
      checkOutDate: widget.bookingData['checkOut'],
      totalAmount: widget.bookingData['totalAmount'],
      paymentMethod: _selectedMethod.name,
      note: _noteController.text,
    );

    final success = await ref.read(bookingProvider.notifier).createBooking(booking);
    
    if (success && mounted) {
      context.go('/booking-success', extra: {
        'bookingId': ref.read(bookingProvider).lastBookingId,
        'roomName': widget.bookingData['roomName'],
        'checkIn': widget.bookingData['checkIn'],
        'checkOut': widget.bookingData['checkOut'],
        'totalAmount': widget.bookingData['totalAmount'],
      });
    } else if (mounted) {
      final error = ref.read(bookingProvider).error;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi đặt phòng'),
          content: Text(error ?? 'Có lỗi xảy ra, vui lòng thử lại.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
        ),
      );
    }
  }
}

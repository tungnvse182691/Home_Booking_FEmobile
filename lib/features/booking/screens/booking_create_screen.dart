import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../rooms/providers/room_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';

class BookingCreateScreen extends ConsumerStatefulWidget {
  final String roomId;
  const BookingCreateScreen({super.key, required this.roomId});

  @override
  ConsumerState<BookingCreateScreen> createState() =>
      _BookingCreateScreenState();
}

class _BookingCreateScreenState extends ConsumerState<BookingCreateScreen> {
  DateTimeRange? _dateRange;
  String _paymentMethod = 'CASH';
  final _specialRequestController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _specialRequestController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _handleConfirmBooking(String roomName) async {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày nhận/trả phòng')),
      );
      return;
    }

    final request = BookingRequest(
      roomId: widget.roomId,
      checkInDate: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
      checkOutDate: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      paymentMethod: _paymentMethod,
      specialRequest: _specialRequestController.text,
    );

    final response = await ref
        .read(bookingProvider.notifier)
        .createBooking(request);

    if (response != null && mounted) {
      context.push(
        '/booking/payment',
        extra: {
          'bookingId': response.bookingId,
          'bookingCode': response.bookingCode,
          'paymentMethod': _paymentMethod,
          'totalAmount': response.totalAmount,
          'roomName': roomName,
          'checkIn': _dateRange!.start,
          'checkOut': _dateRange!.end,
        },
      );
    } else if (mounted) {
      final error = ref.read(bookingProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Có lỗi xảy ra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final isLoading = ref.watch(bookingProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt phòng')),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (room) {
          int nights = _dateRange?.duration.inDays ?? 0;
          double totalAmount = nights * room.pricePerNight;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_currencyFormat.format(room.pricePerNight)} / đêm',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thời gian lưu trú',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dateRange == null
                              ? 'Chọn ngày nhận - trả phòng'
                              : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)} ($nights đêm)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt')),
                    DropdownMenuItem(value: 'VNPAY', child: Text('VNPAY')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Yêu cầu đặc biệt (tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _specialRequestController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Tầng cao, yên tĩnh...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(totalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (isLoading || nights == 0)
                        ? null
                        : () => _handleConfirmBooking(room.name),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Xác nhận đặt phòng'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

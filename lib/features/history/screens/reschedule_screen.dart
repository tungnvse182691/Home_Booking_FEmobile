import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../utils/app_theme.dart';

class RescheduleScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String roomId;
  final String roomName;
  final DateTime currentCheckIn;
  final DateTime currentCheckOut;
  final List<String> blockedDates;
  final double pricePerNight;

  const RescheduleScreen({
    super.key,
    required this.bookingId,
    required this.roomId,
    required this.roomName,
    required this.currentCheckIn,
    required this.currentCheckOut,
    this.blockedDates = const [],
    required this.pricePerNight,
  });

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late List<DateTime> _blockedDateTimes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Chuyển đổi blockedDates, ngoại trừ khoảng thời gian hiện tại của booking này
    _blockedDateTimes = widget.blockedDates
        .map((d) => DateTime.parse(d))
        .where((d) => d.isBefore(widget.currentCheckIn) || d.isAfter(widget.currentCheckOut))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();
  }

  bool _isBlocked(DateTime day) {
    final cleanDay = DateTime(day.year, day.month, day.day);
    return _blockedDateTimes.any((d) => isSameDay(d, cleanDay));
  }

  bool _rangeContainsBlocked(DateTime start, DateTime end) {
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      if (_isBlocked(start.add(Duration(days: i)))) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final oldNights = widget.currentCheckOut.difference(widget.currentCheckIn).inDays;
    final oldTotal = oldNights * widget.pricePerNight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đổi ngày đặt phòng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin ngày hiện tại
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ngày hiện tại:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(widget.currentCheckIn)} → ${dateFormat.format(widget.currentCheckOut)} | $oldNights đêm',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            TableCalendar(
              locale: 'vi_VN',
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.enforced,
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              enabledDayPredicate: (day) => !_isBlocked(day),
              onRangeSelected: (start, end, focusedDay) {
                if (start != null && end != null) {
                  if (_rangeContainsBlocked(start, end)) {
                    Fluttertoast.showToast(msg: "Khoảng ngày này có ngày đã được đặt");
                    setState(() {
                      _rangeStart = null;
                      _rangeEnd = null;
                    });
                    return;
                  }
                }
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                rangeHighlightColor: AppTheme.primary.withOpacity(0.1),
                rangeStartDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                rangeEndDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.3), shape: BoxShape.circle),
              ),
            ),

            if (_rangeStart != null && _rangeEnd != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Divider(),
              ),
              _buildComparison(currencyFormat, dateFormat, oldTotal),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleReschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Xác nhận đổi ngày', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              )
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(NumberFormat currency, DateFormat date, double oldTotal) {
    final newNights = _rangeEnd!.difference(_rangeStart!).inDays;
    final newTotal = newNights * widget.pricePerNight;
    final diff = newTotal - oldTotal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết thay đổi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoRow('Ngày mới', '${date.format(_rangeStart!)} - ${date.format(_rangeEnd!)}', isHighlight: true),
          _buildInfoRow('Số đêm', '$newNights đêm', isHighlight: true),
          _buildInfoRow('Tổng tiền mới', currency.format(newTotal), isHighlight: true),
          if (diff != 0)
            _buildInfoRow(
              diff > 0 ? 'Phí chênh lệch' : 'Hoàn trả',
              currency.format(diff.abs()),
              valueColor: diff > 0 ? AppTheme.primary : Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? (isHighlight ? AppTheme.textPrimary : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReschedule() async {
    setState(() => _isLoading = true);
    try {
      // PATCH /api/bookings/:id/reschedule
      // Body: { newCheckIn, newCheckOut, newTotalAmount }
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Fluttertoast.showToast(msg: 'Đổi ngày thành công!', backgroundColor: Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Lỗi: ${e.toString()}', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_theme.dart';

class BookingCalendarScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final double pricePerNight;
  final List<String> blockedDates;
  final String? thumbnailUrl;

  const BookingCalendarScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.pricePerNight,
    this.blockedDates = const [],
    this.thumbnailUrl,
  });

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  late List<DateTime> _blockedDateTimes;

  @override
  void initState() {
    super.initState();
    _blockedDateTimes = widget.blockedDates
        .map((d) => DateTime.parse(d))
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn ngày lưu trú',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.roomName,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              locale: 'vi_VN',
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.enforced,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              enabledDayPredicate: (day) => !_isBlocked(day),
              onRangeSelected: (start, end, focusedDay) {
                if (start != null && end != null) {
                  if (_rangeContainsBlocked(start, end)) {
                    Fluttertoast.showToast(
                      msg: "Khoảng ngày này có ngày đã được đặt",
                    );
                    setState(() {
                      _rangeStart = null;
                      _rangeEnd = null;
                    });
                    return;
                  }
                  if (end.difference(start).inDays < 1) {
                    Fluttertoast.showToast(msg: "Vui lòng chọn ít nhất 1 đêm");
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
                rangeHighlightColor: AppTheme.primary.withValues(alpha: 0.2),
                rangeStartDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                disabledTextStyle: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            if (_rangeStart != null && _rangeEnd != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildInfoColumn(
                            'Check-in',
                            dateFormat.format(_rangeStart!),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            'Check-out',
                            dateFormat.format(_rangeEnd!),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            'Số đêm',
                            '${_rangeEnd!.difference(_rangeStart!).inDays} dem',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currencyFormat.format(
                            _rangeEnd!.difference(_rangeStart!).inDays *
                                widget.pricePerNight,
                          ),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final nights = _rangeEnd!
                                .difference(_rangeStart!)
                                .inDays;
                            context.push(
                              '/payment',
                              extra: {
                                'roomId': widget.roomId,
                                'roomName': widget.roomName,
                                'thumbnailUrl': widget.thumbnailUrl,
                                'checkIn': _rangeStart,
                                'checkOut': _rangeEnd,
                                'nights': nights,
                                'totalAmount': nights * widget.pricePerNight,
                                'pricePerNight': widget.pricePerNight,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tiếp tục',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

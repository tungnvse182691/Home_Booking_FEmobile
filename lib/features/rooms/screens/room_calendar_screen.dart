import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_theme.dart';

class RoomCalendarScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomCalendarScreen({super.key, required this.roomId, required this.roomName});

  @override
  State<RoomCalendarScreen> createState() => _RoomCalendarScreenState();
}

class _RoomCalendarScreenState extends State<RoomCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dữ liệu giả lập
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime.now().add(const Duration(days: 2)): [
      {'type': 'BOOKING', 'name': 'Nguyễn Văn A', 'phone': '0901234567', 'nights': 2, 'total': 1200000}
    ],
    DateTime.now().add(const Duration(days: 5)): [
      {'type': 'BLOCKED', 'reason': 'Bảo trì định kỳ'}
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Lịch đặt - ${widget.roomName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _handleDayClick(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.transparent), // Tự custom marker
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                final event = events.first as Map<String, dynamic>;
                if (event['type'] == 'BOOKING') {
                  return _buildEventMarker(Colors.green);
                } else if (event['type'] == 'BLOCKED') {
                  return _buildEventMarker(Colors.grey);
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Widget _buildEventMarker(Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _legendItem(Colors.green, 'Đã có khách đặt'),
          const SizedBox(height: 8),
          _legendItem(Colors.grey, 'Ngày đã khóa'),
          const SizedBox(height: 8),
          _legendItem(AppTheme.primary, 'Hôm nay'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  void _handleDayClick(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final events = _events[normalizedDay];

    if (events != null && events.isNotEmpty) {
      final event = events.first;
      if (event['type'] == 'BOOKING') {
        _showBookingInfo(event);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ngày này đã bị khóa')));
      }
    } else {
      _showBlockDayDialog(day);
    }
  }

  void _showBookingInfo(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chi tiết đặt phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _infoRow(Icons.person_outline, 'Khách hàng', booking['name']),
            _infoRow(Icons.phone_outlined, 'Số điện thoại', booking['phone']),
            _infoRow(Icons.nights_stay_outlined, 'Số đêm', '${booking['nights']} đêm'),
            _infoRow(Icons.payments_outlined, 'Tổng tiền', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(booking['total'])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone),
                label: const Text('Liên hệ khách hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDayDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khóa ngày này?'),
        content: Text('Bạn có muốn khóa ngày ${DateFormat('dd/MM/yyyy').format(day)} không? Khách sẽ không thể đặt phòng vào ngày này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              setState(() {
                _events[_normalizeDate(day)] = [{'type': 'BLOCKED'}];
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã khóa ngày thành công')));
            },
            child: const Text('Khóa ngày', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../utils/app_theme.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _CalendarEvent {
  final String type; // 'BOOKING' | 'BLOCKED'
  final String? customerName;
  final String? phone;
  final int? nights;
  final double? total;
  final String? reason;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const _CalendarEvent({
    required this.type,
    this.customerName,
    this.phone,
    this.nights,
    this.total,
    this.reason,
    this.checkIn,
    this.checkOut,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

final _roomCalendarProvider =
    FutureProvider.family<Map<DateTime, List<_CalendarEvent>>, String>((
      ref,
      roomId,
    ) async {
      final dio = ref.read(dioProvider);

      // Fetch all bookings for this room from host endpoint
      final response = await dio.get('/api/host/bookings');
      final data = response.data;

      // BE returns: { success: true, data: { total: N, data: [...HostBookingItem] } }
      final List<dynamic> bookings;
      if (data is Map) {
        final outer = data['data'];
        if (outer is Map) {
          // { data: { total, data: [...] } }
          final inner = outer['data'] ?? outer['items'] ?? [];
          bookings = inner is List ? inner : [];
        } else if (outer is List) {
          bookings = outer;
        } else {
          bookings = [];
        }
      } else {
        bookings = [];
      }

      // Filter by roomId
      final filtered = bookings.where((b) {
        final bRoomId = (b['roomId'] ?? b['room_id'] ?? '').toString();
        return bRoomId == roomId;
      }).toList();

      final Map<DateTime, List<_CalendarEvent>> events = {};

      for (final b in filtered) {
        final status = (b['status'] ?? '').toString().toUpperCase();
        // Only show CONFIRMED and PENDING bookings
        if (status != 'CONFIRMED' && status != 'PENDING') continue;

        final checkInRaw =
            b['checkInDate'] ?? b['check_in_date'] ?? b['checkIn'];
        final checkOutRaw =
            b['checkOutDate'] ?? b['check_out_date'] ?? b['checkOut'];
        if (checkInRaw == null || checkOutRaw == null) continue;

        final checkIn = _parseDate(checkInRaw.toString());
        final checkOut = _parseDate(checkOutRaw.toString());
        if (checkIn == null || checkOut == null) continue;

        final nights =
            (b['numberOfNights'] as num?)?.toInt() ??
            checkOut.difference(checkIn).inDays;
        final total = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final customerName =
            b['customerName']?.toString() ??
            b['guestName']?.toString() ??
            'Khách';
        final phone =
            b['customerPhone']?.toString() ??
            b['phone']?.toString() ??
            'Không có';

        final event = _CalendarEvent(
          type: 'BOOKING',
          customerName: customerName,
          phone: phone,
          nights: nights,
          total: total,
          checkIn: checkIn,
          checkOut: checkOut,
        );

        // Mark every day in the booking range
        for (int i = 0; i < nights; i++) {
          final day = _normalizeDate(checkIn.add(Duration(days: i)));
          events[day] = [...(events[day] ?? []), event];
        }
      }

      return events;
    });

DateTime? _parseDate(String raw) {
  // Handles "2026-05-28", "2026-05-28T00:00:00", DateOnly formats
  try {
    if (raw.contains('T')) return DateTime.parse(raw);
    final parts = raw.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
  } catch (_) {}
  return null;
}

DateTime _normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

// ─── Screen ──────────────────────────────────────────────────────────────────

class RoomCalendarScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const RoomCalendarScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<RoomCalendarScreen> createState() => _RoomCalendarScreenState();
}

class _RoomCalendarScreenState extends ConsumerState<RoomCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Local blocked dates added by host (not yet persisted to BE)
  final Map<DateTime, List<_CalendarEvent>> _localBlocked = {};

  Map<DateTime, List<_CalendarEvent>> _mergeEvents(
    Map<DateTime, List<_CalendarEvent>> remote,
  ) {
    final merged = Map<DateTime, List<_CalendarEvent>>.from(remote);
    for (final entry in _localBlocked.entries) {
      merged[entry.key] = [...(merged[entry.key] ?? []), ...entry.value];
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(_roomCalendarProvider(widget.roomId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Lịch đặt - ${widget.roomName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () =>
                ref.invalidate(_roomCalendarProvider(widget.roomId)),
          ),
        ],
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Lỗi tải lịch: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(_roomCalendarProvider(widget.roomId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (remoteEvents) {
          final events = _mergeEvents(remoteEvents);
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 730)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _handleDayClick(selectedDay, events);
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                eventLoader: (day) => events[_normalizeDate(day)] ?? [],
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(color: Colors.transparent),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, dayEvents) {
                    if (dayEvents.isEmpty) return null;
                    final event = dayEvents.first as _CalendarEvent;
                    if (event.type == 'BOOKING') {
                      return _buildEventMarker(Colors.green);
                    } else if (event.type == 'BLOCKED') {
                      return _buildEventMarker(Colors.grey);
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildLegend(),
              if (remoteEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Chưa có booking nào cho phòng này',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
            ],
          );
        },
      ),
    );
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
          _legendItem(Colors.red, 'Hôm nay'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  void _handleDayClick(
    DateTime day,
    Map<DateTime, List<_CalendarEvent>> events,
  ) {
    final normalizedDay = _normalizeDate(day);
    final dayEvents = events[normalizedDay];

    if (dayEvents != null && dayEvents.isNotEmpty) {
      final event = dayEvents.first;
      if (event.type == 'BOOKING') {
        _showBookingInfo(event);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ngày này đã bị khóa')));
      }
    } else {
      _showBlockDayDialog(day);
    }
  }

  void _showBookingInfo(_CalendarEvent booking) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết đặt phòng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _infoRow(
              Icons.person_outline,
              'Khách hàng',
              booking.customerName ?? '-',
            ),
            _infoRow(
              Icons.phone_outlined,
              'Số điện thoại',
              booking.phone ?? '-',
            ),
            if (booking.checkIn != null)
              _infoRow(
                Icons.calendar_today_outlined,
                'Check-in',
                DateFormat('dd/MM/yyyy').format(booking.checkIn!),
              ),
            if (booking.checkOut != null)
              _infoRow(
                Icons.calendar_today_outlined,
                'Check-out',
                DateFormat('dd/MM/yyyy').format(booking.checkOut!),
              ),
            _infoRow(
              Icons.nights_stay_outlined,
              'Số đêm',
              '${booking.nights ?? 0} đêm',
            ),
            _infoRow(
              Icons.payments_outlined,
              'Tổng tiền',
              currencyFormat.format(booking.total ?? 0),
            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
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
        content: Text(
          'Bạn có muốn khóa ngày ${DateFormat('dd/MM/yyyy').format(day)} không? Khách sẽ không thể đặt phòng vào ngày này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _localBlocked[_normalizeDate(day)] = [
                  const _CalendarEvent(
                    type: 'BLOCKED',
                    reason: 'Khóa bởi host',
                  ),
                ];
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã khóa ngày thành công')),
              );
            },
            child: const Text(
              'Khóa ngày',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

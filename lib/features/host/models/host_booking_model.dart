class HostBookingItem {
  final String bookingId;
  final String bookingCode;
  final String roomId;
  final String roomName;
  final String? thumbnailUrl;
  final String customerName;
  final String? customerPhone;
  final String? customerAvatar;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  final double totalAmount;
  final String status;
  final String? specialRequest;
  final String? cancelReason;
  final DateTime createdAt;

  HostBookingItem({
    required this.bookingId,
    required this.bookingCode,
    required this.roomId,
    required this.roomName,
    this.thumbnailUrl,
    required this.customerName,
    this.customerPhone,
    this.customerAvatar,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    required this.totalAmount,
    required this.status,
    this.specialRequest,
    this.cancelReason,
    required this.createdAt,
  });

  factory HostBookingItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) {
        // DateOnly from BE: "2025-06-01" — treat as local midnight
        if (v.length == 10) return DateTime.parse('${v}T00:00:00');
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return HostBookingItem(
      bookingId: (json['bookingId'] ?? '').toString(),
      bookingCode: json['bookingCode']?.toString() ?? '',
      roomId: (json['roomId'] ?? '').toString(),
      roomName: json['roomName']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString(),
      customerAvatar: json['customerAvatar']?.toString(),
      checkInDate: parseDate(json['checkInDate']),
      checkOutDate: parseDate(json['checkOutDate']),
      numberOfNights: (json['numberOfNights'] as num?)?.toInt() ?? 1,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      specialRequest: json['specialRequest']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

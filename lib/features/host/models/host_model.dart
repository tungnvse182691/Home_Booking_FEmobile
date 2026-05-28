class HostDashboardData {
  final int totalRooms;
  final int totalBookings;
  final double totalRevenue;
  final List<RecentBooking> recentBookings;

  HostDashboardData({
    required this.totalRooms,
    required this.totalBookings,
    required this.totalRevenue,
    required this.recentBookings,
  });

  factory HostDashboardData.fromJson(Map<String, dynamic> json) => HostDashboardData(
    totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
    totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    recentBookings: (json['recentBookings'] as List? ?? [])
        .map((e) => RecentBooking.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class RecentBooking {
  final String bookingId;
  final String bookingCode;
  final String customerName;
  final String roomName;
  final double totalAmount;
  final String status;

  RecentBooking({
    required this.bookingId,
    required this.bookingCode,
    required this.customerName,
    required this.roomName,
    required this.totalAmount,
    required this.status,
  });

  factory RecentBooking.fromJson(Map<String, dynamic> json) => RecentBooking(
    bookingId: (json['bookingId'] ?? '').toString(),
    bookingCode: json['bookingCode']?.toString() ?? '',
    customerName: json['customerName']?.toString() ?? '',
    roomName: json['roomName']?.toString() ?? '',
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    status: json['status']?.toString() ?? '',
  );
}

class HostRoomItem {
  final String id;
  final String name;
  final double price;
  final String status;
  final String? thumbnailUrl;
  final double ratingAvg;
  final int reviewCount;
  final String city;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final DateTime? createdAt;

  HostRoomItem({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    this.thumbnailUrl,
    this.ratingAvg = 0.0,
    this.reviewCount = 0,
    this.city = '',
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.maxGuests = 1,
    this.createdAt,
  });
}

class RevenueReportItem {
  final String month;
  final double amount;

  RevenueReportItem({required this.month, required this.amount});

  factory RevenueReportItem.fromJson(Map<String, dynamic> json) => RevenueReportItem(
    month: json['month']?.toString() ??
        json['monthLabel']?.toString() ??
        json['period']?.toString() ??
        '',
    amount: (json['amount'] as num?)?.toDouble() ??
        (json['revenue'] as num?)?.toDouble() ??
        0.0,
  );
}

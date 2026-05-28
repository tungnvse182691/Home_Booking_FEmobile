class AdminDashboardData {
  final int totalUsers;
  final int totalRooms;
  final int totalBookings;
  final double totalRevenue;
  final double revenueThisMonth;
  final int pendingBookings;
  final int confirmedBookings;
  final int completedBookings;
  final List<AdminRecentBooking> recentBookings;

  AdminDashboardData({
    required this.totalUsers,
    required this.totalRooms,
    required this.totalBookings,
    required this.totalRevenue,
    this.revenueThisMonth = 0.0,
    this.pendingBookings = 0,
    this.confirmedBookings = 0,
    this.completedBookings = 0,
    this.recentBookings = const [],
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
        totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        revenueThisMonth: (json['revenueThisMonth'] as num?)?.toDouble() ?? 0.0,
        pendingBookings: (json['pendingBookings'] as num?)?.toInt() ?? 0,
        confirmedBookings: (json['confirmedBookings'] as num?)?.toInt() ?? 0,
        completedBookings: (json['completedBookings'] as num?)?.toInt() ?? 0,
        recentBookings: (json['recentBookings'] as List? ?? [])
            .map(
              (e) => AdminRecentBooking.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class AdminRecentBooking {
  final String bookingId;
  final String bookingCode;
  final String roomName;
  final String customerName;
  final double totalAmount;
  final String status;

  AdminRecentBooking({
    required this.bookingId,
    required this.bookingCode,
    required this.roomName,
    required this.customerName,
    required this.totalAmount,
    required this.status,
  });

  factory AdminRecentBooking.fromJson(Map<String, dynamic> json) =>
      AdminRecentBooking(
        bookingId: (json['bookingId'] ?? '').toString(),
        bookingCode: json['bookingCode']?.toString() ?? '',
        roomName: json['roomName']?.toString() ?? '',
        customerName: json['customerName']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? '',
      );
}

class AdminUserItem {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AdminUserItem({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone = '',
    required this.role,
    required this.status,
    this.avatarUrl,
    this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) => AdminUserItem(
    userId: (json['userId'] ?? json['id'] ?? '').toString(),
    fullName: json['fullName']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: json['role']?.toString() ?? 'CUSTOMER',
    status: json['status']?.toString() ?? 'ACTIVE',
    avatarUrl: json['avatarUrl']?.toString(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.tryParse(json['lastLoginAt'].toString())
        : null,
  );
}

class AdminPaymentItem {
  final String paymentId;
  final String bookingCode;
  final String customerName;
  final double amount;
  final String method;
  final String status;
  final DateTime createdAt;

  AdminPaymentItem({
    required this.paymentId,
    required this.bookingCode,
    required this.customerName,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory AdminPaymentItem.fromJson(
    Map<String, dynamic> json,
  ) => AdminPaymentItem(
    paymentId: (json['paymentId'] ?? '').toString(),
    bookingCode: json['bookingCode']?.toString() ?? '',
    // BE không trả về customerName trong payments list
    customerName:
        json['customerName']?.toString() ?? 'User #${json['userId'] ?? '?'}',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    // BE trả về 'paymentMethod' (E_WALLET, BANK_CARD, CASH...)
    method:
        json['paymentMethod']?.toString() ?? json['method']?.toString() ?? '',
    // BE trả về 'paymentStatus' (không phải 'status')
    status:
        json['paymentStatus']?.toString() ??
        json['status']?.toString() ??
        'PENDING',
    // BE trả về 'paidAt' (không phải 'createdAt')
    createdAt:
        _parseDate(json['paidAt']) ??
        _parseDate(json['createdAt']) ??
        DateTime.now(),
  );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

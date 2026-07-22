/// ============================================================================
/// MODEL DỮ LIỆU DÀNH CHO MODULE QUẢN TRỊ ADMIN (HOMESTAY BOOKING)
/// Chứa toàn bộ các Data Model chuyển đổi từ JSON API Backend cho Admin
/// ============================================================================

/// Model chứa dữ liệu Thống kê Tổng quan hiển thị trên Bảng điều khiển (Dashboard) của Admin
class AdminDashboardData {
  final int totalUsers;        // Tổng số người dùng đăng ký trên hệ thống
  final int totalRooms;        // Tổng số phòng Homestay hiện có
  final int totalBookings;     // Tổng số đơn đặt phòng đã phát sinh
  final double totalRevenue;   // Tổng doanh thu lũy kế toàn hệ thống
  final double revenueThisMonth;// Doanh thu phát sinh riêng trong tháng này
  final int pendingBookings;   // Số đơn đặt phòng đang ở trạng thái Chờ duyệt (PENDING)
  final int confirmedBookings; // Số đơn đặt phòng đã được Xác nhận (CONFIRMED)
  final int completedBookings; // Số đơn đặt phòng đã Hoàn tất lưu trú (COMPLETED)
  final List<AdminRecentBooking> recentBookings; // Danh sách các đơn đặt phòng mới nhất gần đây

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

  /// Hàm Factory chuyển đổi từ dữ liệu JSON API trả về sang đối tượng AdminDashboardData
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

/// Model hiển thị thông tin vắn tắt của một Đơn đặt phòng mới nhất trên Dashboard
class AdminRecentBooking {
  final String bookingId;   // Mã định danh đơn đặt phòng (ID)
  final String bookingCode; // Mã đơn hiển thị (VD: BK-10023)
  final String roomName;    // Tên phòng homestay được đặt
  final String customerName;// Tên khách hàng thực hiện đặt phòng
  final double totalAmount; // Tổng tiền hóa đơn đặt phòng
  final String status;      // Trạng thái đơn đặt phòng (PENDING, CONFIRMED, CANCELLED...)

  AdminRecentBooking({
    required this.bookingId,
    required this.bookingCode,
    required this.roomName,
    required this.customerName,
    required this.totalAmount,
    required this.status,
  });

  /// Factory parse JSON từ Backend cho Đơn đặt phòng gần đây
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

/// Model đại diện cho thông tin một Người dùng trong danh sách Quản lý Người dùng của Admin
class AdminUserItem {
  final String userId;        // Mã người dùng
  final String fullName;      // Họ và tên người dùng
  final String email;         // Địa chỉ Email
  final String phone;         // Số điện thoại
  final String role;          // Vai trò hệ thống: CUSTOMER (Khách), HOST (Chủ nhà), ADMIN (Quản trị)
  final String status;        // Trạng thái tài khoản: ACTIVE (Đang hoạt động), INACTIVE / LOCKED (Đã khóa)
  final String? avatarUrl;    // Đường dẫn ảnh đại diện (Avatar)
  final DateTime? createdAt;  // Ngày giờ đăng ký tài khoản
  final DateTime? lastLoginAt;// Ngày giờ đăng nhập gần đây nhất

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

  /// Factory parse dữ liệu Người dùng từ JSON API
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

/// Model đại diện cho một Giao dịch Thanh toán toàn hệ thống hiển thị trong Admin
class AdminPaymentItem {
  final String paymentId;   // Mã giao dịch thanh toán (ID)
  final String bookingCode; // Mã đơn đặt phòng tương ứng
  final String customerName;// Tên khách hàng thanh toán
  final double amount;      // Số tiền giao dịch
  final String method;      // Phương thức: VNPAY, CASH, BANK_TRANSFER, E_WALLET...
  final String status;      // Trạng thái giao dịch: SUCCESS, PENDING, FAILED
  final DateTime createdAt; // Ngày giờ thực hiện thanh toán

  AdminPaymentItem({
    required this.paymentId,
    required this.bookingCode,
    required this.customerName,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  /// Factory parse dữ liệu Giao dịch Thanh toán từ JSON Backend
  factory AdminPaymentItem.fromJson(
    Map<String, dynamic> json,
  ) => AdminPaymentItem(
    paymentId: (json['paymentId'] ?? '').toString(),
    bookingCode: json['bookingCode']?.toString() ?? '',
    // BE nếu chưa trả tên khách thì hiển thị tạm "User #ID"
    customerName:
        json['customerName']?.toString() ?? 'User #${json['userId'] ?? '?'}',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    // Lấy trường paymentMethod từ BE
    method:
        json['paymentMethod']?.toString() ?? json['method']?.toString() ?? '',
    // Lấy trường paymentStatus từ BE
    status:
        json['paymentStatus']?.toString() ??
        json['status']?.toString() ??
        'PENDING',
    // Lấy thời gian thanh toán từ paidAt hoặc createdAt
    createdAt:
        _parseDate(json['paidAt']) ??
        _parseDate(json['createdAt']) ??
        DateTime.now(),
  );

  /// Hàm tĩnh hỗ trợ ép kiểu Chuỗi ngày giờ từ API thành DateTime an toàn
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}


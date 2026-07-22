/// Model chứa các chỉ số thống kê tổng quan trên Dashboard của Host (Chủ nhà)
class HostDashboardData {
  final int totalRooms;                     // Tổng số phòng homestay của Host
  final int totalBookings;                  // Tổng số lượt đặt phòng
  final double totalRevenue;                // Tổng doanh thu đạt được (VNĐ)
  final List<RecentBooking> recentBookings; // Danh sách các đơn đặt phòng mới nhất

  HostDashboardData({
    required this.totalRooms,
    required this.totalBookings,
    required this.totalRevenue,
    required this.recentBookings,
  });

  /// Parse JSON từ API GET /api/host/dashboard
  factory HostDashboardData.fromJson(Map<String, dynamic> json) => HostDashboardData(
    totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
    totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    recentBookings: (json['recentBookings'] as List? ?? [])
        .map((e) => RecentBooking.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

/// Model hiển thị thông tin đơn đặt phòng gần đây trên Dashboard Host
class RecentBooking {
  final String bookingId;    // Mã ID đơn đặt phòng
  final String bookingCode;  // Mã code rút gọn đơn đặt
  final String customerName; // Tên khách hàng đặt phòng
  final String roomName;     // Tên phòng được đặt
  final double totalAmount;  // Tổng tiền đơn đặt phòng
  final String status;       // Trạng thái đơn (PENDING, CONFIRMED, COMPLETED, CANCELLED)

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

/// Model thông tin rút gọn về phòng Homestay thuộc quản lý của Host
class HostRoomItem {
  final String id;            // ID phòng
  final String name;          // Tên phòng Homestay
  final double price;         // Giá thuê / 1 đêm (VNĐ)
  final String status;        // Trạng thái (AVAILABLE, BOOKED, MAINTENANCE, HIDDEN)
  final String? thumbnailUrl; // Ảnh đại diện của phòng
  final double ratingAvg;     // Điểm đánh giá trung bình (ví dụ: 4.8)
  final int reviewCount;      // Tổng số lượt đánh giá
  final String city;          // Thành phố/Tỉnh
  final int bedrooms;         // Số phòng ngủ
  final int bathrooms;        // Số phòng tắm
  final int maxGuests;        // Sức chứa tối đa (số khách)
  final DateTime? createdAt;  // Ngày khởi tạo bài đăng phòng

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

/// Model điểm dữ liệu báo cáo doanh thu theo tháng/kỳ
class RevenueReportItem {
  final String month;   // Tháng/kỳ báo cáo (ví dụ: "Tháng 06/2025")
  final double amount;  // Doanh thu trong tháng/kỳ (VNĐ)

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


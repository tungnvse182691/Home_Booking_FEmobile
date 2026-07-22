/// Model đại diện cho thông tin một đơn đặt phòng của Host (Chủ nhà)
class HostBookingItem {
  final String bookingId;       // Mã ID duy nhất của đơn đặt phòng
  final String bookingCode;     // Mã code rút gọn của đơn (ví dụ: BK12345)
  final String roomId;          // ID phòng Homestay được đặt
  final String roomName;        // Tên phòng Homestay
  final String? thumbnailUrl;   // Đường dẫn ảnh đại diện phòng
  final String customerName;    // Tên của khách hàng đặt phòng
  final String? customerPhone;  // Số điện thoại liên hệ khách hàng
  final String? customerAvatar; // Ảnh đại diện của khách hàng
  final DateTime checkInDate;   // Ngày nhận phòng (Check-in)
  final DateTime checkOutDate;  // Ngày trả phòng (Check-out)
  final int numberOfNights;     // Tổng số đêm lưu trú
  final double totalAmount;     // Tổng số tiền thanh toán của đơn
  final String status;          // Trạng thái đơn (PENDING, CONFIRMED, COMPLETED, CANCELLED)
  final String? specialRequest; // Yêu cầu đặc biệt từ khách hàng (nếu có)
  final String? cancelReason;   // Lý do hủy đơn (nếu bị hủy)
  final DateTime createdAt;     // Thời điểm tạo đơn đặt phòng

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

  /// Factory constructor khởi tạo đối tượng từ JSON của Backend trả về
  factory HostBookingItem.fromJson(Map<String, dynamic> json) {
    // Hàm trợ giúp ép kiểu chuỗi ngày từ Backend thành DateTime
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) {
        // Định dạng ngày yyyy-MM-dd từ BE
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


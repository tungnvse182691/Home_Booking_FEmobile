class BookingModel {
  final String? id;
  final String roomId;
  final String roomName;
  final String? thumbnailUrl;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalAmount;
  final String paymentMethod;
  final String? note;
  final String status;

  BookingModel({
    this.id,
    required this.roomId,
    required this.roomName,
    this.thumbnailUrl,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalAmount,
    required this.paymentMethod,
    this.note,
    this.status = 'PENDING',
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'note': note,
    };
  }
}

import '../../../core/constants/api_constants.dart';

class BookingRequest {
  final String roomId;
  final String checkInDate;
  final String checkOutDate;
  final String paymentMethod;
  final String? specialRequest;

  BookingRequest({
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.paymentMethod,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() => {
    // Backend expects numeric roomId when possible — send as int if parseable
    'roomId': int.tryParse(roomId) ?? roomId,
    'checkInDate': checkInDate,
    'checkOutDate': checkOutDate,
    'paymentMethod': paymentMethod,
    if (specialRequest != null && specialRequest!.isNotEmpty)
      'specialRequest': specialRequest,
  };
}

class BookingResponse {
  final String bookingId;
  final String bookingCode;
  final double totalAmount;
  final String status;

  BookingResponse({
    required this.bookingId,
    required this.bookingCode,
    required this.totalAmount,
    required this.status,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) =>
      BookingResponse(
        bookingId: (json['bookingId'] ?? json['id'] ?? '').toString(),
        bookingCode: json['bookingCode']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? '',
      );
}

class PaymentRequest {
  final String bookingId;
  final String paymentMethod;

  PaymentRequest({required this.bookingId, required this.paymentMethod});

  Map<String, dynamic> toJson() => {
    'bookingId': int.tryParse(bookingId) ?? bookingId,
    'paymentMethod': paymentMethod,
  };
}

class PaymentResponse {
  final String? paymentUrl;
  final String transactionCode;

  PaymentResponse({this.paymentUrl, required this.transactionCode});

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      PaymentResponse(
        paymentUrl: json['paymentUrl']?.toString(),
        transactionCode: json['transactionCode']?.toString() ?? '',
      );
}

class PaymentConfirmRequest {
  final String transactionCode;
  final bool success;

  PaymentConfirmRequest({required this.transactionCode, required this.success});

  Map<String, dynamic> toJson() => {
    'transactionCode': transactionCode,
    'success': success,
  };
}

class BookingHistoryItem {
  final String bookingId;
  final String bookingCode;
  final String roomName;
  final String checkInDate;
  final String checkOutDate;
  final double totalAmount;
  final String status;
  final String? roomId;
  final String? thumbnailUrl;
  final int? rating;

  BookingHistoryItem({
    required this.bookingId,
    required this.bookingCode,
    required this.roomName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalAmount,
    required this.status,
    this.roomId,
    this.thumbnailUrl,
    this.rating,
  });

  factory BookingHistoryItem.fromJson(Map<String, dynamic> json) =>
      BookingHistoryItem(
        bookingId: (json['bookingId'] ?? json['id'] ?? '').toString(),
        bookingCode: json['bookingCode']?.toString() ?? '',
        roomName: json['roomName']?.toString() ?? '',
        checkInDate: json['checkInDate']?.toString() ?? '',
        checkOutDate: json['checkOutDate']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? 'PENDING',
        roomId: json['roomId']?.toString(),
        thumbnailUrl: ApiConstants.formatImageUrl(
          json['thumbnailUrl']?.toString() ??
              json['thumbnailImage']?.toString(),
        ),
        rating: json['rating'] as int?,
      );
}

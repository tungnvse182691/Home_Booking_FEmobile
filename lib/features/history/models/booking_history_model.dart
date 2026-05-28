import '../../rooms/models/room_model.dart';

enum BookingStatus { PENDING, CONFIRMED, CANCELED, COMPLETED }

class BookingHistoryModel {
  final String id;
  final String? roomId;
  final String roomName;
  final String? location;
  final String? thumbnailUrl;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final double totalAmount;
  final BookingStatus status;
  final DateTime? canceledAt;
  final HostModel? host;
  final double? rating; 
  final String? review;

  BookingHistoryModel({
    required this.id,
    this.roomId,
    required this.roomName,
    this.location,
    this.thumbnailUrl,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.totalAmount,
    required this.status,
    this.canceledAt,
    this.host,
    this.rating,
    this.review,
  });

  factory BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    return BookingHistoryModel(
      id: (json['bookingId'] ?? json['id'] ?? '').toString(),
      roomId: json['roomId']?.toString(),
      roomName: json['roomName'] ?? '',
      location: json['location'],
      thumbnailUrl: json['thumbnailUrl'],
      checkInDate: json['checkInDate'] != null ? DateTime.parse(json['checkInDate']) : DateTime.now(),
      checkOutDate: json['checkOutDate'] != null ? DateTime.parse(json['checkOutDate']) : DateTime.now(),
      nights: json['nights'] ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']?.toString() ?? 'PENDING'),
      canceledAt: json['canceledAt'] != null ? DateTime.parse(json['canceledAt']) : null,
      host: json['host'] != null ? HostModel.fromJson(json['host']) : null,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'],
    );
  }

  static BookingStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return BookingStatus.PENDING;
      case 'CONFIRMED': return BookingStatus.CONFIRMED;
      case 'COMPLETED': return BookingStatus.COMPLETED;
      case 'CANCELED': return BookingStatus.CANCELED;
      default: return BookingStatus.PENDING;
    }
  }

  BookingHistoryModel copyWith({BookingStatus? status, DateTime? canceledAt}) {
    return BookingHistoryModel(
      id: id,
      roomId: roomId,
      roomName: roomName,
      location: location,
      thumbnailUrl: thumbnailUrl,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      nights: nights,
      totalAmount: totalAmount,
      status: status ?? this.status,
      canceledAt: canceledAt ?? this.canceledAt,
      host: host,
      rating: rating,
      review: review,
    );
  }
}

import '../../rooms/models/room_model.dart';

enum BookingStatus { CONFIRMED, COMPLETED, CANCELED }

class BookingHistoryModel {
  final String id;
  final String roomId;
  final String roomName;
  final String? location;
  final String thumbnailUrl;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final double totalAmount;
  final BookingStatus status;
  final DateTime? canceledAt;
  final HostModel? host;
  final double? rating; // Điểm đánh giá của user cho booking này
  final String? review;

  BookingHistoryModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    this.location,
    required this.thumbnailUrl,
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
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      location: json['location'],
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      checkInDate: DateTime.parse(json['checkInDate']),
      checkOutDate: DateTime.parse(json['checkOutDate']),
      nights: json['nights'] ?? 0,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: BookingStatus.values.firstWhere((e) => e.name == json['status']),
      canceledAt: json['canceledAt'] != null ? DateTime.parse(json['canceledAt']) : null,
      host: json['host'] != null ? HostModel.fromJson(json['host']) : null,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'],
    );
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

import '../../../core/constants/api_constants.dart';

class ReviewModel {
  final String reviewId;
  final String userId;
  final String roomId;
  final String? roomName;
  final String? roomThumbnailUrl;
  final String bookingId;
  final String userName;
  final String? avatarUrl;
  final double rating;
  final double? cleanliness;
  final double? location;
  final double? service;
  final double? value;
  final List<String>? tags;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.roomId,
    this.roomName,
    this.roomThumbnailUrl,
    required this.bookingId,
    required this.userName,
    this.avatarUrl,
    required this.rating,
    this.cleanliness,
    this.location,
    this.service,
    this.value,
    this.tags,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final reviewerJson = json['reviewer'] as Map<String, dynamic>?;
    List<String>? tags;
    final rawTags = json['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }
    return ReviewModel(
      reviewId: json['reviewId']?.toString() ?? json['id']?.toString() ?? '',
      userId: reviewerJson?['userId']?.toString() ?? json['userId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      roomName: json['roomName']?.toString(),
      roomThumbnailUrl: ApiConstants.formatImageUrl(json['roomThumbnailUrl']?.toString()),
      bookingId: json['bookingId']?.toString() ?? '',
      userName: reviewerJson?['fullName']?.toString() ??
          json['userName']?.toString() ??
          'Người dùng',
      avatarUrl: ApiConstants.formatImageUrl(
        reviewerJson?['avatarUrl']?.toString() ?? json['avatarUrl']?.toString(),
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      cleanliness: (json['cleanliness'] as num?)?.toDouble(),
      location: (json['location'] as num?)?.toDouble(),
      service: (json['service'] as num?)?.toDouble(),
      value: (json['value'] as num?)?.toDouble(),
      tags: tags,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

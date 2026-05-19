class ReviewModel {
  final String id;
  final String bookingId;
  final String roomId;
  final String userName;
  final String? userAvatar;
  final double overallRating;
  final double? cleanlinessRating;
  final double? locationRating;
  final double? serviceRating;
  final double? valueRating;
  final List<String> quickTags;
  final String? comment;
  final List<String> images;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.roomId,
    required this.userName,
    this.userAvatar,
    required this.overallRating,
    this.cleanlinessRating,
    this.locationRating,
    this.serviceRating,
    this.valueRating,
    this.quickTags = const [],
    this.comment,
    this.images = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      userName: json['userName'] ?? 'Người dùng',
      userAvatar: json['userAvatar'],
      overallRating: (json['overallRating'] as num).toDouble(),
      cleanlinessRating: (json['cleanlinessRating'] as num?)?.toDouble(),
      locationRating: (json['locationRating'] as num?)?.toDouble(),
      serviceRating: (json['serviceRating'] as num?)?.toDouble(),
      valueRating: (json['valueRating'] as num?)?.toDouble(),
      quickTags: List<String>.from(json['quickTags'] ?? []),
      comment: json['comment'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

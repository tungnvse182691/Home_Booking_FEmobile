enum Role { user, ai }

class SuggestedRoom {
  final int roomId;
  final String name;
  final String city;
  final double pricePerNight;
  final String? thumbnailUrl;
  final double ratingAvg;

  SuggestedRoom({
    required this.roomId,
    required this.name,
    required this.city,
    required this.pricePerNight,
    this.thumbnailUrl,
    required this.ratingAvg,
  });

  factory SuggestedRoom.fromJson(Map<String, dynamic> json) {
    return SuggestedRoom(
      roomId: json['roomId'] is int ? json['roomId'] as int : (json['roomId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChatMessage {
  final Role role;
  final String content;
  final DateTime timestamp;
  final List<SuggestedRoom>? suggestedRooms;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.suggestedRooms,
  });
}

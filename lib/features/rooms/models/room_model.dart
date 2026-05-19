class HostModel {
  final String name;
  final String avatar;
  final double rating;

  HostModel({
    required this.name,
    required this.avatar,
    required this.rating,
  });

  factory HostModel.fromJson(Map<String, dynamic> json) {
    return HostModel(
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RoomModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final double price;
  final double rating;
  final int reviews;
  final String imageUrl;
  final List<String> images;
  final List<String> amenities;
  final List<String> blockedDates;
  final HostModel? host;
  final double lat;
  final double lng;

  RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.images,
    required this.amenities,
    this.blockedDates = const [],
    this.host,
    this.lat = 0.0,
    this.lng = 0.0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: json['reviews'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? [json['imageUrl']]),
      amenities: List<String>.from(json['amenities'] ?? []),
      blockedDates: List<String>.from(json['blockedDates'] ?? []),
      host: json['host'] != null ? HostModel.fromJson(json['host']) : null,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

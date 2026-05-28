import '../../../core/constants/api_constants.dart';

class RoomListItem {
  final String? favoriteId;
  final String roomId;
  final String name;
  final String city;
  final double pricePerNight;
  final String thumbnailUrl;
  final double rating;
  final int reviewCount;

  RoomListItem({
    this.favoriteId,
    required this.roomId,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.thumbnailUrl,
    required this.rating,
    required this.reviewCount,
  });

  factory RoomListItem.fromJson(Map<String, dynamic> json) => RoomListItem(
    favoriteId: json['favoriteId']?.toString(),
    roomId: (json['roomId'] ?? json['id'] ?? '').toString(),
    name: json['name']?.toString() ?? json['roomName']?.toString() ?? '',
    city: json['city']?.toString() ?? json['location']?.toString() ?? '',
    pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0.0,
    thumbnailUrl:
        ApiConstants.formatImageUrl(
          json['thumbnailImage']?.toString() ??
              json['thumbnailUrl']?.toString(),
        ) ??
        '',
    rating:
        (json['ratingAvg'] as num?)?.toDouble() ??
        (json['rating'] as num?)?.toDouble() ??
        0.0,
    reviewCount: json['reviewCount'] ?? 0,
  );

  String get roomName => name;
}

class RoomListResponse {
  final List<RoomListItem> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  RoomListResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory RoomListResponse.fromJson(Map<String, dynamic> json) {
    final List rawItems =
        (json['items'] as List?) ??
        (json['data'] as List?) ??
        (json['results'] as List?) ??
        const [];
    final total =
        (json['totalCount'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        rawItems.length;
    final page =
        (json['pageNumber'] as num?)?.toInt() ??
        (json['page'] as num?)?.toInt() ??
        1;
    final limit =
        (json['pageSize'] as num?)?.toInt() ??
        (json['limit'] as num?)?.toInt() ??
        rawItems.length;
    final calculatedTotalPages = limit > 0 ? (total / limit).ceil() : 1;
    final totalPages =
        (json['totalPages'] as num?)?.toInt() ?? calculatedTotalPages;

    return RoomListResponse(
      items: rawItems
          .map(
            (e) => RoomListItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      totalCount: total,
      pageNumber: page,
      pageSize: limit,
      totalPages: totalPages,
    );
  }
}

typedef RoomModel = RoomDetail;

class RoomDetail {
  final String roomId;
  final String name;
  final String description;
  final String city;
  final String? district;
  final String? ward;
  final String? areaName;
  final String address;
  final double pricePerNight;
  final int maxGuests;
  final int bedrooms;
  final int bathrooms;
  final List<RoomImage> roomImages;
  final double rating;
  final int reviewCount;
  final List<Amenity> amenities;
  final String roomType;
  final HostModel host;
  final double lat;
  final double lng;
  final List<String> blockedDates;

  RoomDetail({
    required this.roomId,
    required this.name,
    required this.description,
    required this.city,
    this.district,
    this.ward,
    this.areaName,
    required this.address,
    required this.pricePerNight,
    required this.maxGuests,
    this.bedrooms = 1,
    this.bathrooms = 1,
    required this.roomImages,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.roomType,
    required this.host,
    this.lat = 0.0,
    this.lng = 0.0,
    this.blockedDates = const [],
  });

  // Getters for UI compatibility
  String get id => roomId;
  String get location => address;
  double get price => pricePerNight;
  int get reviews => reviewCount;
  String get thumbnailUrl {
    final thumb = roomImages.where((img) => img.isThumbnail).toList();
    if (thumb.isNotEmpty) return thumb.first.imageUrl;
    if (roomImages.isNotEmpty) return roomImages.first.imageUrl;
    return '';
  }

  String get imageUrl => thumbnailUrl;
  List<String> get images => roomImages.map((e) => e.imageUrl).toList();
  List<String> get amenityNames => amenities.map((e) => e.name).toList();

  factory RoomDetail.fromJson(Map<String, dynamic> json) => RoomDetail(
    roomId: (json['roomId'] ?? json['id'] ?? '').toString(),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    city: json['city'] ?? '',
    district: json['district']?.toString(),
    ward: json['ward']?.toString(),
    areaName: json['areaName']?.toString(),
    address: json['address'] ?? '',
    pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0.0,
    maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 1,
    bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
    bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
    roomImages: (json['images'] as List? ?? [])
        .map((e) => RoomImage.fromJson(e))
        .toList(),
    // BE trả về 'ratingAvg'
    rating:
        (json['ratingAvg'] as num?)?.toDouble() ??
        (json['rating'] as num?)?.toDouble() ??
        0.0,
    reviewCount: json['reviewCount'] ?? 0,
    amenities: (json['amenities'] as List? ?? [])
        .map((e) => Amenity.fromJson(e))
        .toList(),
    // BE trả về 'roomTypeName'
    roomType:
        json['roomTypeName']?.toString() ?? json['roomType']?.toString() ?? '',
    host: HostModel.fromJson(json['host'] ?? {}),
    lat:
        (json['latitude'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble() ??
        0.0,
    lng:
        (json['longitude'] as num?)?.toDouble() ??
        (json['lng'] as num?)?.toDouble() ??
        0.0,
    blockedDates: (json['blockedDates'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

class RoomImage {
  final String imageUrl;
  final bool isThumbnail;

  RoomImage({required this.imageUrl, required this.isThumbnail});

  factory RoomImage.fromJson(Map<String, dynamic> json) => RoomImage(
    imageUrl: ApiConstants.formatImageUrl(json['imageUrl'] ?? '') ?? '',
    isThumbnail: json['isThumbnail'] ?? false,
  );
}

class HostModel {
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  HostModel({
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory HostModel.fromJson(Map<String, dynamic> json) => HostModel(
    userId: (json['userId'] ?? json['id'] ?? '').toString(),
    fullName: json['fullName'] ?? '',
    email: json['email'],
    phone: json['phone'],
    avatarUrl: ApiConstants.formatImageUrl(json['avatarUrl']),
  );
}

class Amenity {
  final String amenityId;
  final String name;
  final String? iconUrl;

  Amenity({required this.amenityId, required this.name, this.iconUrl});

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    amenityId: (json['amenityId'] ?? json['id'] ?? '').toString(),
    name: json['name'] ?? '',
    // BE trả về 'iconCode' thay vì 'iconUrl'
    iconUrl:
        json['iconUrl']?.toString() ??
        json['iconCode']?.toString() ??
        json['icon']?.toString(),
  );
}

class RoomType {
  final String roomTypeId;
  final String name;

  RoomType({required this.roomTypeId, required this.name});

  factory RoomType.fromJson(Map<String, dynamic> json) => RoomType(
    roomTypeId: (json['roomTypeId'] ?? json['id'] ?? '').toString(),
    // BE trả về 'typeName', fallback về 'name'
    name: json['typeName']?.toString() ?? json['name']?.toString() ?? '',
  );
}

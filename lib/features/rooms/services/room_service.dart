import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/room_model.dart';
import '../../review/models/review_model.dart';

class RoomService {
  final Dio _dio;

  RoomService(this._dio);

  List<dynamic> _extractItems(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final nested = map['items'] ?? map['data'] ?? map['results'];
      if (nested is List) return nested;
      if (nested is Map) return _extractItems(nested);
    }
    return const [];
  }

  Future<RoomListResponse> getRooms({
    String? searchTerm,
    String? city,
    String? roomTypeId,
    double? minPrice,
    double? maxPrice,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.rooms,
        queryParameters: {
          if (searchTerm != null && searchTerm.isNotEmpty) 'keyword': searchTerm,
          if (city != null && city.isNotEmpty) 'city': city,
          if (roomTypeId != null && roomTypeId.isNotEmpty) 'roomTypeId': roomTypeId,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          'page': pageNumber,
          'limit': pageSize,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return RoomListResponse.fromJson({'items': data});
        }
        if (data is Map<String, dynamic>) {
          final map = Map<String, dynamic>.from(data);
          final payload = <String, dynamic>{...map};
          payload['items'] = _extractItems(map);
          return RoomListResponse.fromJson(payload);
        }
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final payload = <String, dynamic>{...map};
          payload['items'] = _extractItems(map);
          return RoomListResponse.fromJson(payload);
        }
        throw Exception('Định dạng dữ liệu phòng không hợp lệ');
      }

      throw Exception(response.data['message'] ?? 'Không thể tải danh sách phòng');
    } catch (e) {
      rethrow;
    }
  }

  Future<RoomDetail> getRoomDetail(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.roomDetail}$id');
      if (response.data['success'] == true) {
        return RoomDetail.fromJson(response.data['data']);
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể tải chi tiết phòng',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReviewModel>> getRoomReviews(String roomId) async {
    try {
      final response = await _dio.get('${ApiConstants.rooms}/$roomId/reviews');
      if (response.data['success'] == true) {
        // BE trả về { total, page, limit, data: [...] }
        final wrapper = response.data['data'];
        final List items = wrapper is Map
            ? (wrapper['data'] ?? wrapper['items'] ?? [])
            : (wrapper as List? ?? []);
        return items.map((e) => ReviewModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomType>> getRoomTypes() async {
    try {
      final response = await _dio.get(ApiConstants.roomTypes);
      if (response.data['success'] == true) {
        final items = _extractItems(response.data['data']);
        return items
            .map((e) => RoomType.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Amenity>> getAmenities() async {
    try {
      final response = await _dio.get(ApiConstants.amenities);
      if (response.data['success'] == true) {
        final items = _extractItems(response.data['data']);
        return items
            .map((e) => Amenity.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

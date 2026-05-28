import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../models/host_model.dart';

class HostService {
  final Dio _dio;

  HostService(this._dio);

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final wrapped = data['data'];
      if (wrapped is Map<String, dynamic>) return wrapped;
      return data;
    }
    if (data is Map) {
      final wrapped = data['data'];
      if (wrapped is Map) return Map<String, dynamic>.from(wrapped);
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final wrapped = data['data'];
      // data.data is a List directly
      if (wrapped is List) return wrapped;
      // data.data is an object containing items (e.g. revenue report)
      if (wrapped is Map) {
        final inner = wrapped['items'] ?? wrapped['results'] ?? [];
        if (inner is List) return inner;
      }
      final items = data['items'] ?? data['results'] ?? [];
      if (items is List) return items;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final wrapped = map['data'];
      if (wrapped is List) return wrapped;
      if (wrapped is Map) {
        final inner = wrapped['items'] ?? wrapped['results'] ?? [];
        if (inner is List) return inner;
      }
      final items = map['items'] ?? map['results'] ?? [];
      if (items is List) return items;
    }
    return const [];
  }

  Future<HostDashboardData> getDashboard() async {
    final response = await _dio.get(ApiConstants.hostDashboard);
    return HostDashboardData.fromJson(_extractMap(response.data));
  }

  /// GET /api/host/rooms — lay danh sach phong cua host hien tai (dua vao JWT)
  Future<List<HostRoomItem>> getRooms(String currentUserId) async {
    final response = await _dio.get(ApiConstants.hostRooms);
    final rawList = _extractList(response.data);
    return rawList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return HostRoomItem(
        id: (map['roomId'] ?? map['id'] ?? '').toString(),
        name: map['name']?.toString() ?? '',
        price: (map['pricePerNight'] as num?)?.toDouble() ?? 0.0,
        status: map['status']?.toString() ?? 'AVAILABLE',
        thumbnailUrl: ApiConstants.formatImageUrl(map['thumbnailUrl']?.toString()),
        ratingAvg: (map['ratingAvg'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
        city: map['city']?.toString() ?? '',
        bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 1,
        bathrooms: (map['bathrooms'] as num?)?.toInt() ?? 1,
        maxGuests: (map['maxGuests'] as num?)?.toInt() ?? 1,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString())
            : null,
      );
    }).toList();
  }

  Future<void> createRoom(Map<String, dynamic> roomData) async {
    await _dio.post(ApiConstants.hostRooms, data: roomData);
  }

  Future<void> updateRoom(String id, Map<String, dynamic> roomData) async {
    await _dio.put('${ApiConstants.hostRooms}/$id', data: roomData);
  }

  Future<void> deleteRoom(String id) async {
    await _dio.delete('${ApiConstants.hostRooms}/$id');
  }

  /// GET /api/host/reports/revenue
  /// BE returns: { success, data: { fromDate, toDate, groupBy, totalRevenue, totalBookings, items: [...] } }
  Future<List<RevenueReportItem>> getRevenueReport() async {
    final response = await _dio.get(ApiConstants.hostRevenue);
    final rawList = _extractList(response.data);
    return rawList
        .map((e) => RevenueReportItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

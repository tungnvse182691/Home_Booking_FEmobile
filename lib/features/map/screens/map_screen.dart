import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/map_provider.dart';
import '../widgets/price_marker.dart';
import '../widgets/room_bottom_sheet.dart';
import '../../../utils/app_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(10.7769, 106.7009); // Quận 1, HCM

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    // Bỏ qua xin quyền nếu đang test UI nhanh (tùy chọn)
    // Hoặc xử lý đúng chuẩn:
    var status = await Permission.location.request();
    if (status.isGranted) {
      _moveToCurrentLocation();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    } catch (e) {
      debugPrint('Không thể lấy vị trí: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 14,
              onTap: (_, __) => mapNotifier.selectRoom(null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.home_booking',
              ),
              
              // Markers
              MarkerLayer(
                markers: mapState.rooms.map((room) {
                  final isSelected = mapState.selectedRoom?.id == room.id;
                  return Marker(
                    point: LatLng(room.lat, room.lng),
                    width: 70,
                    height: 40,
                    child: PriceMarker(
                      price: room.price,
                      isSelected: isSelected,
                      onTap: () {
                        mapNotifier.selectRoom(room);
                        _mapController.move(LatLng(room.lat, room.lng), _mapController.camera.zoom);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          // Nút quay lại
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // FAB "Vị trí của tôi"
          Positioned(
            bottom: mapState.selectedRoom != null ? 220 : 32,
            right: 16,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppTheme.primary),
            ),
          ),
          
          // Bottom Sheet khi chọn phòng
          if (mapState.selectedRoom != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: RoomBottomSheet(room: mapState.selectedRoom!),
            ),
        ],
      ),
    );
  }
}

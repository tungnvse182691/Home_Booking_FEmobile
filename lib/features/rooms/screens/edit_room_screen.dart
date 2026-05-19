import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/app_theme.dart';
import '../providers/create_room_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/image_picker_grid.dart';

class EditRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const EditRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends ConsumerState<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  
  final List<String> _amenityOptions = [
    'Wifi', 'Bếp', 'Bể bơi', 'Điều hòa', 'Máy giặt', 'Chỗ đậu xe', 'TV', 'Tủ lạnh'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _priceController = TextEditingController();
    _addressController = TextEditingController();
    
    // Prefill data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoomData();
    });
  }

  void _loadRoomData() {
    final roomState = ref.read(roomNotifierProvider);
    final room = roomState.rooms.firstWhere((r) => r.id == widget.roomId);
    
    _nameController.text = room.name;
    _descController.text = room.description;
    _priceController.text = room.price.toString();
    _addressController.text = room.location;

    final notifier = ref.read(createRoomProvider.notifier);
    notifier.updateBasicInfo(name: room.name, description: room.description, price: room.price);
    notifier.setAddress(room.location);
    notifier.setLocation(room.lat, room.lng);
    // Lưu ý: createRoomProvider hiện tại dùng XFile cho ảnh mới, 
    // trong thực tế Edit cần xử lý cả ảnh URL cũ và XFile mới.
    for (var a in room.amenities) {
      notifier.toggleAmenity(a);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chỉnh sửa phòng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: StepIndicator(currentStep: state.currentStep),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(state, notifier),
            ),
          ),
          _buildBottomAction(state, notifier),
        ],
      ),
    );
  }

  Widget _buildStepContent(CreateRoomState state, CreateRoomNotifier notifier) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2(state, notifier);
      case 3:
        return _buildStep3(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên phòng'),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên phòng' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Mô tả'),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mô tả' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Giá / đêm (VNĐ)', suffixText: 'đ'),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập giá' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(CreateRoomState state, CreateRoomNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ImagePickerGrid(
          images: state.images,
          onPick: () async {
            final images = await ImagePicker().pickMultiImage();
            if (images.isNotEmpty) notifier.addImages(images);
          },
          onRemove: (index) => notifier.removeImage(index),
        ),
        const SizedBox(height: 32),
        const Text('Tiện ích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _amenityOptions.map((amenity) {
            final isSelected = state.selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (_) => notifier.toggleAmenity(amenity),
              selectedColor: AppTheme.primary.withOpacity(0.2),
              checkmarkColor: AppTheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3(CreateRoomState state, CreateRoomNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vị trí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(state.lat ?? 10.7769, state.lng ?? 106.7009),
                initialZoom: 15,
                onTap: (tapPosition, point) => notifier.setLocation(point.latitude, point.longitude),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                if (state.lat != null && state.lng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(state.lat!, state.lng!),
                        width: 40, height: 40,
                        child: const Icon(Icons.location_on, color: AppTheme.primary, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể'),
          onChanged: (v) => notifier.setAddress(v),
        ),
      ],
    );
  }

  Widget _buildBottomAction(CreateRoomState state, CreateRoomNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (state.currentStep > 1)
            Expanded(child: OutlinedButton(onPressed: () => notifier.setStep(state.currentStep - 1), child: const Text('Quay lại'))),
          if (state.currentStep > 1) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () async {
                if (state.currentStep == 1) {
                  if (_formKey.currentState!.validate()) {
                    notifier.updateBasicInfo(
                      name: _nameController.text,
                      description: _descController.text,
                      price: double.parse(_priceController.text),
                    );
                    notifier.setStep(2);
                  }
                } else if (state.currentStep == 2) {
                  notifier.setStep(3);
                } else {
                  // Gọi API cập nhật (PATCH)
                  final success = await notifier.submit(); // Trong thực tế dùng logic Patch riêng
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: AppTheme.success));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(state.currentStep < 3 ? 'Tiếp theo' : 'Lưu thay đổi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

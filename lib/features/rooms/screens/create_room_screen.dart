import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/app_theme.dart';
import '../providers/create_room_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/image_picker_grid.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final List<String> _amenityOptions = [
    'Wifi', 'Bếp', 'Bể bơi', 'Điều hòa', 'Máy giặt', 'Chỗ đậu xe', 'TV', 'Tủ lạnh'
  ];

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
        title: const Text('Tạo phòng mới', style: TextStyle(fontWeight: FontWeight.bold)),
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
        return _buildStep1(state, notifier);
      case 2:
        return _buildStep2(state, notifier);
      case 3:
        return _buildStep3(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1(CreateRoomState state, CreateRoomNotifier notifier) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên phòng', hintText: 'VD: Căn hộ Cozy trung tâm'),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên phòng' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'Nhập mô tả chi tiết về phòng...'),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mô tả' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Giá / đêm (VNĐ)', suffixText: 'đ'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập giá';
              if (double.tryParse(v) == null) return 'Giá không hợp lệ';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(CreateRoomState state, CreateRoomNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh (Tối đa 5)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                initialCenter: const LatLng(10.7769, 106.7009),
                initialZoom: 13,
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
        const SizedBox(height: 16),
        if (state.lat != null)
          Text('Tọa độ: ${state.lat!.toStringAsFixed(4)}, ${state.lng!.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể', hintText: 'VD: 123 Lê Lợi, Quận 1...'),
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
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.setStep(state.currentStep - 1),
                child: const Text('Quay lại'),
              ),
            ),
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
                  // Đã bỏ qua kiểm tra ảnh để test UI
                  notifier.setStep(3);
                } else {
                  if (state.lat == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn vị trí trên bản đồ')));
                    return;
                  }
                  final success = await notifier.submit();
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo phòng thành công!'), backgroundColor: AppTheme.success));
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
                  : Text(state.currentStep < 3 ? 'Tiếp theo' : 'Tạo phòng', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

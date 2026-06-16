import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/create_room_provider.dart';
import '../providers/room_list_provider.dart';
import '../models/room_model.dart';
import '../widgets/step_indicator.dart';
import '../widgets/image_picker_grid.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step 1 controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxGuestsController = TextEditingController(text: '2');
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');

  // Step 2 controllers (địa chỉ — không còn map)
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _areaController = TextEditingController();
  final _latController = TextEditingController(text: '10.7769');
  final _lngController = TextEditingController(text: '106.7009');

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _maxGuestsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _areaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);
    // Watch at top-level to avoid "modify during build" error
    final roomTypes = ref.watch(roomTypesProvider).value ?? [];
    final amenities = ref.watch(amenitiesProvider).value ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tạo phòng mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
              child: _buildStepContent(state, notifier, roomTypes, amenities),
            ),
          ),
          _buildBottomAction(state, notifier),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    CreateRoomState state,
    CreateRoomNotifier notifier,
    List<RoomType> roomTypes,
    List<Amenity> amenities,
  ) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1(state, notifier, roomTypes);
      case 2:
        return _buildStep2(state, notifier);
      case 3:
        return _buildStep3(state, notifier, amenities);
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Thông tin cơ bản ─────────────────────────────────────────────
  Widget _buildStep1(
    CreateRoomState state,
    CreateRoomNotifier notifier,
    List<RoomType> roomTypes,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên phòng *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập tên phòng'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: state.roomTypeId.isEmpty ? null : state.roomTypeId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Loại phòng *',
              border: OutlineInputBorder(),
            ),
            items: roomTypes
                .map(
                  (e) => DropdownMenuItem(
                    value: e.roomTypeId,
                    child: Text(e.name),
                  ),
                )
                .toList(),
            onChanged: (v) => notifier.updateField(roomTypeId: v),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vui lòng chọn loại phòng' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá/đêm *',
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nhập giá';
                    }
                    final p = double.tryParse(v.trim());
                    if (p == null || p <= 0) return 'Giá không hợp lệ';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxGuestsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số khách tối đa',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bedroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Phòng ngủ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _bathroomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Phòng tắm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Phòng nổi bật (Featured)'),
            value: state.isFeatured,
            onChanged: (v) => notifier.updateField(isFeatured: v),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Vị trí (không còn map) ──────────────────────────────────────
  Widget _buildStep2(CreateRoomState state, CreateRoomNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vị trí',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'Thành phố *',
            border: OutlineInputBorder(),
            hintText: 'VD: Hồ Chí Minh',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'Quận/Huyện',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _wardController,
                decoration: const InputDecoration(
                  labelText: 'Phường/Xã',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _areaController,
          decoration: const InputDecoration(
            labelText: 'Tên khu vực',
            border: OutlineInputBorder(),
            hintText: 'VD: Quận 1, Bình Thạnh...',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ cụ thể *',
            border: OutlineInputBorder(),
            hintText: 'VD: 123 Nguyễn Huệ',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tọa độ (tùy chọn)',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Vĩ độ (Lat)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kinh độ (Lng)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Hình ảnh & Tiện ích ─────────────────────────────────────────
  Widget _buildStep3(
    CreateRoomState state,
    CreateRoomNotifier notifier,
    List<Amenity> amenities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh & Tiện ích',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const Text('Hình ảnh (Tối đa 5)'),
        const SizedBox(height: 8),
        ImagePickerGrid(
          images: state.images,
          existingUrls: state.imageUrls,
          onPick: () async {
            final picked = await ImagePicker().pickMultiImage();
            if (picked.isNotEmpty) notifier.addImages(picked);
          },
          onRemove: (i) => notifier.removeImage(i),
          onRemoveUrl: (i) => notifier.removeImageUrl(i),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Hoặc nhập URL hình ảnh',
            suffixIcon: Icon(Icons.add),
            border: OutlineInputBorder(),
          ),
          onFieldSubmitted: (v) {
            if (v.isNotEmpty) notifier.addImageUrl(v);
          },
        ),
        const SizedBox(height: 24),
        const Text('Tiện ích'),
        const SizedBox(height: 8),
        amenities.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: amenities.map((a) {
                  final isSelected = state.selectedAmenityIds.contains(
                    a.amenityId,
                  );
                  return FilterChip(
                    label: Text(a.name),
                    selected: isSelected,
                    onSelected: (_) => notifier.toggleAmenity(a.amenityId),
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
      ],
    );
  }

  // ── Bottom action bar ────────────────────────────────────────────────────
  Widget _buildBottomAction(
    CreateRoomState state,
    CreateRoomNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (state.currentStep > 1) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.setStep(state.currentStep - 1),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () => _handleNext(state, notifier),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(state.currentStep < 3 ? 'Tiếp theo' : 'Hoàn tất'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext(
    CreateRoomState state,
    CreateRoomNotifier notifier,
  ) async {
    if (state.currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      notifier.updateField(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        maxGuests: int.tryParse(_maxGuestsController.text.trim()) ?? 2,
        bedrooms: int.tryParse(_bedroomsController.text.trim()) ?? 1,
        bathrooms: int.tryParse(_bathroomsController.text.trim()) ?? 1,
      );
      notifier.setStep(2);
      return;
    }

    if (state.currentStep == 2) {
      final city = _cityController.text.trim();
      if (city.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập thành phố'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final address = _addressController.text.trim();
      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập địa chỉ cụ thể'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      notifier.updateField(
        city: city,
        district: _districtController.text.trim(),
        ward: _wardController.text.trim(),
        areaName: _areaController.text.trim(),
      );
      notifier.setAddress(address);
      final lat = double.tryParse(_latController.text.trim()) ?? 10.7769;
      final lng = double.tryParse(_lngController.text.trim()) ?? 106.7009;
      notifier.setLocation(lat, lng);
      notifier.setStep(3);
      return;
    }

    // Step 3 → submit
    final success = await notifier.submit();
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo phòng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/app_theme.dart';
import '../models/room_model.dart';
import '../providers/create_room_provider.dart';
import '../providers/room_provider.dart';
import '../providers/room_list_provider.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/step_indicator.dart';

class EditRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const EditRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends ConsumerState<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step 1
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _maxGuestsController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;

  // Step 2 (địa chỉ — không còn map)
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _wardController;
  late final TextEditingController _areaController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _priceController = TextEditingController();
    _maxGuestsController = TextEditingController(text: '2');
    _bedroomsController = TextEditingController(text: '1');
    _bathroomsController = TextEditingController(text: '1');
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _wardController = TextEditingController();
    _areaController = TextEditingController();
    _latController = TextEditingController(text: '10.7769');
    _lngController = TextEditingController(text: '106.7009');

    // Reset createRoomProvider state khi mở màn hình edit
    Future.microtask(() {
      if (mounted) {
        ref.read(createRoomProvider.notifier).reset();
      }
    });
  }

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

  /// Prefill controllers và provider state từ dữ liệu phòng.
  /// Dùng Future.microtask để tránh modify provider during build.
  void _schedulePrefill(RoomDetail room) {
    if (_prefilled) return;
    _prefilled = true;

    Future.microtask(() {
      if (!mounted) return;

      // Fill text controllers
      _nameController.text = room.name;
      _descController.text = room.description;
      _priceController.text = room.pricePerNight.toStringAsFixed(0);
      _maxGuestsController.text = room.maxGuests.toString();
      _bedroomsController.text = room.bedrooms.toString();
      _bathroomsController.text = room.bathrooms.toString();
      _addressController.text = room.address;
      _cityController.text = room.city;
      _districtController.text = room.district ?? '';
      _wardController.text = room.ward ?? '';
      _areaController.text = room.areaName ?? '';
      _latController.text = room.lat.toString();
      _lngController.text = room.lng.toString();

      // Fill provider state
      final notifier = ref.read(createRoomProvider.notifier);
      notifier.setRoomId(widget.roomId);
      notifier.updateField(
        name: room.name,
        description: room.description,
        price: room.pricePerNight,
        maxGuests: room.maxGuests,
        bedrooms: room.bedrooms,
        bathrooms: room.bathrooms,
        city: room.city,
        district: room.district ?? '',
        ward: room.ward ?? '',
        areaName: room.areaName ?? '',
        roomTypeId: _resolveRoomTypeId(room.roomType),
      );
      notifier.setAddress(room.address);
      notifier.setLocation(room.lat, room.lng);

      // Load existing image URLs from room (set all at once)
      final existingUrls = room.images.where((u) => u.isNotEmpty).toList();
      if (existingUrls.isNotEmpty) notifier.setImageUrls(existingUrls);

      // Set amenities — each toggleAmenity call is safe inside microtask
      for (final amenity in room.amenities) {
        notifier.toggleAmenity(amenity.amenityId);
      }
    });
  }

  String _resolveRoomTypeId(String roomTypeName) {
    final roomTypes = ref.read(roomTypesProvider).valueOrNull ?? const [];
    for (final rt in roomTypes) {
      if (rt.name == roomTypeName) return rt.roomTypeId;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    // Watch at top-level to avoid "modify during build"
    final amenities = ref.watch(amenitiesProvider).value ?? [];

    return roomAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chỉnh sửa phòng',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: Text('Lỗi tải dữ liệu: $err')),
      ),
      data: (room) {
        // Schedule prefill outside build — no modify during build
        _schedulePrefill(room);

        final state = ref.watch(createRoomProvider);
        final notifier = ref.read(createRoomProvider.notifier);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Chỉnh sửa phòng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                  child: _buildStepContent(state, notifier, amenities),
                ),
              ),
              _buildBottomAction(state, notifier),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepContent(
    CreateRoomState state,
    CreateRoomNotifier notifier,
    List<Amenity> amenities,
  ) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3(state, notifier, amenities);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Thông tin cơ bản ─────────────────────────────────────────────
  Widget _buildStep1() {
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
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Giá/đêm *',
              suffixText: 'đ',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập giá';
              final p = double.tryParse(v.trim());
              if (p == null || p <= 0) return 'Giá không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
              const SizedBox(width: 12),
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
        ],
      ),
    );
  }

  // ── Step 2: Vị trí (không còn map) ──────────────────────────────────────
  Widget _buildStep2() {
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
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ cụ thể *',
            border: OutlineInputBorder(),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        const Text(
          'Tiện ích',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        amenities.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: amenities.map((amenity) {
                  final isSelected = state.selectedAmenityIds.contains(
                    amenity.amenityId,
                  );
                  return FilterChip(
                    label: Text(amenity.name),
                    selected: isSelected,
                    onSelected: (_) =>
                        notifier.toggleAmenity(amenity.amenityId),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primary,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      state.currentStep < 3 ? 'Tiếp theo' : 'Lưu thay đổi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          content: Text('Cập nhật thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
}

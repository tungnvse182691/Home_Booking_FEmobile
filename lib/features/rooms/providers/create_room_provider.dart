import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class CreateRoomState {
  final int currentStep;
  final String? roomId;
  final String name;
  final String description;
  final double pricePerNight;
  final int maxGuests;
  final int bedrooms;
  final int bathrooms;
  final List<XFile> images;
  final List<String> imageUrls;
  final List<String> selectedAmenityIds;
  final double? lat;
  final double? lng;
  final String address;
  final String city;
  final String district;
  final String ward;
  final String areaName;
  final String roomTypeId;
  final bool isFeatured;
  final bool isAdmin;
  final bool isLoading;
  final String? error;

  CreateRoomState({
    this.currentStep = 1,
    this.roomId,
    this.name = '',
    this.description = '',
    this.pricePerNight = 0,
    this.maxGuests = 1,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.images = const [],
    this.imageUrls = const [],
    this.selectedAmenityIds = const [],
    this.lat,
    this.lng,
    this.address = '',
    this.city = '',
    this.district = '',
    this.ward = '',
    this.areaName = '',
    this.roomTypeId = '',
    this.isFeatured = false,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
  });

  CreateRoomState copyWith({
    int? currentStep,
    String? roomId,
    String? name,
    String? description,
    double? pricePerNight,
    int? maxGuests,
    int? bedrooms,
    int? bathrooms,
    List<XFile>? images,
    List<String>? imageUrls,
    List<String>? selectedAmenityIds,
    double? lat,
    double? lng,
    String? address,
    String? city,
    String? district,
    String? ward,
    String? areaName,
    String? roomTypeId,
    bool? isFeatured,
    bool? isAdmin,
    bool? isLoading,
    String? error,
  }) {
    return CreateRoomState(
      currentStep: currentStep ?? this.currentStep,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      maxGuests: maxGuests ?? this.maxGuests,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      images: images ?? this.images,
      imageUrls: imageUrls ?? this.imageUrls,
      selectedAmenityIds: selectedAmenityIds ?? this.selectedAmenityIds,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      areaName: areaName ?? this.areaName,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      isFeatured: isFeatured ?? this.isFeatured,
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CreateRoomNotifier extends StateNotifier<CreateRoomState> {
  final Ref ref;

  CreateRoomNotifier(this.ref) : super(CreateRoomState());

  void setStep(int step) => state = state.copyWith(currentStep: step);

  void setRoomId(String? roomId) => state = state.copyWith(roomId: roomId);

  void setIsAdmin(bool isAdmin) => state = state.copyWith(isAdmin: isAdmin);

  void reset() => state = CreateRoomState();

  void updateField({
    String? name,
    String? description,
    double? price,
    int? maxGuests,
    int? bedrooms,
    int? bathrooms,
    String? city,
    String? district,
    String? ward,
    String? areaName,
    String? roomTypeId,
    bool? isFeatured,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      description: description ?? state.description,
      pricePerNight: price ?? state.pricePerNight,
      maxGuests: maxGuests ?? state.maxGuests,
      bedrooms: bedrooms ?? state.bedrooms,
      bathrooms: bathrooms ?? state.bathrooms,
      city: city ?? state.city,
      district: district ?? state.district,
      ward: ward ?? state.ward,
      areaName: areaName ?? state.areaName,
      // Chỉ cập nhật roomTypeId khi giá trị mới không phải null VÀ không rỗng
      roomTypeId: (roomTypeId != null && roomTypeId.isNotEmpty) ? roomTypeId : state.roomTypeId,
      isFeatured: isFeatured ?? state.isFeatured,
    );
  }

  void addImages(List<XFile> newImages) {
    state = state.copyWith(images: [...state.images, ...newImages]);
  }

  void addImageUrl(String url) {
    state = state.copyWith(imageUrls: [...state.imageUrls, url]);
  }

  void setImageUrls(List<String> urls) {
    state = state.copyWith(imageUrls: urls);
  }

  void removeImageUrl(int index) {
    final updated = List<String>.from(state.imageUrls)..removeAt(index);
    state = state.copyWith(imageUrls: updated);
  }

  void removeImage(int index) {
    final updated = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updated);
  }

  void toggleAmenity(String amenityId) {
    final updated = List<String>.from(state.selectedAmenityIds);
    if (updated.contains(amenityId)) {
      updated.remove(amenityId);
    } else {
      updated.add(amenityId);
    }
    state = state.copyWith(selectedAmenityIds: updated);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  void setAddress(String address) {
    state = state.copyWith(address: address);
  }

  Future<bool> submit() async {
    // Validate required fields trước khi gửi
    if (state.name.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Tên phòng không được để trống',
      );
      return false;
    }
    if (state.city.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Thành phố không được để trống',
      );
      return false;
    }
    if (state.address.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Địa chỉ không được để trống',
      );
      return false;
    }
    if (state.pricePerNight <= 0) {
      state = state.copyWith(
        isLoading: false,
        error: 'Giá phòng phải lớn hơn 0',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      final isEdit = state.roomId != null && state.roomId!.isNotEmpty;

      final Map<String, dynamic> body = {
        "name": state.name.trim(),
        "description": state.description.trim(),
        "address": state.address.trim(),
        "city": state.city.trim(),
        if (state.district.isNotEmpty) "district": state.district.trim(),
        if (state.ward.isNotEmpty) "ward": state.ward.trim(),
        if (state.areaName.isNotEmpty) "areaName": state.areaName.trim(),
        "pricePerNight": state.pricePerNight,
        "maxGuests": state.maxGuests,
        "bedrooms": state.bedrooms,
        "bathrooms": state.bathrooms,
        "latitude": state.lat ?? 10.7769,
        "longitude": state.lng ?? 106.7009,
        "isFeatured": state.isFeatured,
        "imageUrls": state.imageUrls
            .where((u) => u.startsWith('http://') || u.startsWith('https://'))
            .toList(),
        "amenityIds": state.selectedAmenityIds
            .map((id) => int.tryParse(id) ?? 0)
            .where((id) => id > 0)
            .toList(),
      };

      final rtId = int.tryParse(state.roomTypeId);
      if (rtId == null || rtId <= 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'Vui lòng chọn loại phòng',
        );
        return false;
      }
      body["roomTypeId"] = rtId;

      if (isEdit) {
        await dio.put('${ApiConstants.hostRooms}/${state.roomId}', data: body);
      } else {
        await dio.post(ApiConstants.hostRooms, data: body);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final createRoomProvider =
    StateNotifierProvider.autoDispose<CreateRoomNotifier, CreateRoomState>((ref) {
      return CreateRoomNotifier(ref);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'room_provider.dart';

class CreateRoomState {
  final int currentStep;
  final String name;
  final String description;
  final double price;
  final List<XFile> images;
  final List<String> selectedAmenities;
  final double? lat;
  final double? lng;
  final String address;
  final bool isLoading;
  final String? error;

  CreateRoomState({
    this.currentStep = 1,
    this.name = '',
    this.description = '',
    this.price = 0,
    this.images = const [],
    this.selectedAmenities = const [],
    this.lat,
    this.lng,
    this.address = '',
    this.isLoading = false,
    this.error,
  });

  CreateRoomState copyWith({
    int? currentStep,
    String? name,
    String? description,
    double? price,
    List<XFile>? images,
    List<String>? selectedAmenities,
    double? lat,
    double? lng,
    String? address,
    bool? isLoading,
    String? error,
  }) {
    return CreateRoomState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CreateRoomNotifier extends StateNotifier<CreateRoomState> {
  final Ref ref;

  CreateRoomNotifier(this.ref) : super(CreateRoomState());

  void setStep(int step) => state = state.copyWith(currentStep: step);
  
  void updateBasicInfo({String? name, String? description, double? price}) {
    state = state.copyWith(
      name: name ?? state.name,
      description: description ?? state.description,
      price: price ?? state.price,
    );
  }

  void addImages(List<XFile> newImages) {
    final updatedImages = [...state.images, ...newImages].take(5).toList();
    state = state.copyWith(images: updatedImages);
  }

  void removeImage(int index) {
    final updatedImages = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updatedImages);
  }

  void toggleAmenity(String amenity) {
    final updated = List<String>.from(state.selectedAmenities);
    if (updated.contains(amenity)) {
      updated.remove(amenity);
    } else {
      updated.add(amenity);
    }
    state = state.copyWith(selectedAmenities: updated);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  void setAddress(String address) {
    state = state.copyWith(address: address);
  }

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      
      // Chuẩn bị dữ liệu multipart
      final formData = FormData.fromMap({
        'name': state.name,
        'description': state.description,
        'price': state.price,
        'address': state.address,
        'lat': state.lat,
        'lng': state.lng,
        'amenities': state.selectedAmenities,
      });

      for (var image in state.images) {
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      // await dio.post('/api/rooms', data: formData);
      
      // Giả lập thành công
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final createRoomProvider = StateNotifierProvider<CreateRoomNotifier, CreateRoomState>((ref) {
  return CreateRoomNotifier(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../rooms/providers/room_provider.dart';

class UserModel {
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  final String role; // 'USER' or 'HOST'
  final String? bio;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    required this.role,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      avatar: json['avatar'],
      role: json['role'] ?? 'USER',
      bio: json['bio'],
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    String? bio,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      phone: phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role,
      bio: bio ?? this.bio,
    );
  }
}

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  ProfileState({this.user, this.isLoading = false, this.error});

  ProfileState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(ProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // final dio = ref.read(dioProvider);
      // final response = await dio.get('/api/users/profile');
      // final user = UserModel.fromJson(response.data);
      
      // Giả lập dữ liệu
      await Future.delayed(const Duration(seconds: 1));
      final user = UserModel(
        userId: 'u123',
        name: 'Nguyễn Văn A',
        phone: '0901234567',
        email: 'vana@gmail.com',
        avatar: 'https://i.pravatar.cc/150?u=u123',
        role: 'HOST',
        bio: 'Yêu du lịch và thích khám phá những vùng đất mới.',
      );

      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    state = state.copyWith(isLoading: true);
    try {
      // final dio = ref.read(dioProvider);
      // await dio.patch('/api/users/profile', data: { ... });
      
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String currentPass, String newPass) async {
    state = state.copyWith(isLoading: true);
    try {
      // await ref.read(dioProvider).put('/api/users/change-password', data: { ... });
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'jwt_token');
    // Clear other states if necessary
    state = ProfileState();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

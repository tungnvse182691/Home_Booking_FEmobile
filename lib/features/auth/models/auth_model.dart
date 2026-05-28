import '../../../core/constants/api_constants.dart';

class LoginRequest {
  final String emailOrPhone;
  final String password;

  LoginRequest({required this.emailOrPhone, required this.password});

  Map<String, dynamic> toJson() => {
    'emailOrPhone': emailOrPhone,
    'password': password,
  };
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'password': password,
  };
}

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatarUrl;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: (json['userId'] ?? json['id'] ?? '').toString(),
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    role: json['role'] ?? 'CUSTOMER',
    status: json['status'] ?? 'ACTIVE',
    avatarUrl: ApiConstants.formatImageUrl(json['avatarUrl']),
  );

  UserModel copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? avatarUrl,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String expiresAt;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
    expiresAt: json['expiresAt']?.toString() ?? '',
    user: UserModel.fromJson(json['user'] ?? {}),
  );
}

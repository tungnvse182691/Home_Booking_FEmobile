import 'package:flutter/foundation.dart';

class ApiConstants {
  // Change this to your deployed Railway domain once you deploy
  static const String _productionUrl = 'https://your-backend-service.up.railway.app';

  // Set useProduction to true and update productionUrl with your Railway public domain when ready.
  static const String productionUrl = 'https://homebookingbe-production.up.railway.app';
  static const bool useProduction = true;

  static String get baseUrl => useProduction 
      ? productionUrl 
      : (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');

  // Auth
  static const String login = "/api/auth/login";
  static const String register = "/api/auth/register";
  static const String logout = "/api/auth/logout";
  static const String changePassword = "/api/auth/change-password";
  static const String forgotPassword = "/api/auth/forgot-password";
  static const String resetPassword = "/api/auth/reset-password";

  // Profile (riÃªng, khÃ´ng náº±m dÆ°á»›i /auth/)
  static const String profile = "/api/profile";
  // Auth - current user
  static const String authMe = "/api/auth/me";

  // Rooms
  static const String rooms = "/api/rooms";
  static const String roomDetail = "/api/rooms/"; // + {id}
  static const String myRooms = "/api/rooms/my-rooms";
  static const String roomTypes = "/api/room-types";
  static const String amenities = "/api/amenities";

  // Booking
  static const String bookings = "/api/bookings";
  static const String myBookings = "/api/bookings/my-bookings";
  static const String myHistory = "/api/bookings/my-history";

  // Payments
  static const String createPayment = "/api/payments/create";
  static const String confirmPayment = "/api/payments/confirm";

  // Favorites
  static const String favorites = "/api/favorites";

  // Host
  static const String hostDashboard = "/api/host/dashboard";
  static const String hostRooms = "/api/host/rooms";
  static const String hostRevenue = "/api/host/reports/revenue";
  static const String hostBookings = "/api/host/bookings";

  // Admin
  static const String adminDashboard = "/api/admin/dashboard";
  static const String adminUsers = "/api/admin/users";
  static const String adminPayments = "/api/admin/payments";
  static const String adminRevenue = "/api/admin/reports/revenue";
  static const String adminRooms = "/api/admin/rooms";

  static String? formatImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // Remove leading slash if present
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return "$baseUrl/$cleanUrl";
  }
}

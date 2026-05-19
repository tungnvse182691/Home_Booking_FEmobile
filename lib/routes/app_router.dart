import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth_screens.dart';
import '../features/rooms/screens/home_screen.dart';
import '../features/rooms/screens/room_detail_screen.dart';
import '../features/rooms/screens/create_room_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/booking/screens/payment_screen.dart';
import '../features/booking/screens/booking_success_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/booking_detail_screen.dart';
import '../features/history/models/booking_history_model.dart';
import '../features/review/screens/review_screen.dart';
import '../features/review/screens/all_reviews_screen.dart';
import '../features/review/screens/my_reviews_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/favorite/screens/favorite_screen.dart';
import '../features/rooms/screens/my_rooms_screen.dart';
import '../features/rooms/screens/edit_room_screen.dart';
import '../features/rooms/screens/room_calendar_screen.dart';
import '../features/notification/screens/notification_screen.dart';
import '../features/history/screens/reschedule_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/reschedule/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        final data = state.extra as Map<String, dynamic>;
        return RescheduleScreen(
          bookingId: bookingId,
          roomId: data['roomId'],
          roomName: data['roomName'],
          currentCheckIn: data['currentCheckIn'],
          currentCheckOut: data['currentCheckOut'],
          blockedDates: data['blockedDates'] ?? [],
          pricePerNight: data['pricePerNight'],
        );
      },
    ),
    GoRoute(
      path: '/my-rooms',
      builder: (context, state) => const MyRoomsScreen(),
    ),
    GoRoute(
      path: '/edit-room/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return EditRoomScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/room-calendar/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        final roomName = state.extra as String;
        return RoomCalendarScreen(roomId: roomId, roomName: roomName);
      },
    ),
    GoRoute(
      path: '/favorite',
      builder: (context, state) => const FavoriteScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ReviewScreen(
          bookingId: data['bookingId'],
          roomId: data['roomId'],
          roomName: data['roomName'],
          thumbnailUrl: data['thumbnailUrl'],
        );
      },
    ),
    GoRoute(
      path: '/all-reviews',
      builder: (context, state) {
        final roomId = state.extra as String;
        return AllReviewsScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/my-reviews',
      builder: (context, state) => const MyReviewsScreen(),
    ),
    GoRoute(
      path: '/booking-detail/:id',
      builder: (context, state) {
        final booking = state.extra as BookingHistoryModel;
        return BookingDetailScreen(booking: booking);
      },
    ),
    GoRoute(
      path: '/create-room',
      builder: (context, state) => const CreateRoomScreen(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/room-detail/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return RoomDetailScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return PaymentScreen(bookingData: data);
      },
    ),
    GoRoute(
      path: '/booking-success',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return BookingSuccessScreen(successData: data);
      },
    ),
  ],
);

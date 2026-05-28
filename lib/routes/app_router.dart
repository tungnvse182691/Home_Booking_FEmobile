import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';

import '../features/rooms/screens/customer_home_screen.dart';
import '../features/rooms/screens/room_detail_screen.dart';
import '../features/rooms/screens/create_room_screen.dart';
import '../features/rooms/screens/my_rooms_screen.dart';
import '../features/rooms/screens/edit_room_screen.dart';
import '../features/rooms/screens/room_calendar_screen.dart';

import '../features/map/screens/map_screen.dart';

import '../features/booking/screens/payment_screen.dart';
import '../features/booking/screens/booking_create_screen.dart';
import '../features/booking/screens/booking_success_screen.dart';
import '../features/booking/screens/booking_history_screen.dart';

import '../features/history/screens/booking_detail_screen.dart';
import '../features/history/models/booking_history_model.dart';
import '../features/history/screens/reschedule_screen.dart';

import '../features/review/screens/review_screen.dart';
import '../features/review/screens/all_reviews_screen.dart';
import '../features/review/screens/my_reviews_screen.dart';

import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';

import '../features/favorite/screens/favorite_screen.dart';
import '../features/notification/screens/notification_screen.dart';

// Host
import '../features/host/screens/host_dashboard_screen.dart';
import '../features/host/screens/host_rooms_screen.dart';
import '../features/host/screens/host_revenue_screen.dart';
import '../features/host/screens/host_bookings_screen.dart';

// Admin
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_payments_screen.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_rooms_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isAuthPath =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn) {
        return isAuthPath ? null : '/login';
      }

      // Logged in
      if (isAuthPath) {
        if (authState.role == 'HOST') return '/host/dashboard';
        if (authState.role == 'ADMIN') return '/admin/dashboard';
        return '/home';
      }

      final role = authState.role;
      final path = state.matchedLocation;

      if (path == '/' || path == '/home') {
        if (role == 'HOST') return '/host/dashboard';
        if (role == 'ADMIN') return '/admin/dashboard';
      }

      if (role == 'CUSTOMER') {
        if (path.startsWith('/host') || path.startsWith('/admin')) {
          return '/home';
        }
      } else if (role == 'HOST') {
        if (path.startsWith('/admin')) {
          return '/host/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Shell Route for Navigation Bar
      ShellRoute(
        builder: (context, state, child) {
          final role = ref.read(authStateProvider)?.role ?? 'CUSTOMER';
          if (role == 'ADMIN') return child;
          return MainScaffold(role: role, child: child);
        },
        routes: [
          // Customer Tabs
          GoRoute(
            path: '/home',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoriteScreen(),
          ),
          GoRoute(
            path: '/booking/history',
            builder: (context, state) => const BookingHistoryScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Host Tabs
          GoRoute(
            path: '/host/dashboard',
            builder: (context, state) => const HostDashboardScreen(),
          ),
          GoRoute(
            path: '/host/rooms',
            builder: (context, state) => const HostRoomsScreen(),
          ),
          GoRoute(
            path: '/host/revenue',
            builder: (context, state) => const HostRevenueScreen(),
          ),
          GoRoute(
            path: '/host/bookings',
            builder: (context, state) => const HostBookingsScreen(),
          ),
        ],
      ),

      // Other Customer Routes (Outside Shell if needed, or keep inside if they should show navbar)
      // Usually details don't show the bottom navbar.
      GoRoute(
        path: '/room-detail/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/booking/create',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId']!;
          return BookingCreateScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/booking/payment',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return PaymentScreen(
            bookingId: data['bookingId'].toString(),
            bookingCode: data['bookingCode']?.toString() ?? '',
            paymentMethod: data['paymentMethod']?.toString() ?? 'CASH',
            totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
            roomName: data['roomName']?.toString() ?? '',
            checkIn: data['checkIn'] as DateTime,
            checkOut: data['checkOut'] as DateTime,
          );
        },
      ),
      GoRoute(
        path: '/booking/success',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return BookingSuccessScreen(successData: data);
        },
      ),

      // Host specific routes not in tabs
      GoRoute(
        path: '/create-room',
        builder: (context, state) => const CreateRoomScreen(),
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

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/payments',
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/rooms',
        builder: (context, state) => const AdminRoomsScreen(),
      ),

      // Shared/Miscellaneous
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/booking-detail/:id',
        builder: (context, state) {
          final booking = state.extra as BookingHistoryModel;
          return BookingDetailScreen(booking: booking);
        },
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
        path: '/review',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return ReviewScreen(
            bookingId: data['bookingId'],
            roomId: data['roomId'],
            roomName: data['roomName'],
            thumbnailUrl: data['thumbnailUrl'],
            checkOutDate: data['checkOutDate'] is DateTime
                ? data['checkOutDate'] as DateTime
                : (data['checkOutDate'] is String
                    ? DateTime.tryParse(data['checkOutDate'])
                    : null),
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
    ],
  );
});

class MainScaffold extends StatelessWidget {
  final String role;
  final Widget child;

  const MainScaffold({super.key, required this.role, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final tabs = role == 'HOST' ? _hostTabs : _customerTabs;

    int currentIndex = tabs.indexWhere((tab) => location == tab.path);
    if (currentIndex == -1) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(tabs[index].path),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: tabs.map((tab) => tab.item).toList(),
      ),
    );
  }

  static final List<_TabData> _customerTabs = [
    _TabData(
      path: '/home',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
    ),
    _TabData(
      path: '/favorites',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: 'Favorites',
      ),
    ),
    _TabData(
      path: '/booking/history',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'History',
      ),
    ),
    _TabData(
      path: '/notifications',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.notifications),
        label: 'Notifications',
      ),
    ),
    _TabData(
      path: '/profile',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ),
  ];

  static final List<_TabData> _hostTabs = [
    _TabData(
      path: '/host/dashboard',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    ),
    _TabData(
      path: '/host/rooms',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Rooms',
      ),
    ),
    _TabData(
      path: '/host/revenue',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.payments),
        label: 'Revenue',
      ),
    ),
    _TabData(
      path: '/profile',
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ),
  ];
}

class _TabData {
  final String path;
  final BottomNavigationBarItem item;

  _TabData({required this.path, required this.item});
}


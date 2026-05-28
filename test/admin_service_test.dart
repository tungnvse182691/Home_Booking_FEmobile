import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:home_booking/features/admin/services/admin_service.dart';
import 'package:home_booking/core/constants/api_constants.dart';

void main() {
  test('Test AdminService getUsers and getRevenueReport', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      contentType: 'application/json',
    ));

    // Login
    final loginResponse = await dio.post('/api/auth/login', data: {
      'emailOrPhone': 'admin@gmail.com',
      'password': 'password123',
    });
    final token = loginResponse.data['data']['accessToken'];
    print('Token: $token');

    dio.options.headers['Authorization'] = 'Bearer $token';

    final adminService = AdminService(dio);

    try {
      print('Calling getDashboard()...');
      final response = await dio.get(ApiConstants.adminDashboard);
      print('Raw dashboard response: ${response.data}');
      final dashboard = await adminService.getDashboard();
      print('Dashboard data: totalUsers=${dashboard.totalUsers}, totalRooms=${dashboard.totalRooms}, totalBookings=${dashboard.totalBookings}, totalRevenue=${dashboard.totalRevenue}');
    } catch (e, stack) {
      print('Error in getDashboard(): $e');
      print(stack);
    }

    try {
      print('Calling getPayments()...');
      final response = await dio.get(ApiConstants.adminPayments);
      print('Raw payments response: ${response.data}');
      final payments = await adminService.getPayments();
      print('Payments count: ${payments.length}');
    } catch (e, stack) {
      print('Error in getPayments(): $e');
      print(stack);
    }

    try {
      print('Calling getUsers()...');
      final response = await dio.get(ApiConstants.adminUsers);
      print('Raw users response: ${response.data}');
      final users = await adminService.getUsers();
      print('Users count: ${users.length}');
      if (users.isNotEmpty) {
        print('First user: ${users.first.fullName}');
      }
    } catch (e, stack) {
      print('Error in getUsers(): $e');
      print(stack);
    }

    try {
      print('Calling getRevenueReport()...');
      final response = await dio.get(ApiConstants.adminRevenue);
      print('Raw revenue response: ${response.data}');
      final revenue = await adminService.getRevenueReport();
      print('Revenue items count: ${revenue.length}');
      if (revenue.isNotEmpty) {
        print('First revenue item: ${revenue.first.month} -> ${revenue.first.amount}');
      }
    } catch (e, stack) {
      print('Error in getRevenueReport(): $e');
      print(stack);
    }
  });
}

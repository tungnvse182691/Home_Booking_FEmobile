import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:home_booking/core/network/dio_client.dart';
import 'package:home_booking/features/admin/providers/admin_provider.dart';

void main() {
  test('Test Admin providers', () async {
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

    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
      ],
    );

    // Watch adminUsersProvider
    final usersSubscription = container.listen(
      adminUsersProvider,
      (previous, next) {
        print('users status: $next');
      },
      fireImmediately: true,
    );

    await Future.delayed(const Duration(seconds: 2));

    final usersState = container.read(adminUsersProvider);
    if (usersState is AsyncError) {
      print('Users error: ${(usersState as AsyncError).error}');
      print((usersState as AsyncError).stackTrace);
    } else {
      print('Users data: ${usersState.value?.length}');
    }

    // Watch adminRevenueProvider
    final revenueState = await container.read(adminRevenueProvider.future);
    print('Revenue items count: ${revenueState.length}');

    container.dispose();
  });
}

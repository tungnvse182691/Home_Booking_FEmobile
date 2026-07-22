import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/app_theme.dart';
import 'routes/app_router.dart';
import 'core/network/dio_client.dart';
import 'features/auth/providers/auth_provider.dart';

/// Hàm khởi chạy chính (Entry Point) của ứng dụng Flutter
void main() async {
  // Đảm bảo các khung hệ thống của Flutter Framework đã được khởi tạo hoàn tất trước khi chạy mã bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo định dạng ngày tháng tiếng Việt (vi_VN) cho các thư viện intl
  await initializeDateFormatting('vi_VN', null);
  
  // Khởi tạo ProviderContainer của Riverpod để có thể đọc State trước khi dựng UI
  final container = ProviderContainer();
  
  // Kiểm tra phiên đăng nhập tự động của người dùng (nếu có Token trong bộ nhớ)
  await container.read(authStateProvider.notifier).checkAuth();

  // Khởi chạy ứng dụng Flutter với ProviderScope của Riverpod
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HomeBookingApp(),
    ),
  );
}

/// Widget gốc (Root Widget) của toàn bộ ứng dụng StayEase
class HomeBookingApp extends ConsumerWidget {
  const HomeBookingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đọc router cấu hình điều hướng GoRouter từ appRouterProvider
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'StayEase',                                   // Tên ứng dụng
      debugShowCheckedModeBanner: false,                   // Ẩn banner DEBUG ở góc màn hình
      theme: AppTheme.lightTheme,                          // Áp dụng Theme giao diện đã cấu hình
      routerConfig: router,                                // Cấu hình Router điều hướng chính
      scaffoldMessengerKey: scaffoldMessengerKey,          // Phím hiển thị SnackBar toàn cục
      localizationsDelegates: const [                       // Cấu hình ngôn ngữ hệ thống
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),                                // Hỗ trợ ngôn ngữ Tiếng Việt
      ],
      locale: const Locale('vi', 'VN'),                    // Thiết lập locale mặc định là Việt Nam
    );
  }
}


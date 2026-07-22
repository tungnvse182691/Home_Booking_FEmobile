import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../host/models/host_model.dart';

/// ============================================================================
/// MÀN HÌNH BÁO CÁO DOANH THU TOÀN HỆ THỐNG (DÀNH CHO ADMIN)
/// Hiển thị tổng quan doanh thu theo quý (Q1-Q4) và danh sách báo cáo chi tiết theo tháng
/// ============================================================================

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi dữ liệu báo cáo doanh thu từ adminRevenueProvider
    final revenueAsync = ref.watch(adminRevenueProvider);
    // Định dạng tiền tệ Việt Nam (VD: 15.000.000 đ)
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('Báo cáo hệ thống'),
          ],
        ),
      ),
      // Xử lý các trạng thái AsyncValue (Loading, Error, Data)
      body: revenueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải báo cáo: $err')),
        data: (data) => RefreshIndicator(
          // Kéo xuống để nạp lại dữ liệu báo cáo mới nhất
          onRefresh: () => ref.refresh(adminRevenueProvider.future),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doanh thu toàn hệ thống',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Widget hiển thị tổng doanh thu chia theo 4 Quý trong năm (Q1, Q2, Q3, Q4)
                _QuarterSummary(data: data, currencyFormat: currencyFormat),
                const SizedBox(height: 24),
                // Danh sách chi tiết doanh thu theo từng tháng/kỳ
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.show_chart)),
                          title: Text(item.month.contains('-') ? 'Kỳ ${item.month}' : 'Tháng ${item.month}'),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currencyFormat.format(item.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget tính toán và hiển thị Thẻ Tổng quan Doanh thu theo 4 Quý (Q1 - Q4)
class _QuarterSummary extends StatelessWidget {
  final List<RevenueReportItem> data;
  final NumberFormat currencyFormat;

  const _QuarterSummary({required this.data, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    // Map lưu giữ tổng số tiền của từng Quý (Q1, Q2, Q3, Q4)
    final quarterTotals = <String, double>{'Q1': 0, 'Q2': 0, 'Q3': 0, 'Q4': 0};

    // Vòng lặp duyệt qua từng mục báo cáo tháng từ API để phân loại vào Quý
    for (final item in data) {
      int? monthValue;
      if (item.month.contains('-')) {
        final parts = item.month.split('-');
        if (parts.length >= 2) {
          monthValue = int.tryParse(parts[1]);
        }
      }
      monthValue ??= int.tryParse(item.month.replaceAll(RegExp(r'[^0-9]'), ''));
      if (monthValue == null || monthValue < 1 || monthValue > 12) continue;
      
      // Công thức tính Quý dựa trên số tháng: Q1 (1-3), Q2 (4-6), Q3 (7-9), Q4 (10-12)
      final quarter = ((monthValue - 1) ~/ 3) + 1;
      quarterTotals['Q$quarter'] = (quarterTotals['Q$quarter'] ?? 0) + item.amount;
    }

    // Hiển thị 4 thẻ tượng trưng cho 4 Quý
    return Row(
      children: quarterTotals.entries.map((entry) {
        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currencyFormat.format(entry.value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


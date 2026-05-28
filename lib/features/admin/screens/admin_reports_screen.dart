import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../host/models/host_model.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(adminRevenueProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo hệ thống')),
      body: revenueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminRevenueProvider.future),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Doanh thu toàn hệ thống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _QuarterSummary(data: data, currencyFormat: currencyFormat),
                const SizedBox(height: 24),
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

class _QuarterSummary extends StatelessWidget {
  final List<RevenueReportItem> data;
  final NumberFormat currencyFormat;

  const _QuarterSummary({required this.data, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final quarterTotals = <String, double>{'Q1': 0, 'Q2': 0, 'Q3': 0, 'Q4': 0};

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
      final quarter = ((monthValue - 1) ~/ 3) + 1;
      quarterTotals['Q$quarter'] = (quarterTotals['Q$quarter'] ?? 0) + item.amount;
    }

    return Row(
      children: quarterTotals.entries.map((entry) {
        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8), // Gỉam padding một chút
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _selectedStatus = '';
  String _selectedMethod = '';

  Future<void> _applyFilter() async {
    ref
        .read(adminPaymentsProvider.notifier)
        .fetchPayments(
          status: _selectedStatus.isEmpty ? null : _selectedStatus,
          method: _selectedMethod.isEmpty ? null : _selectedMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _applyFilter),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'PENDING', child: Text('Chờ TT')),
                      DropdownMenuItem(
                        value: 'SUCCESS',
                        child: Text('Thành công'),
                      ),
                      DropdownMenuItem(
                        value: 'FAILED',
                        child: Text('Thất bại'),
                      ),
                      DropdownMenuItem(
                        value: 'REFUNDED',
                        child: Text('Hoàn tiền'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedStatus = v ?? '');
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Phương thức',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'VNPAY', child: Text('VNPay')),
                      DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt')),
                      DropdownMenuItem(
                        value: 'BANK_CARD',
                        child: Text('Thẻ ngân hàng'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedMethod = v ?? '');
                      _applyFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Payment list ─────────────────────────────────────────────────
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _applyFilter,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có giao dịch nào',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _applyFilter,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Mã đơn')),
                          DataColumn(label: Text('Khách hàng')),
                          DataColumn(label: Text('Số tiền')),
                          DataColumn(label: Text('Phương thức')),
                          DataColumn(label: Text('Trạng thái')),
                          DataColumn(label: Text('Ngày')),
                        ],
                        rows: payments
                            .map(
                              (p) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      p.bookingCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      p.customerName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormat.format(p.amount),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_methodLabel(p.method))),
                                  DataCell(_statusCell(p.status)),
                                  DataCell(
                                    Text(
                                      DateFormat(
                                        'dd/MM/yy',
                                      ).format(p.createdAt),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'VNPAY':
        return 'VNPay';
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_CARD':
        return 'Thẻ NH';
      case 'E_WALLET':
        return 'Ví điện tử';
      default:
        return method;
    }
  }

  Widget _statusCell(String status) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        color = Colors.green;
        label = 'Thành công';
        break;
      case 'FAILED':
        color = Colors.red;
        label = 'Thất bại';
        break;
      case 'PENDING':
        color = Colors.orange;
        label = 'Chờ TT';
        break;
      case 'REFUNDED':
        color = Colors.purple;
        label = 'Hoàn tiền';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

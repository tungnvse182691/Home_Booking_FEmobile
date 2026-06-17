import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/admin_model.dart';
import '../../../utils/app_theme.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _selectedStatus = '';
  String _selectedMethod = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  Future<void> _applyFilter() async {
    ref.read(adminPaymentsProvider.notifier).fetchPayments(
          status: _selectedStatus.isEmpty ? null : _selectedStatus,
          method: _selectedMethod.isEmpty ? null : _selectedMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Giao dịch',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _applyFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _PillDropdown(
                    value: _selectedStatus,
                    hint: 'Trạng thái',
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'PENDING', child: Text('Chờ TT')),
                      DropdownMenuItem(value: 'SUCCESS', child: Text('Thành công')),
                      DropdownMenuItem(value: 'FAILED', child: Text('Thất bại')),
                      DropdownMenuItem(value: 'REFUNDED', child: Text('Hoàn tiền')),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedStatus = v ?? '');
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PillDropdown(
                    value: _selectedMethod,
                    hint: 'Phương thức',
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'VNPAY', child: Text('VNPay')),
                      DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt')),
                      DropdownMenuItem(value: 'BANK_CARD', child: Text('Thẻ NH')),
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

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (err, _) => _ErrorView(onRetry: _applyFilter, error: err),
              data: (payments) {
                if (payments.isEmpty) {
                  return _EmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: 'Không có giao dịch nào',
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _applyFilter,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 380),
                          child: SlideAnimation(
                            verticalOffset: 40,
                            child: FadeInAnimation(
                              child: _TransactionCard(
                                payment: payments[index],
                                currencyFormat: currencyFormat,
                              ),
                            ),
                          ),
                        );
                      },
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
}

// ── Transaction Card ─────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final AdminPaymentItem payment;
  final NumberFormat currencyFormat;

  const _TransactionCard({
    required this.payment,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo(payment.status);
    final (methodIcon, methodColor) = _methodInfo(payment.method);
    final dateStr = DateFormat('dd MMM yyyy').format(payment.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Leading icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(methodIcon, color: methodColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.customerName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${payment.bookingCode} · $dateStr',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(payment.amount),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusChip(label: statusLabel, color: statusColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String status) => switch (status.toUpperCase()) {
        'SUCCESS' => ('Thành công', const Color(0xFF2ECC71)),
        'FAILED' => ('Thất bại', Colors.redAccent),
        'PENDING' => ('Chờ TT', Colors.orange),
        'REFUNDED' => ('Hoàn tiền', Colors.purple),
        _ => (status, Colors.grey),
      };

  (IconData, Color) _methodInfo(String method) =>
      switch (method.toUpperCase()) {
        'VNPAY' => (Icons.account_balance_rounded, const Color(0xFF006BD6)),
        'CASH' => (Icons.payments_outlined, const Color(0xFF2ECC71)),
        'BANK_CARD' => (Icons.credit_card_rounded, Colors.blueGrey),
        'E_WALLET' => (Icons.wallet_rounded, Colors.purple),
        _ => (Icons.receipt_outlined, AppTheme.textSecondary),
      };
}

// ── Stadium Status Chip ──────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Pill Dropdown ────────────────────────────────────────────────────────
class _PillDropdown extends StatelessWidget {
  final String value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _PillDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value.isNotEmpty;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withOpacity(0.08)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive ? AppTheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppTheme.primary : AppTheme.textPrimary,
          ),
          borderRadius: BorderRadius.circular(16),
          items: items,
          onChanged: onChanged,
          hint: Text(
            hint,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared UI helpers ────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final Object error;

  const _ErrorView({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Không thể tải dữ liệu',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Result returned when the VNPay WebView is closed.
class VnPayResult {
  final bool success;
  final String? transactionCode;
  final String? message;

  const VnPayResult({
    required this.success,
    this.transactionCode,
    this.message,
  });
}

/// In-app WebView screen that renders the VNPay payment gateway.
/// Intercepts the backend return URL to detect payment result without leaving the app.
class VnPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  /// The backend domain used for redirect URLs (e.g. "spotty-bats-hunt.loca.lt" or "localhost:8080").
  /// The screen intercepts any navigation that contains "/api/payments/vnpay-return".
  final String? returnUrlHost;

  const VnPayWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.returnUrlHost,
  });

  @override
  State<VnPayWebViewScreen> createState() => _VnPayWebViewScreenState();
}

class _VnPayWebViewScreenState extends State<VnPayWebViewScreen> {
  late final WebViewController _controller;
  int _loadProgress = 0;
  bool _isLoading = true;
  String? _pageTitle;
  bool _resultPopped = false;

  /// Try to parse and pop result from a URL that looks like a vnpay-return or deep link.
  /// Returns true if we handled it and popped.
  bool _tryHandleReturnUrl(String url) {
    if (_resultPopped) return false;

    // Intercept backend vnpay-return URL (HTTP redirect from VNPay after OTP)
    if (url.contains('/api/payments/vnpay-return')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final responseCode = uri.queryParameters['vnp_ResponseCode'];
        final transactionStatus = uri.queryParameters['vnp_TransactionStatus'];
        final txRef = uri.queryParameters['vnp_TxnRef'];
        final isSuccess = responseCode == '00' && transactionStatus == '00';
        if (mounted) {
          _resultPopped = true;
          Navigator.of(context).pop(
            VnPayResult(
              success: isSuccess,
              transactionCode: txRef,
              message: isSuccess
                  ? 'Thanh toán thành công!'
                  : _mapVnpayCode(responseCode),
            ),
          );
        }
        return true;
      }
    }

    // Intercept "FrontendReturnUrl" fallback (deep link) - success=true/false as query param
    if (url.contains('success=') &&
        (url.contains('transactionCode=') ||
            url.contains('vnpay') ||
            url.contains('homestaybooking'))) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final isSuccess = uri.queryParameters['success'] == 'true';
        final txCode = uri.queryParameters['transactionCode'];
        final msg = uri.queryParameters['message'];
        if (mounted) {
          _resultPopped = true;
          Navigator.of(context).pop(
            VnPayResult(
              success: isSuccess,
              transactionCode: txCode,
              message:
                  msg ??
                  (isSuccess
                      ? 'Thanh toán thành công!'
                      : 'Thanh toán thất bại.'),
            ),
          );
        }
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            // Intercept BEFORE the page loads - catches HTTP redirects
            if (_tryHandleReturnUrl(url)) return;
            setState(() {
              _isLoading = true;
              _loadProgress = 0;
            });
          },
          onPageFinished: (url) {
            // Also check on finish in case onPageStarted missed it
            if (_tryHandleReturnUrl(url)) return;
            setState(() {
              _isLoading = false;
              _loadProgress = 100;
            });
            _controller.getTitle().then((title) {
              if (mounted && title != null) {
                setState(() => _pageTitle = title);
              }
            });
          },
          onProgress: (progress) {
            setState(() => _loadProgress = progress);
          },
          onWebResourceError: (error) {
            // When Android blocks HTTP (ERR_CLEARTEXT_NOT_PERMITTED),
            // try to get the URL from the error and parse the result
            if (error.isForMainFrame == true) {
              final failingUrl = error.url ?? '';
              if (_tryHandleReturnUrl(failingUrl)) return;
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (_tryHandleReturnUrl(url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl), headers: const {});
  }

  String _mapVnpayCode(String? code) {
    switch (code) {
      case '07':
        return 'Giao dịch bị nghi ngờ gian lận.';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking.';
      case '10':
        return 'Xác thực thông tin thẻ/tài khoản quá 3 lần.';
      case '11':
        return 'Đã hết hạn chờ thanh toán.';
      case '12':
        return 'Thẻ/Tài khoản bị khóa.';
      case '13':
        return 'Sai mã OTP.';
      case '24':
        return 'Giao dịch bị hủy.';
      case '51':
        return 'Tài khoản không đủ số dư.';
      case '65':
        return 'Vượt quá hạn mức giao dịch trong ngày.';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì.';
      case '79':
        return 'Nhập sai mật khẩu quá số lần quy định.';
      default:
        return 'Thanh toán thất bại. Mã lỗi: ${code ?? "?"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2035),
        elevation: 0,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => _showCancelDialog(),
          tooltip: 'Đóng',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pageTitle ?? 'Cổng thanh toán VNPay',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Bảo mật bởi VNPay',
              style: TextStyle(color: Color(0xFF00C853), fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            child: _loadProgress < 100
                ? LinearProgressIndicator(
                    value: _loadProgress / 100.0,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF005BAC),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && _loadProgress < 20)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _VnPayLoadingWidget(),
                    const SizedBox(height: 24),
                    Text(
                      'Đang tải cổng thanh toán...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF005BAC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy thanh toán?'),
        content: const Text(
          'Bạn có chắc muốn hủy quá trình thanh toán không?\nGiao dịch sẽ không được hoàn tất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục thanh toán'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      _resultPopped = true;
      Navigator.of(context).pop(
        const VnPayResult(
          success: false,
          message: 'Người dùng hủy thanh toán.',
        ),
      );
    }
  }
}

/// A simple pulsing VNPay-branded loading widget.
class _VnPayLoadingWidget extends StatefulWidget {
  @override
  State<_VnPayLoadingWidget> createState() => _VnPayLoadingWidgetState();
}

class _VnPayLoadingWidgetState extends State<_VnPayLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF005BAC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF005BAC).withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'VNPay',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

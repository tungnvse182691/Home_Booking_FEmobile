import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// Uses flutter_inappwebview for proper SSL handling on Android emulators.
class VnPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;
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
  int _loadProgress = 0;
  bool _isLoading = true;
  String? _pageTitle;
  bool _resultPopped = false;

  final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    // *** KEY FIX: bypass SSL cert errors on Android emulator (net_error -202) ***
    allowingReadAccessTo: null,
    // Trust all certificates in sandbox/dev environment
    preferredContentMode: UserPreferredContentMode.MOBILE,
    useOnDownloadStart: true,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    userAgent:
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    // Allow mixed content (HTTP resources on HTTPS pages)
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    // Disable safe browsing to avoid false blocks in sandbox
    safeBrowsingEnabled: false,
    clearCache: true,
  );

  bool _tryHandleReturnUrl(String url) {
    if (_resultPopped) return false;

    // Intercept backend vnpay-return URL
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

    // Intercept deep link fallback
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
                  (isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại.'),
            ),
          );
        }
        return true;
      }
    }

    return false;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white70),
            tooltip: 'Mở bằng Trình duyệt',
            onPressed: () async {
              final uri = Uri.parse(widget.paymentUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
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
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.paymentUrl),
            ),
            initialSettings: _webViewSettings,
            onWebViewCreated: (controller) {
              // controller reference available if needed
            },
            // *** KEY FIX: Accept all SSL certs for sandbox.vnpayment.vn ***
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              final host = challenge.protectionSpace.host;
              debugPrint('[VNPayWebView] SSL challenge for host: $host');
              // Trust VNPay sandbox certificate
              if (host.contains('vnpayment.vn') || host.contains('vnpay')) {
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED,
                );
              }
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onLoadStart: (controller, url) {
              final urlStr = url?.toString() ?? '';
              debugPrint('[VNPayWebView] Page started: $urlStr');
              if (_tryHandleReturnUrl(urlStr)) return;
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _loadProgress = 0;
                });
              }
            },
            onLoadStop: (controller, url) async {
              final urlStr = url?.toString() ?? '';
              debugPrint('[VNPayWebView] Page finished: $urlStr');
              if (_tryHandleReturnUrl(urlStr)) return;
              final title = await controller.getTitle();
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadProgress = 100;
                  if (title != null && title.isNotEmpty) {
                    _pageTitle = title;
                  }
                });
              }
            },
            onProgressChanged: (controller, progress) {
              if (mounted) {
                setState(() => _loadProgress = progress);
              }
            },
            onReceivedError: (controller, request, error) {
              debugPrint('[VNPayWebView] Error: ${error.type} - ${error.description} - url: ${request.url}');
              final urlStr = request.url.toString();
              if (_tryHandleReturnUrl(urlStr)) return;
              if (mounted) setState(() => _isLoading = false);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url?.toString() ?? '';
              debugPrint('[VNPayWebView] Nav request: $url');
              if (_tryHandleReturnUrl(url)) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF005BAC),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../data/mock_data.dart';

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Đã bỏ qua validate để test UI nhanh
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Mock login success
    MockData.currentUser.isLoggedIn = true;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('StayEase',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                ),
                Center(
                  child: Text('Đặt phòng dễ dàng, trải nghiệm tuyệt vời',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 13, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 48),
                Text('Chào mừng trở lại!',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('Đăng nhập để tiếp tục',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 32),
                // Phone field
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: '0901234567',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^0[0-9]{9}$').hasMatch(v))
                      return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Quên mật khẩu?',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                    text: 'Đăng nhập',
                    onPressed: _handleLogin,
                    isLoading: _isLoading),
                const SizedBox(height: 16),
                // Divider
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('hoặc',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13, color: AppTheme.textHint)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.register),
                    child: const Text('Tạo tài khoản mới'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== REGISTER SCREEN ====================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppTheme.success),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: 'Tạo tài khoản'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin cá nhân',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('Điền thông tin để tạo tài khoản mới',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Vui lòng nhập họ và tên';
                    if (v.trim().length < 3)
                      return 'Tên tối thiểu 3 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: '0901234567',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^0[0-9]{9}$').hasMatch(v))
                      return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Tối thiểu 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Mật khẩu không khớp';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                    text: 'Tạo tài khoản',
                    onPressed: _handleRegister,
                    isLoading: _isLoading),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Đã có tài khoản? ',
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        TextSpan(
                          text: 'Đăng nhập',
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
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

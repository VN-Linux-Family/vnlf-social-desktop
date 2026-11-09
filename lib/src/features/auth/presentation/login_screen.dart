import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../../../domain/models.dart' show StorageFailure;
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _tabIndex = 0; // 0 = login, 1 = register

  // Login controllers & focus
  final _loginIdController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginIdFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  bool _loginObscure = true;

  // Register controllers & focus
  final _regEmailController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _regEmailFocus = FocusNode();
  final _regUsernameFocus = FocusNode();
  final _regPasswordFocus = FocusNode();
  final _regConfirmFocus = FocusNode();
  bool _regObscure = true;

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    _loginIdFocus.dispose();
    _loginPasswordFocus.dispose();
    _regEmailController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regEmailFocus.dispose();
    _regUsernameFocus.dispose();
    _regPasswordFocus.dispose();
    _regConfirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final login = _loginIdController.text.trim();
    final password = _loginPasswordController.text;

    if (login.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage =
            'Vui lòng nhập đầy đủ email/tên người dùng và mật khẩu.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = await ref
          .read(authControllerProvider.notifier)
          .login(login, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chào mừng trở lại, ${session.displayName}!'),
          backgroundColor: VnlfColors.of(context).brand,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = authErrorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    final email = _regEmailController.text.trim();
    final username = _regUsernameController.text.trim();
    final password = _regPasswordController.text;
    final confirm = _regConfirmPasswordController.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ tất cả các trường.';
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không trùng khớp.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = await ref
          .read(authControllerProvider.notifier)
          .register(email, username, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tạo tài khoản thành công! Chào mừng ${session.displayName}.',
          ),
          backgroundColor: VnlfColors.of(context).brand,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = authErrorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    var canPop = false;
    try {
      canPop = context.canPop();
    } catch (_) {
      try {
        canPop = Navigator.canPop(context);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: colors.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: english ? 'Back' : 'Quay lại',
          icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
          onPressed: () {
            if (canPop) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _tabIndex == 0
              ? (english ? 'Log In' : 'Đăng nhập')
              : (english ? 'Register' : 'Đăng ký'),
          style: VnlfTypography.h3(colors.ink),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
                  border: Border.all(color: colors.line),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Header
                    Center(
                      child: BrandAssets.logo(
                        size: 48,
                        semanticLabel: 'VNLF Social',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vietnam Linux Family',
                      textAlign: TextAlign.center,
                      style: VnlfTypography.h2(colors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      english
                          ? 'Vietnamese Linux & Open Source Community'
                          : 'Cộng đồng Linux & Mã nguồn mở Việt Nam',
                      textAlign: TextAlign.center,
                      style: VnlfTypography.meta(colors.muted),
                    ),
                    const SizedBox(height: 24),

                    // Tab Segment
                    Container(
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                        border: Border.all(color: colors.line),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() {
                                _tabIndex = 0;
                                _errorMessage = null;
                              }),
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusSm,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _tabIndex == 0 ? colors.surface : null,
                                  borderRadius: BorderRadius.circular(
                                    VnlfDimensions.radiusSm,
                                  ),
                                  boxShadow: _tabIndex == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  english ? 'Log In' : 'Đăng nhập',
                                  textAlign: TextAlign.center,
                                  style: VnlfTypography.control(
                                    _tabIndex == 0
                                        ? colors.brand
                                        : colors.muted,
                                    fontWeight: _tabIndex == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() {
                                _tabIndex = 1;
                                _errorMessage = null;
                              }),
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusSm,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _tabIndex == 1 ? colors.surface : null,
                                  borderRadius: BorderRadius.circular(
                                    VnlfDimensions.radiusSm,
                                  ),
                                  boxShadow: _tabIndex == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  english ? 'Register' : 'Đăng ký',
                                  textAlign: TextAlign.center,
                                  style: VnlfTypography.control(
                                    _tabIndex == 1
                                        ? colors.brand
                                        : colors.muted,
                                    fontWeight: _tabIndex == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Message Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: VnlfTypography.meta(colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tab Form Body
                    if (_tabIndex == 0) ...[
                      // LOGIN FORM
                      AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const Key('login-id-field'),
                              controller: _loginIdController,
                              focusNode: _loginIdFocus,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              decoration: InputDecoration(
                                labelText: english
                                    ? 'Email or Username'
                                    : 'Email hoặc Tên người dùng',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: const OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  FocusScope.of(context)
                                      .requestFocus(_loginPasswordFocus),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              key: const Key('login-password-field'),
                              controller: _loginPasswordController,
                              focusNode: _loginPasswordFocus,
                              obscureText: _loginObscure,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: english ? 'Password' : 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _loginObscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _loginObscure = !_loginObscure,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _loading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.brand,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    VnlfDimensions.radiusMd,
                                  ),
                                ),
                              ),
                              child: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    )
                                  : Text(
                                      english
                                          ? 'Enter VNLF Social'
                                          : 'Vào VNLF Social',
                                      style: VnlfTypography.control(
                                        Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // REGISTER FORM
                      AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const Key('reg-email-field'),
                              controller: _regEmailController,
                              focusNode: _regEmailFocus,
                              autofocus: true,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: const OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _regUsernameFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              key: const Key('reg-username-field'),
                              controller: _regUsernameController,
                              focusNode: _regUsernameFocus,
                              autofillHints: const [AutofillHints.newUsername],
                              decoration: InputDecoration(
                                labelText: english
                                    ? 'Username'
                                    : 'Tên người dùng',
                                prefixIcon: const Icon(Icons.alternate_email),
                                border: const OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _regPasswordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              key: const Key('reg-password-field'),
                              controller: _regPasswordController,
                              focusNode: _regPasswordFocus,
                              obscureText: _regObscure,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: english ? 'Password' : 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _regObscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _regObscure = !_regObscure,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _regConfirmFocus.requestFocus(),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              key: const Key('reg-confirm-field'),
                              controller: _regConfirmPasswordController,
                              focusNode: _regConfirmFocus,
                              obscureText: _regObscure,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: english
                                    ? 'Confirm Password'
                                    : 'Nhập lại mật khẩu',
                                prefixIcon: const Icon(Icons.lock_reset),
                                border: const OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleRegister(),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _loading ? null : _handleRegister,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.brand,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    VnlfDimensions.radiusMd,
                                  ),
                                ),
                              ),
                              child: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    )
                                  : Text(
                                      english
                                          ? 'Create Account'
                                          : 'Tạo tài khoản',
                                      style: VnlfTypography.control(
                                        Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Như website: câu báo lỗi của máy chủ theo mã lỗi; không có phản hồi thì
/// báo chưa kết nối được máy chủ.
String authErrorMessage(Object error) => switch (error) {
  HttpFailure(code: 'INVALID_CREDENTIALS') ||
  HttpFailure(statusCode: 401) => vi.api.auth.emailHoacMatKhauKhong,
  HttpFailure(code: 'IDENTITY_TAKEN') ||
  HttpFailure(statusCode: 409) => vi.api.auth.emailHoacUsernameDaDuoc,
  HttpFailure(code: 'ACCOUNT_PENDING_DELETION') =>
    vi.api.auth.taiKhoanDangChoXoa,
  HttpFailure(code: 'ACCOUNT_RESTRICTED') => vi.api.auth.taiKhoanHienKhongThe,
  RateLimited() ||
  HttpFailure(code: 'RATE_LIMITED') ||
  HttpFailure(statusCode: 429) => vi.api.rateLimit.banThaoTacQuaNhanh,
  HttpFailure(code: 'RATE_LIMIT_UNAVAILABLE') =>
    vi.api.rateLimit.dichVuTamThoiChua,
  HttpFailure(statusCode: 422) => vi.miscViews.kiemTraLaiThongTin,
  StorageFailure() => vi.app.chuaLuuDuocPhien,
  HttpFailure(:final statusCode) => format(vi.common.yeuCauThatBai, {
    'status': statusCode,
  }),
  _ => vi.miscViews.chuaKetNoiDuocMayChu,
};

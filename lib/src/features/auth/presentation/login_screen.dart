import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/password_reset_repository.dart';
import '../domain/password_reset.dart';

/// The three forms of the website's sign-in page (`AuthView`). A reset link
/// from the email opens the website, where the new password is set.
enum AuthMode { login, register, forgot }

final passwordResetRepositoryProvider = Provider<PasswordResetRepository>(
  (ref) => offlineFeatures
      ? const FixturePasswordResetRepository()
      : LivePasswordResetRepository(ref.watch(apiClientProvider)),
);

const _resendCooldown = 60;
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _usernamePattern = RegExp(r'^[A-Za-z0-9._]{3,30}$');
final _loginPattern = RegExp(r'^@?[A-Za-z0-9._]{3,30}$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

typedef _Notice = ({bool error, String text});

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late AuthMode _mode = widget.initialMode;
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _submitting = false;
  _Notice? _notice;
  String? _sentTo;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    for (final controller in [_email, _username, _password, _confirm]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in [_email, _username, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _validEmail => _emailPattern.hasMatch(_email.text.trim());
  bool get _validUsername => _usernamePattern.hasMatch(_username.text.trim());
  bool get _validLogin =>
      _validEmail || _loginPattern.hasMatch(_email.text.trim());
  bool get _validPassword => _password.text.length >= 10;
  bool get _passwordsMatch => _password.text == _confirm.text;

  bool get _emailInvalid =>
      _email.text.isNotEmpty &&
      (_mode == AuthMode.login ? !_validLogin : !_validEmail);

  bool get _canSubmit => switch (_mode) {
    AuthMode.forgot => _validEmail,
    AuthMode.register =>
      _validEmail && _validUsername && _validPassword && _passwordsMatch,
    AuthMode.login => _validLogin && _password.text.isNotEmpty,
  };

  void _switch(AuthMode mode) => setState(() {
    _mode = mode;
    _notice = null;
    _sentTo = null;
  });

  void _leave() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_canSubmit) {
      setState(
        () => _notice = (error: true, text: vi.miscViews.kiemTraLaiThongTin),
      );
      return;
    }
    if (_mode == AuthMode.forgot) {
      await _sendResetLink(_email.text.trim(), again: false);
      return;
    }
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (_mode == AuthMode.register) {
        await auth.register(
          _email.text.trim(),
          _username.text.trim(),
          _password.text,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
      if (mounted) _leave();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _notice = (error: true, text: authErrorMessage(error)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendResetLink(String target, {required bool again}) async {
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      await ref.read(passwordResetRepositoryProvider).requestReset(target);
      if (!mounted) return;
      _resendTimer?.cancel();
      setState(() {
        _sentTo = target;
        _resendIn = _resendCooldown;
        if (again) _notice = (error: false, text: vi.miscViews.daGuiLaiEmail);
      });
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _resendIn <= 1) timer.cancel();
        if (mounted) {
          setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
        }
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _notice = (error: true, text: authErrorMessage(error)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < VnlfDimensions.tabletMinWidth;
    final panel = _panel(context, phone: phone, width: size.width);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: phone
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const _AuthArt(phone: true), panel],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 9, child: _AuthArt(phone: false)),
                  Expanded(
                    flex: 11,
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(child: panel),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required bool phone,
    required double width,
  }) {
    final colors = VnlfColors.of(context);
    final muted = VnlfTypography.body(colors.muted);
    final heading = switch (_mode) {
      AuthMode.login =>
        '${vi.miscViews.noiCongDong} ${vi.miscViews.cungXayDung}',
      AuthMode.register =>
        '${vi.miscViews.batDauCauChuyen} ${vi.miscViews.cuaBan}',
      AuthMode.forgot => '${vi.miscViews.datLai} ${vi.miscViews.matKhau}',
    };
    final lead = switch (_mode) {
      AuthMode.login => vi.miscViews.chiaSeDieuBanBiet,
      AuthMode.register => vi.miscViews.taoUsernameTimCongDong,
      AuthMode.forgot => vi.miscViews.nhapEmailDeNhanLien,
    };
    final sent = _mode == AuthMode.forgot && _sentTo != null;
    return Padding(
      padding: phone
          ? const EdgeInsets.fromLTRB(14, 14, 14, 28)
          : EdgeInsets.symmetric(
              horizontal: (width * .08).clamp(30, 120).toDouble(),
              vertical: 30,
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthHead(onHome: _leave),
          SizedBox(height: phone ? 18 : 75),
          // The column stretches its children, so the copy needs its own
          // alignment for the website's 430px limit to apply.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 22, bottom: 12),
                    child: Semantics(
                      header: true,
                      child: Text(
                        heading,
                        style: VnlfTypography.body(colors.ink)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (!sent) Text(lead, style: muted.copyWith(height: 1.6)),
                ],
              ),
            ),
          ),
          if (_mode != AuthMode.forgot)
            _AuthTabs(mode: _mode, onChanged: _switch),
          if (sent) ..._sentOutcome(context) else ..._form(context),
          if (_mode != AuthMode.forgot)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: [
                  VnlfIcon(
                    VnlfLucide.shieldCheck,
                    size: 15,
                    color: colors.muted,
                  ),
                  Flexible(
                    child: Text(vi.miscViews.dangKyMoKhongCan, style: muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _form(BuildContext context) {
    final register = _mode == AuthMode.register;
    final login = _mode == AuthMode.login;
    return [
      if (_notice != null) _AuthAlert(notice: _notice!),
      if (register)
        _AuthField(
          key: const Key('reg-username-field'),
          controller: _username,
          icon: VnlfLucide.atSign,
          hint: vi.miscViews.username,
          error: _username.text.isNotEmpty && !_validUsername
              ? vi.miscViews.usernameCan330Ky
              : null,
          onSubmitted: _submit,
        ),
      _AuthField(
        key: Key(login ? 'login-id-field' : 'reg-email-field'),
        controller: _email,
        icon: login ? VnlfLucide.atSign : VnlfLucide.mail,
        hint: login ? vi.miscViews.emailHoacUsername : vi.miscViews.emailCuaBan,
        keyboardType: login ? TextInputType.text : TextInputType.emailAddress,
        error: _emailInvalid
            ? (login
                  ? vi.miscViews.emailHoacUsernameChuaDung
                  : vi.miscViews.emailChuaDungDinhDang)
            : null,
        onSubmitted: _submit,
      ),
      if (_mode != AuthMode.forgot)
        _AuthField(
          key: Key(login ? 'login-password-field' : 'reg-password-field'),
          controller: _password,
          icon: VnlfLucide.lockKeyhole,
          hint: register
              ? vi.miscViews.matKhauToiThieu10
              : vi.miscViews.matKhau2,
          obscure: !_showPassword,
          onToggleObscure: () => setState(() => _showPassword = !_showPassword),
          error: register && _password.text.isNotEmpty && !_validPassword
              ? vi.miscViews.matKhauCanItNhat
              : null,
          onSubmitted: _submit,
        ),
      if (register)
        _AuthField(
          key: const Key('reg-confirm-field'),
          controller: _confirm,
          icon: VnlfLucide.lockKeyhole,
          hint: vi.miscViews.nhapLaiMatKhau,
          obscure: !_showPassword,
          error: _confirm.text.isNotEmpty && !_passwordsMatch
              ? vi.miscViews.matKhauNhapLaiChua
              : null,
          onSubmitted: _submit,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 17),
          child: _AuthSubmit(
            label: _submitting
                ? (_mode == AuthMode.forgot
                      ? vi.miscViews.dangGui
                      : vi.common.dangXuLy)
                : switch (_mode) {
                    AuthMode.login => vi.miscViews.vaoVnlfSocial,
                    AuthMode.register => vi.miscViews.taoTaiKhoan,
                    AuthMode.forgot => vi.miscViews.guiLienKetDatLai,
                  },
            busy: _submitting,
            onPressed: _canSubmit && !_submitting ? _submit : null,
          ),
        ),
      ),
      if (login)
        _AuthLink(
          label: vi.miscViews.quenMatKhau,
          onPressed: () => _switch(AuthMode.forgot),
        ),
      if (_mode == AuthMode.forgot)
        _AuthLink(
          label: vi.miscViews.quayLaiDangNhap,
          onPressed: () => _switch(AuthMode.login),
        ),
    ];
  }

  List<Widget> _sentOutcome(BuildContext context) {
    final colors = VnlfColors.of(context);
    final muted = VnlfTypography.body(colors.muted).copyWith(height: 1.6);
    return [
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        ),
        child: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brand.withValues(alpha: .12),
                ),
                child: Center(
                  child: VnlfIcon(
                    VnlfLucide.mailCheck,
                    size: 20,
                    color: colors.brand,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      vi.miscViews.kiemTraHopThu,
                      style: VnlfTypography.body(colors.ink)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      format(vi.miscViews.neuEmailDaDangKy, {
                        'email': _sentTo ?? '',
                      }),
                      style: muted,
                    ),
                    Text(vi.miscViews.chuaThayEmail, style: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (_notice != null) _AuthAlert(notice: _notice!),
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: _submitting || _resendIn > 0
                ? null
                : () => _sendResetLink(_sentTo ?? '', again: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.ink,
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              ),
              textStyle: VnlfTypography.body(colors.ink)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            child: Text(
              _submitting
                  ? vi.miscViews.dangGui
                  : _resendIn > 0
                  ? format(vi.miscViews.guiLaiSau, {'seconds': _resendIn})
                  : vi.miscViews.guiLai,
            ),
          ),
        ),
      ),
      _AuthLink(
        label: vi.miscViews.dungEmailKhac,
        onPressed: () => setState(() {
          _sentTo = null;
          _notice = null;
        }),
      ),
      _AuthLink(
        label: vi.miscViews.quayLaiDangNhap,
        onPressed: () => _switch(AuthMode.login),
      ),
    ];
  }
}

/// The brand-green column with the emblem; a 120px band on phones.
class _AuthArt extends StatelessWidget {
  const _AuthArt({required this.phone});
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final ink = const Color(0xFFEDF5E9);
    return Container(
      height: phone ? 120 : null,
      color: colors.isDark ? const Color(0xFF0E3A24) : const Color(0xFF1D6B43),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(child: BrandAssets.logo(size: phone ? 54 : 190)),
          Padding(
            padding: EdgeInsets.only(top: phone ? 5 : 22),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${vi.miscViews.vietNam}\n'),
                  TextSpan(
                    text: vi.miscViews.linuxFamily,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: VnlfTypography.body(ink)
                  .copyWith(height: 1.8, letterSpacing: .4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHead extends ConsumerWidget {
  const _AuthHead({required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    return Row(
      children: [
        InkWell(
          onTap: onHome,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              BrandAssets.logo(size: 30, semanticLabel: 'VNLF Social'),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'VNLF ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: 'Social',
                      style: TextStyle(color: colors.brand),
                    ),
                  ],
                ),
                style: VnlfTypography.body(colors.ink),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: vi.miscViews.doiGiaoDien,
          onPressed: () => ref
              .read(themeModeProvider.notifier)
              .setThemeMode(colors.isDark ? ThemeMode.light : ThemeMode.dark),
          icon: VnlfIcon(
            colors.isDark ? VnlfLucide.sun : VnlfLucide.moon,
            size: 18,
            color: colors.muted,
          ),
        ),
      ],
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    Widget tab(String label, AuthMode value) {
      final active = mode == value;
      return Semantics(
        selected: active,
        button: true,
        child: InkWell(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? colors.brand : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              style: VnlfTypography.body(active ? colors.ink : colors.muted)
                  .copyWith(fontWeight: active ? FontWeight.w700 : null),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 42),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        spacing: 24,
        children: [
          tab(vi.common.dangNhap, AuthMode.login),
          tab(vi.miscViews.dangKy, AuthMode.register),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    required this.onSubmitted,
    this.error,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
  });

  final TextEditingController controller;
  final VnlfLucide icon;
  final String hint;
  final String? error;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final invalid = error != null;
    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 5,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              border: Border.all(
                color: invalid
                    ? Color.alphaBlend(
                        colors.red.withValues(alpha: .65),
                        colors.line,
                      )
                    : colors.line,
              ),
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              boxShadow: invalid
                  ? [
                      BoxShadow(
                        color: colors.red.withValues(alpha: .09),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              spacing: 8,
              children: [
                VnlfIcon(icon, size: 16, color: colors.muted),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    autocorrect: false,
                    enableSuggestions: !obscure,
                    onSubmitted: (_) => onSubmitted(),
                    style: VnlfTypography.body(colors.ink),
                    // The box above draws the border; the theme's outline
                    // would draw a second one inside it.
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: hint,
                      hintStyle: VnlfTypography.body(colors.muted),
                    ),
                  ),
                ),
                if (onToggleObscure != null)
                  IconButton(
                    tooltip: obscure
                        ? vi.miscViews.hienMatKhau
                        : vi.miscViews.anMatKhau,
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggleObscure,
                    icon: VnlfIcon(
                      VnlfLucide.eye,
                      size: 16,
                      color: colors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (invalid)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                error!,
                style: VnlfTypography.body(colors.red).copyWith(height: 1.45),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthSubmit extends StatelessWidget {
  const _AuthSubmit({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final background = colors.isDark
        ? const Color(0xFF7FCF9A)
        : const Color(0xFF1D6B43);
    final foreground = colors.isDark ? const Color(0xFF0C1F14) : Colors.white;
    return Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 7,
              children: [
                Text(
                  label,
                  style: VnlfTypography.body(foreground)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                VnlfIcon(
                  busy ? VnlfLucide.loaderCircle : VnlfLucide.arrowUpRight,
                  size: 16,
                  color: foreground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLink extends StatelessWidget {
  const _AuthLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    // The website's link has no hover background.
    return InkWell(
      onTap: onPressed,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: VnlfTypography.body(colors.muted),
        ),
      ),
    );
  }
}

class _AuthAlert extends StatelessWidget {
  const _AuthAlert({required this.notice});
  final _Notice notice;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final tint = notice.error ? colors.red : colors.brand;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: notice.error ? .08 : .09),
          border: Border.all(
            color: tint.withValues(alpha: notice.error ? .28 : .26),
          ),
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: VnlfIcon(
                notice.error ? VnlfLucide.circleAlert : VnlfLucide.circleCheck,
                size: 16,
                color: tint,
              ),
            ),
            Expanded(
              child: Text(
                notice.text,
                style: VnlfTypography.body(tint).copyWith(height: 1.5),
              ),
            ),
          ],
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

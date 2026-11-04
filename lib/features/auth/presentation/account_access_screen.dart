import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_auth_layout.dart';
import '../data/account_auth_api.dart';

enum AccountAuthStep { login, register, forgot, verifyRegistration, reset }

class AccountAccessScreen extends StatefulWidget {
  const AccountAccessScreen({
    super.key,
    required this.onAuthenticated,
    this.api,
    this.googleSignIn,
    this.googleError,
    this.initialStep = AccountAuthStep.login,
  });

  final ValueChanged<AccountSession> onAuthenticated;
  final AccountAuthApi? api;
  final Widget? googleSignIn;
  final String? googleError;
  final AccountAuthStep initialStep;

  @override
  State<AccountAccessScreen> createState() => _AccountAccessScreenState();
}

class _AccountAccessScreenState extends State<AccountAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _code = TextEditingController();
  late final AccountAuthApi _api;
  late AccountAuthStep _step;
  String? _challengeId;
  String? _error;
  String? _notice;
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AccountAuthApi();
    _step = widget.initialStep;
  }

  @override
  void dispose() {
    for (final field in [
      _username,
      _name,
      _email,
      _password,
      _confirmation,
      _code,
    ]) {
      field.dispose();
    }
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _change(AccountAuthStep step) {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();
    setState(() {
      _step = step;
      _error = null;
      _notice = null;
      _password.clear();
      _confirmation.clear();
      _code.clear();
    });
  }

  String? _passwordError(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (_step != AccountAuthStep.login && value.length < 8) {
      return 'Mật khẩu cần ít nhất 8 ký tự';
    }
    if (utf8.encode(value).length > 72) {
      return 'Mật khẩu quá dài (tối đa 72 byte UTF-8)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      switch (_step) {
        case AccountAuthStep.login:
          final session = await _api.login(_username.text, _password.text);
          if (mounted) widget.onAuthenticated(session);
        case AccountAuthStep.register:
          final id = await _api.register(
            _name.text,
            _email.text,
            _password.text,
          );
          if (mounted) {
            setState(() {
              _challengeId = id;
              _step = AccountAuthStep.verifyRegistration;
              _code.clear();
            });
          }
        case AccountAuthStep.forgot:
          final id = await _api.forgotPassword(_email.text);
          if (mounted) {
            setState(() {
              _challengeId = id;
              _step = AccountAuthStep.reset;
              _code.clear();
              _password.clear();
              _confirmation.clear();
            });
          }
        case AccountAuthStep.verifyRegistration:
          final session = await _api.verifyRegistration(
            _challengeId!,
            _code.text,
          );
          if (mounted) widget.onAuthenticated(session);
        case AccountAuthStep.reset:
          await _api.resetPassword(_challengeId!, _code.text, _password.text);
          if (mounted) {
            _username.text = _email.text;
            setState(() {
              _step = AccountAuthStep.login;
              _password.clear();
              _confirmation.clear();
              _code.clear();
              _notice =
                  'Đã đổi mật khẩu. Đăng nhập bằng mật khẩu mới để tiếp tục.';
            });
          }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AccountApiException
              ? error.message
              : 'Chưa hoàn tất yêu cầu. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final id = _step == AccountAuthStep.verifyRegistration
          ? await _api.register(_name.text, _email.text, _password.text)
          : await _api.forgotPassword(_email.text);
      if (mounted) {
        setState(() {
          _challengeId = id;
          _code.clear();
          _notice = 'Đã gửi lại yêu cầu. Kiểm tra hộp thư và thư rác.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AccountApiException
              ? error.message
              : 'Chưa gửi lại được mã xác nhận.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _step == AccountAuthStep.login;
    final isRegister = _step == AccountAuthStep.register;
    final isForgot = _step == AccountAuthStep.forgot;
    final isVerify = _step == AccountAuthStep.verifyRegistration;
    final isReset = _step == AccountAuthStep.reset;

    final title = switch (_step) {
      AccountAuthStep.login => 'Đăng nhập hệ thống',
      AccountAuthStep.register => 'Tạo tài khoản nhân viên',
      AccountAuthStep.forgot => 'Quên mật khẩu',
      AccountAuthStep.verifyRegistration => 'Xác nhận email',
      AccountAuthStep.reset => 'Đặt lại mật khẩu',
    };

    final subtitle = switch (_step) {
      AccountAuthStep.login =>
        'Đăng nhập bằng email hoặc mã nhân viên để bắt đầu ca làm việc.',
      AccountAuthStep.register =>
        'Đăng ký tài khoản để xem lịch làm việc và chấm công tại siêu thị.',
      AccountAuthStep.forgot =>
        'Nhập email tài khoản để nhận mã đặt lại mật khẩu an toàn.',
      AccountAuthStep.verifyRegistration =>
        'Nhập mã 6 số gửi đến ${_email.text.trim()}. Mã có hiệu lực 10 phút.',
      AccountAuthStep.reset =>
        'Nếu email hợp lệ, mã 6 số sẽ được gửi đến ${_email.text.trim()}. Kiểm tra cả thư rác.',
    };

    final action = switch (_step) {
      AccountAuthStep.login => 'Đăng nhập',
      AccountAuthStep.register => 'Đăng ký',
      AccountAuthStep.forgot => 'Gửi mã xác nhận',
      AccountAuthStep.verifyRegistration => 'Xác nhận & đăng nhập',
      AccountAuthStep.reset => 'Lưu mật khẩu mới',
    };

    return AppAuthLayout(
      title: title,
      subtitle: subtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isRegister) ...[
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Ví dụ: Nguyễn Văn An',
                    counterText: '',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              if (isLogin) ...[
                TextFormField(
                  controller: _username,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Email / Mã nhân viên',
                    hintText: 'admin@smartmarket.local hoặc EMP001',
                    counterText: '',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tài khoản'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              if (isRegister || isForgot) ...[
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ Email',
                    hintText: 'name@example.com',
                    counterText: '',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) =>
                      value != null &&
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value.trim())
                      ? null
                      : 'Vui lòng nhập email hợp lệ',
                ),
                const SizedBox(height: 16),
              ],
              if (isVerify || isReset) ...[
                TextFormField(
                  controller: _code,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mã xác nhận 6 số',
                    hintText: '000000',
                    prefixIcon: Icon(Icons.mark_email_read_outlined),
                  ),
                  validator: (value) =>
                      value != null && RegExp(r'^\d{6}$').hasMatch(value)
                      ? null
                      : 'Nhập đủ 6 chữ số',
                ),
                const SizedBox(height: 16),
              ],
              if (isLogin || isRegister || isReset) ...[
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hidePassword,
                  autofillHints: [
                    isLogin
                        ? AutofillHints.password
                        : AutofillHints.newPassword,
                  ],
                  onFieldSubmitted: (_) {
                    if (isLogin) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: isReset ? 'Mật khẩu mới' : 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: _passwordError,
                ),
                const SizedBox(height: 16),
              ],
              if (isRegister || isReset) ...[
                TextFormField(
                  controller: _confirmation,
                  enabled: !_busy,
                  obscureText: _hideConfirmation,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      tooltip: _hideConfirmation
                          ? 'Hiện xác nhận mật khẩu'
                          : 'Ẩn xác nhận mật khẩu',
                      onPressed: () => setState(
                        () => _hideConfirmation = !_hideConfirmation,
                      ),
                      icon: Icon(
                        _hideConfirmation
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Vui lòng xác nhận mật khẩu'
                      : value != _password.text
                      ? 'Mật khẩu xác nhận chưa khớp'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _change(AccountAuthStep.forgot),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),

              // THÔNG BÁO LỖI HOẶC THÀNH CÔNG RÕ RÀNG
              if (_error != null || _notice != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _error != null
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _error != null
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _error != null
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                        color: _error != null
                            ? AppColors.statusAbsent
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error ?? _notice!,
                            style: TextStyle(
                              color: _error != null
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF166534),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // NÚT HÀNH ĐỘNG CHÍNH CÓ TRẠNG THÁI LOADING RÕ RÀNG
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Đang xử lý...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        action,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              if (isLogin) ...[
                if (widget.googleSignIn != null) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'hoặc đăng nhập nhanh',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  IgnorePointer(ignoring: _busy, child: widget.googleSignIn!),
                  if (widget.googleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Google: ${widget.googleError}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản nhân viên?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _change(AccountAuthStep.register),
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                if (isVerify || isReset)
                  TextButton(
                    onPressed: _busy ? null : _resend,
                    child: const Text('Gửi lại mã xác nhận qua email'),
                  ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _change(AccountAuthStep.login),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Quay lại đăng nhập'),
                ),
              ],
              if (isRegister)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tài khoản mới đăng ký sẽ thuộc vai trò Nhân viên. Quản lý siêu thị sẽ xếp ca và gán khu vực làm việc cho bạn.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

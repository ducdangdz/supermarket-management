import 'package:flutter_localizations/flutter_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../auth/data/account_auth_api.dart';
import '../auth/presentation/account_access_screen.dart';
import 'dart:async';
import 'dart:convert';

import 'auth/web_google_button.dart';
import '../launcher/authenticated_team_home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const _googleWebClientId =
    '1066032644057-3d0l0gkbpj6h8b9ffm2gaf04h5n21816.apps.googleusercontent.com';

String get _apiBaseUrl => accountApiBaseUrl;

class SmartMarketApp extends StatefulWidget {
  const SmartMarketApp({super.key, this.initialSession});
  final Session? initialSession;

  @override
  State<SmartMarketApp> createState() => _SmartMarketAppState();
}

class _SmartMarketAppState extends State<SmartMarketApp> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEvents;
  Session? _session;
  bool _initializing = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    if (_session == null) {
      _initializeGoogle();
    } else {
      _initializing = false;
    }
  }

  Future<void> _initializeGoogle() async {
    try {
      final signIn = GoogleSignIn.instance;
      await signIn.initialize(
        clientId: kIsWeb ? _googleWebClientId : null,
        serverClientId: kIsWeb ? null : _googleWebClientId,
      );
      _authEvents = signIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: (Object error) => _showError(_messageFor(error)),
      );
    } on Object catch (error) {
      _error = _messageFor(error);
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        if (!(_session?.idToken.startsWith('smh_') ?? false))
          _loginBackend(user);
      case GoogleSignInAuthenticationEventSignOut():
        if (mounted && !(_session?.idToken.startsWith('smh_') ?? false))
          setState(() => _session = null);
    }
  }

  Future<void> _startNativeSignIn() async {
    try {
      _showError(null);
      if (!GoogleSignIn.instance.supportsAuthenticate()) return;
      await GoogleSignIn.instance.authenticate();
    } on Object catch (error) {
      _showError(_messageFor(error));
    }
  }

  Future<void> _loginBackend(GoogleSignInAccount account) async {
    if (_loading || _session != null) return;
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _showError('Không nhận được Google ID token.');
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/google'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      final payload = _decode(response.body);
      if (response.statusCode != 200) {
        throw StateError(
          payload['message']?.toString() ?? 'Đăng nhập thất bại.',
        );
      }
      if (mounted)
        setState(() => _session = Session.fromJson(payload, idToken));
    } on Object catch (error) {
      _showError(_messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String? message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _signOut() async {
    final api = AccountAuthApi();
    try {
      if (_session?.idToken.startsWith('smh_') ?? false) {
        await api.logout(_session!.idToken);
      } else {
        await GoogleSignIn.instance.signOut();
      }
      if (mounted)
        setState(() {
          _session = null;
          _error = null;
        });
    } catch (_) {
      // Always finish the local logout, even if the server is unreachable.
    } finally {
      api.close();
      if (mounted)
        setState(() {
          _session = null;
          _error = null;
        });
    }
  }

  @override
  void dispose() {
    _authEvents?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartMarket HRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      home: _session == null
          ? LoginPage(
              initializing: _initializing,
              loading: _loading,
              error: _error,
              onNativeLogin: _startNativeSignIn,
              onAuthenticated: (account) {
                setState(() {
                  _session = Session.fromJson(account.user, account.token);
                  _error = null;
                });
              },
            )
          : AuthenticatedTeamHome(
              key: ValueKey(_session!.idToken),
              session: _session!,
              onLogout: _signOut,
            ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    required this.initializing,
    required this.loading,
    required this.error,
    required this.onNativeLogin,
    required this.onAuthenticated,
  });
  final bool initializing;
  final bool loading;
  final String? error;
  final Future<void> Function() onNativeLogin;
  final ValueChanged<AccountSession> onAuthenticated;

  @override
  Widget build(BuildContext context) => AccountAccessScreen(
    onAuthenticated: onAuthenticated,
    googleError: error,
    googleSignIn: initializing
        ? const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : kIsWeb
        ? Align(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: webGoogleSignInButton(),
            ),
          )
        : OutlinedButton.icon(
            onPressed: loading ? null : onNativeLogin,
            icon: const Icon(Icons.g_mobiledata_rounded),
            label: Text(loading ? 'Đang đăng nhập...' : 'Đăng nhập với Google'),
          ),
  );
}

class Session {
  const Session({
    required this.employeeId,
    required this.idToken,
    required this.fullName,
    required this.email,
    required this.roleCode,
    required this.roleName,
    this.branchId,
  });
  factory Session.fromJson(Map<String, dynamic> json, String idToken) =>
      Session(
        employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
        idToken: idToken,
        fullName: json['fullName']?.toString() ?? 'Người dùng',
        email: json['email']?.toString() ?? '',
        roleCode: json['roleCode']?.toString() ?? '',
        roleName: json['roleName']?.toString() ?? '',
        branchId: (json['branchId'] as num?)?.toInt(),
      );
  final int employeeId;
  final int? branchId;
  final String idToken;
  final String fullName;
  final String email;
  final String roleCode;
  final String roleName;
}

Map<String, dynamic> _decode(String body) {
  final value = jsonDecode(body);
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

String _messageFor(Object error) {
  final message = error.toString().replaceFirst('Bad state: ', '');
  if (error is TimeoutException)
    return 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
  if (error is http.ClientException || message.contains('SocketException'))
    return 'Không kết nối được backend tại $_apiBaseUrl.';
  return message;
}

import 'dart:async';
import 'dart:convert';

import 'auth/web_google_button.dart';
import 'employee_workspace.dart';
import 'management_workspace.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const _googleWebClientId =
    '1066032644057-3d0l0gkbpj6h8b9ffm2gaf04h5n21816.apps.googleusercontent.com';

String get _apiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  return kIsWeb
      ? 'http://localhost:8081/api'
      : 'http://10.0.2.2:8081/api';
}

void main() => runApp(const SmartMarketApp());

class SmartMarketApp extends StatefulWidget {
  const SmartMarketApp({super.key});

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
    _initializeGoogle();
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
      signIn.attemptLightweightAuthentication();
    } on Object catch (error) {
      _error = _messageFor(error);
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        _loginBackend(user);
      case GoogleSignInAuthenticationEventSignOut():
        if (mounted) setState(() => _session = null);
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
        throw StateError(payload['message']?.toString() ?? 'Đăng nhập thất bại.');
      }
      if (mounted) setState(() => _session = Session.fromJson(payload, idToken));
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
    await GoogleSignIn.instance.signOut();
    if (mounted) setState(() => _session = null);
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C66)),
        useMaterial3: true,
      ),
      home: _session == null
          ? LoginPage(
              initializing: _initializing,
              loading: _loading,
              error: _error,
              onNativeLogin: _startNativeSignIn,
            )
          : _session!.roleCode == 'EMPLOYEE'
              ? EmployeeWorkspace(
              employeeId: _session!.employeeId,
              idToken: _session!.idToken,
              fullName: _session!.fullName,
              email: _session!.email,
              roleCode: _session!.roleCode,
              roleName: _session!.roleName,
              onLogout: _signOut,
            )
              : ManagementWorkspace(
                  idToken: _session!.idToken,
                  fullName: _session!.fullName,
                  roleCode: _session!.roleCode,
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
  });

  final bool initializing;
  final bool loading;
  final String? error;
  final Future<void> Function() onNativeLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront_rounded,
                    size: 74, color: Color(0xFF0E7C66)),
                const SizedBox(height: 20),
                Text('SmartMarket HRM',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Quản lý nhân sự và chấm công',
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 36),
                if (initializing)
                  const Center(child: CircularProgressIndicator())
                else if (kIsWeb)
                  Center(child: webGoogleSignInButton())
                else
                  FilledButton.icon(
                    onPressed: loading ? null : onNativeLogin,
                    icon: loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: Text(loading ? 'Đang đăng nhập...' : 'Đăng nhập với Google'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                if (loading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Session {
  const Session({required this.employeeId, required this.idToken, required this.fullName, required this.email, required this.roleCode, required this.roleName});
  factory Session.fromJson(Map<String, dynamic> json, String idToken) => Session(
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
      idToken: idToken,
      fullName: json['fullName']?.toString() ?? 'Người dùng',
      email: json['email']?.toString() ?? '',
      roleCode: json['roleCode']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? '');
  final int employeeId;
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
  if (message.contains('SocketException')) return 'Không kết nối được backend tại $_apiBaseUrl.';
  return message;
}

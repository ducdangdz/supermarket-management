import 'package:flutter/material.dart';
import '../../backend/backend_workspace.dart';
import 'account_access_screen.dart';

/// The former employee login now uses the same real account APIs as the online module.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => AccountAccessScreen(
    onAuthenticated: (account) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SmartMarketApp(
            initialSession: Session.fromJson(account.user, account.token),
          ),
        ),
      );
    },
  );
}

import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget webGoogleSignInButton() => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    text: web.GSIButtonText.signinWith,
    theme: web.GSIButtonTheme.outline,
    size: web.GSIButtonSize.large,
    minimumWidth: 320,
    locale: 'vi',
  ),
);

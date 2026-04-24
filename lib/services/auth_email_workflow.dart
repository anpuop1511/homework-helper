import 'package:firebase_auth/firebase_auth.dart';

enum AuthActionType {
  verifyEmail,
  resetPassword,
  recoverEmail,
  unknown,
}

class AuthActionLink {
  AuthActionLink(this.uri);

  final Uri uri;

  String? get oobCode => uri.queryParameters['oobCode'];

  AuthActionType get type {
    switch (uri.queryParameters['mode']) {
      case 'verifyEmail':
        return AuthActionType.verifyEmail;
      case 'resetPassword':
        return AuthActionType.resetPassword;
      case 'recoverEmail':
        return AuthActionType.recoverEmail;
      default:
        return AuthActionType.unknown;
    }
  }

  bool get isSupported =>
      oobCode != null &&
      type != AuthActionType.unknown &&
      _isAuthHandlerUri(uri);

  bool get isVerification => type == AuthActionType.verifyEmail;

  bool get isPasswordReset => type == AuthActionType.resetPassword;
}

class AuthEmailWorkflow {
  static const String authHandlerUrl = 'https://hwhelper.tech/';

  static final Uri authHandlerUri = Uri.parse(authHandlerUrl);

  static final ActionCodeSettings emailVerificationActionCodeSettings =
      ActionCodeSettings(
    url: authHandlerUrl,
    handleCodeInApp: true,
  );

  static final ActionCodeSettings passwordResetActionCodeSettings =
      ActionCodeSettings(
    url: authHandlerUrl,
    handleCodeInApp: true,
  );

  static AuthActionLink? tryParse(Uri uri) {
    final link = AuthActionLink(uri);
    return link.isSupported ? link : null;
  }

  static bool isAuthActionUri(Uri uri) => _isAuthHandlerUri(uri);

  static String describeMode(AuthActionType type) {
    switch (type) {
      case AuthActionType.verifyEmail:
        return 'Verify your email';
      case AuthActionType.resetPassword:
        return 'Reset your password';
      case AuthActionType.recoverEmail:
        return 'Recover email';
      case AuthActionType.unknown:
        return 'Unknown action';
    }
  }
}

bool _isAuthHandlerUri(Uri uri) {
  // Accept both hwhelper.tech and www.hwhelper.tech
  final host = uri.host;
  if (host != 'hwhelper.tech' && host != 'www.hwhelper.tech') return false;

  final hasActionQuery = uri.queryParameters.containsKey('mode') &&
      uri.queryParameters.containsKey('oobCode');

  if (!hasActionQuery) return false;

  // Accept any of these paths:
  // - /auth-handler?...
  // - /auth-handler?...
  // - / or empty path with query params
  // - /index.html with query params
  return uri.path.isEmpty ||
      uri.path == '/' ||
      uri.path == '/index.html' ||
      uri.path == '/auth-handler' ||
      (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'auth-handler');
}

import 'package:firebase_auth/firebase_auth.dart';

enum AuthActionType {
  verifyEmail,
  resetPassword,
  recoverEmail,
  deleteAccount,
  unknown,
}

class AuthActionLink {
  AuthActionLink(this.uri);

  final Uri uri;

  String? get oobCode => uri.queryParameters['oobCode'];
  String? get confirmationCode => uri.queryParameters['confirmationCode'];
  String? get targetEmail => uri.queryParameters['email'];

  AuthActionType get type {
    switch (uri.queryParameters['mode']) {
      case 'verifyEmail':
        return AuthActionType.verifyEmail;
      case 'resetPassword':
        return AuthActionType.resetPassword;
      case 'recoverEmail':
        return AuthActionType.recoverEmail;
      case 'deleteAccount':
        return AuthActionType.deleteAccount;
      default:
        return AuthActionType.unknown;
    }
  }

  bool get isSupported {
    if (type == AuthActionType.unknown || !_isAuthHandlerUri(uri)) {
      return false;
    }

    if (type == AuthActionType.deleteAccount) {
      return confirmationCode != null && confirmationCode!.isNotEmpty;
    }

    return oobCode != null && oobCode!.isNotEmpty;
  }

  bool get isVerification => type == AuthActionType.verifyEmail;

  bool get isPasswordReset => type == AuthActionType.resetPassword;

  bool get isDeleteAccount => type == AuthActionType.deleteAccount;
}

class AuthEmailWorkflow {
  static const String authHandlerUrl =
      'https://homework-helper-web-dun.vercel.app/app';

  static final Uri authHandlerUri = Uri.parse(authHandlerUrl);

  static final ActionCodeSettings emailVerificationActionCodeSettings =
      ActionCodeSettings(url: authHandlerUrl, handleCodeInApp: true);

  static final ActionCodeSettings passwordResetActionCodeSettings =
      ActionCodeSettings(url: authHandlerUrl, handleCodeInApp: true);

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
      case AuthActionType.deleteAccount:
        return 'Confirm account deletion';
      case AuthActionType.unknown:
        return 'Unknown action';
    }
  }
}

bool _isAuthHandlerUri(Uri uri) {
  // Accept both the Vercel app host and the legacy hwhelper.tech domains.
  final host = uri.host;
  if (host != 'homework-helper-web-dun.vercel.app' &&
      host != 'hwhelper.tech' &&
      host != 'www.hwhelper.tech') {
    return false;
  }

  final mode = uri.queryParameters['mode'];
  if (mode == null || mode.isEmpty) return false;

  final hasActionQuery = mode == 'deleteAccount'
      ? uri.queryParameters.containsKey('confirmationCode')
      : uri.queryParameters.containsKey('oobCode');

  if (!hasActionQuery) return false;

  // Accept any of these paths:
  // - /app?...
  // - /auth-handler?...
  // - / or empty path with query params
  // - /index.html with query params
  return uri.path.isEmpty ||
      uri.path == '/' ||
      uri.path == '/app' ||
      uri.path == '/index.html' ||
      uri.path == '/auth-handler' ||
      (uri.pathSegments.isNotEmpty &&
          (uri.pathSegments.first == 'auth-handler' ||
              uri.pathSegments.first == 'app'));
}

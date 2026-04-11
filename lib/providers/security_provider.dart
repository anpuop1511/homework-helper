import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app security settings: App Lock, Biometric-for-NFC, and Passkey.
///
/// State is persisted to [SharedPreferences] so it survives app restarts.
class SecurityProvider extends ChangeNotifier {
  static const _kAppLock = 'security_app_lock';
  static const _kBioNfc = 'security_bio_nfc';
  static const _kPasskeySet = 'security_passkey_set';

  final LocalAuthentication _auth = LocalAuthentication();

  bool _isAppLockEnabled = false;
  bool _isBioNfcEnabled = false;
  bool _isPasskeySet = false;

  /// Timestamp of the last time the app was in the foreground.
  DateTime _lastActive = DateTime.now();

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isBioNfcEnabled => _isBioNfcEnabled;
  bool get isPasskeySet => _isPasskeySet;
  DateTime get lastActive => _lastActive;

  SecurityProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLockEnabled = prefs.getBool(_kAppLock) ?? false;
    _isBioNfcEnabled = prefs.getBool(_kBioNfc) ?? false;
    _isPasskeySet = prefs.getBool(_kPasskeySet) ?? false;
    notifyListeners();
  }

  Future<void> setAppLock(bool value) async {
    _isAppLockEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLock, value);
  }

  Future<void> setBioNfc(bool value) async {
    _isBioNfcEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBioNfc, value);
  }

  Future<void> setPasskeySet(bool value) async {
    _isPasskeySet = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPasskeySet, value);
  }

  /// Records the current time as the last active timestamp (call on resume).
  void recordActive() {
    _lastActive = DateTime.now();
  }

  /// Returns true when biometrics are available on this device.
  /// Always returns false on Web where local_auth is not supported.
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Triggers the native biometric / device-credential prompt.
  ///
  /// Returns `true` on success, `false` on failure, cancellation, or when
  /// running on the Web platform where local_auth is not supported.
  Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

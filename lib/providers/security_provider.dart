import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app security settings: App Lock, Biometric-for-NFC, Passkey,
/// and AI permissions.
///
/// State is persisted to [SharedPreferences] so it survives app restarts.
class SecurityProvider extends ChangeNotifier {
  static const _kAppLock = 'security_app_lock';
  static const _kBioNfc = 'security_bio_nfc';
  static const _kPasskeySet = 'security_passkey_set';
  static const _kAiEnabled = 'security_ai_enabled';
  static const _kPasskeyEmail = 'passkey_email';
  static const _kPasskeyPassword = 'passkey_password';

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAppLockEnabled = false;
  bool _isBioNfcEnabled = false;
  bool _isPasskeySet = false;
  bool _isAiEnabled = true;

  /// Timestamp of the last time the app was in the foreground.
  DateTime _lastActive = DateTime.now();

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isBioNfcEnabled => _isBioNfcEnabled;
  bool get isPasskeySet => _isPasskeySet;

  /// When `false` the user has revoked AI permissions and AI features are
  /// disabled.
  bool get isAiEnabled => _isAiEnabled;

  DateTime get lastActive => _lastActive;

  SecurityProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLockEnabled = prefs.getBool(_kAppLock) ?? false;
    _isBioNfcEnabled = prefs.getBool(_kBioNfc) ?? false;
    _isPasskeySet = prefs.getBool(_kPasskeySet) ?? false;
    _isAiEnabled = prefs.getBool(_kAiEnabled) ?? true;
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
    if (!value) {
      // Clear stored credentials when passkey is removed.
      await _secureStorage.delete(key: _kPasskeyEmail);
      await _secureStorage.delete(key: _kPasskeyPassword);
    }
  }

  /// Stores the user's email and password securely so the Passkey sign-in
  /// can re-authenticate with Firebase after biometric verification succeeds.
  Future<void> storePasskeyCredentials(String email, String password) async {
    await _secureStorage.write(key: _kPasskeyEmail, value: email);
    await _secureStorage.write(key: _kPasskeyPassword, value: password);
  }

  /// Returns the stored passkey credentials, or `null` if none are saved.
  Future<({String email, String password})?> getPasskeyCredentials() async {
    final email = await _secureStorage.read(key: _kPasskeyEmail);
    final password = await _secureStorage.read(key: _kPasskeyPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  /// Enables or disables AI features app-wide.
  Future<void> setAiEnabled(bool value) async {
    _isAiEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAiEnabled, value);
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
      final available = await _auth.getAvailableBiometrics();
      final isDeviceSupported = await _auth.isDeviceSupported();
      return available.isNotEmpty || isDeviceSupported;
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
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

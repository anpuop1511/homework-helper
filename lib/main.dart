import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/assignments_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/social_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/username_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables. Supports two mechanisms:
  //   1. A .env file bundled as a Flutter asset (add to pubspec.yaml assets locally).
  //   2. --dart-define=GEMINI_API_KEY=xxx at build/run/test time (CI-friendly).
  const geminiApiKeyFromDefine =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  try {
    await dotenv.load(
      fileName: '.env',
      mergeWith: {'GEMINI_API_KEY': geminiApiKeyFromDefine},
    );
  } catch (e) {
    // .env not available as a bundled asset — populate from dart-define only.
    debugPrint('[dotenv] .env not bundled; falling back to --dart-define: $e');
    dotenv.loadFromString(
      fileInput: 'GEMINI_API_KEY=$geminiApiKeyFromDefine',
    );
  }

  await NotificationService.instance.init();

  // Initialise Firebase.  If the placeholder firebase_options.dart has not
  // been replaced yet, Firebase.initializeApp() will throw; the app will then
  // run in offline / guest-only mode.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    // Firebase not yet configured — offline mode only.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(firebaseReady: firebaseReady),
        ),
        // SocialProvider is wired to AuthProvider so it receives the UID
        // whenever the user signs in or out.
        ChangeNotifierProxyProvider<AuthProvider, SocialProvider>(
          create: (_) => SocialProvider(),
          update: (_, auth, prev) {
            final provider = prev ?? SocialProvider();
            provider.setUid(
              auth.uid,
              email: auth.email,
              name: auth.currentUser?.displayName,
              username: auth.username,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, AssignmentsProvider>(
          create: (_) => AssignmentsProvider(),
          update: (_, userProvider, prev) =>
              (prev ?? AssignmentsProvider())..updateUserProvider(userProvider),
        ),
      ],
      child: const HomeworkHelperApp(),
    ),
  );
}

/// Routes to [LoginScreen] or [MainScaffold] based on [AuthProvider] state.
/// Also saves the user's email to Firestore so friends can search by email.
class _AuthGate extends StatefulWidget {
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _prevUid;
  Timer? _loadTimer;
  bool _showRetry = false;

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  /// Starts a one-shot timer that surfaces a Retry button if Firestore
  /// hasn't finished loading the username within 8 seconds.
  void _scheduleRetryIfNeeded() {
    if (_loadTimer != null) return; // already running
    _loadTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showRetry = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.uid;

    // Whenever the UID changes (sign-in / sign-out), sync the email to
    // Firestore so friends can look the user up by email.
    if (uid != _prevUid) {
      _prevUid = uid;
      // Reset retry state whenever the account changes.
      _loadTimer?.cancel();
      _loadTimer = null;
      _showRetry = false;
      if (uid != null && auth.email != null) {
        DatabaseService.instance
            .saveUserEmail(uid, auth.email!)
            .ignore();
      }
    }

    if (!auth.isSignedIn) {
      return const LoginScreen();
    }

    // Show a minimal splash while the username is still being fetched from
    // Firestore so we don't flash the wrong screen.
    if (!auth.usernameLoaded) {
      _scheduleRetryIfNeeded();
      if (_showRetry) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Taking a while to connect…'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showRetry = false;
                      _loadTimer?.cancel();
                      _loadTimer = null;
                    });
                    auth.refreshUsername();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Loading finished – cancel any pending retry timer.
    _loadTimer?.cancel();
    _loadTimer = null;

    // Force existing (and new) users to pick a handle if they don't have one.
    if (auth.username == null || auth.username!.isEmpty) {
      return const UsernameScreen();
    }

    return const MainScaffold();
  }
}

/// Root widget for the Homework Helper application.
/// Configures Material 3 theming with light and dark mode support.
/// Uses [DynamicColorBuilder] to adopt the device's system accent color
/// when available (Android 12+ / Material You).
class HomeworkHelperApp extends StatelessWidget {
  const HomeworkHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vibe = context.watch<ThemeProvider>().vibe;
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Homework Helper',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(vibe, lightDynamic),
          darkTheme: AppTheme.darkTheme(vibe, darkDynamic),
          themeMode: ThemeMode.system,
          home: _AuthGate(),
        );
      },
    );
  }
}

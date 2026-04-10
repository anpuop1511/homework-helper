import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/assignments_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          home: const _AuthGate(),
        );
      },
    );
  }
}

/// Decides whether to show [LoginScreen] or [MainScaffold] based on the
/// Firebase auth state.  Also wires the UID into [UserProvider],
/// [AssignmentsProvider], and [ThemeProvider] whenever it changes.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Trigger an initial sync on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncUid());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncUid();
  }

  void _syncUid() {
    final auth = context.read<AuthProvider>();
    final uid = auth.uid;
    context.read<UserProvider>().setUid(uid);
    context.read<AssignmentsProvider>().setUid(uid);
    context.read<ThemeProvider>().setUid(uid);
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthProvider>().isSignedIn;
    return isSignedIn ? const MainScaffold() : const LoginScreen();
  }
}

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.uid;

    // Whenever the UID changes (sign-in / sign-out), sync the email to
    // Firestore so friends can look the user up by email.
    if (uid != _prevUid) {
      _prevUid = uid;
      if (uid != null && auth.email != null) {
        DatabaseService.instance
            .saveUserEmail(uid, auth.email!)
            .ignore();
      }
    }

    if (auth.isSignedIn) {
      return const MainScaffold();
    }
    return const LoginScreen();
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

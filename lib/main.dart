import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/assignments_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/social_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
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
          home: const LoginScreen(),
        );
      },
    );
  }
}

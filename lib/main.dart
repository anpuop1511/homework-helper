import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/assignments_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
class HomeworkHelperApp extends StatelessWidget {
  const HomeworkHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vibe = context.watch<ThemeProvider>().vibe;
    return MaterialApp(
      title: 'Homework Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(vibe),
      darkTheme: AppTheme.darkTheme(vibe),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}

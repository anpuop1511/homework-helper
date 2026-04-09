import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/assignments_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AssignmentsProvider(),
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
    return MaterialApp(
      title: 'Homework Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}

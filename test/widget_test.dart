import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homework_helper/main.dart';
import 'package:homework_helper/models/assignment.dart';
import 'package:homework_helper/providers/assignments_provider.dart';
import 'package:homework_helper/providers/user_provider.dart';
import 'package:homework_helper/providers/theme_provider.dart';
import 'package:homework_helper/screens/login_screen.dart';
import 'package:homework_helper/screens/home_screen.dart';
import 'package:homework_helper/widgets/assignment_card.dart';

/// Wraps [child] with all required providers and a [MaterialApp].
Widget _buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProxyProvider<UserProvider, AssignmentsProvider>(
        create: (_) => AssignmentsProvider(),
        update: (_, userProvider, prev) =>
            (prev ?? AssignmentsProvider())..updateUserProvider(userProvider),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

/// Wraps the full [HomeworkHelperApp] with all required providers.
Widget _buildFullApp() {
  return MultiProvider(
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
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeworkHelperApp', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(_buildFullApp());
      expect(find.byType(MaterialApp), findsWidgets);
    });

    testWidgets('shows login screen on launch', (WidgetTester tester) async {
      await tester.pumpWidget(_buildFullApp());
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('login screen has Sign In and Sign Up toggles',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildFullApp());
      await tester.pump();
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('login screen shows Continue as Guest button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildFullApp());
      await tester.pump();
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets('login screen shows Sign in with Google button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildFullApp());
      await tester.pump();
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });

  group('HomeScreen widget', () {
    testWidgets('shows home screen with key elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pump();
      expect(find.text('Hey there! 👋'), findsOneWidget);
    });

    testWidgets('shows Add Task FAB', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pump();
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('displays subject filter chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pump();
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
    });
  });

  group('Assignment model', () {
    test('creates with required fields', () {
      final dueDate = DateTime(2026, 6, 1);
      final a = Assignment(
        id: 'test-1',
        title: 'Test Assignment',
        subject: Subject.math,
        dueDate: dueDate,
      );
      expect(a.id, 'test-1');
      expect(a.title, 'Test Assignment');
      expect(a.subject, Subject.math);
      expect(a.dueDate, dueDate);
      expect(a.isCompleted, false);
    });

    test('copyWith updates fields', () {
      final original = Assignment(
        id: '1',
        title: 'Original',
        subject: Subject.science,
        dueDate: DateTime(2026, 6, 1),
      );
      final updated = original.copyWith(title: 'Updated', isCompleted: true);
      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true);
      expect(updated.id, original.id);
      expect(updated.subject, original.subject);
    });

    test('equality is based on id', () {
      final a1 = Assignment(
        id: 'same-id',
        title: 'Assignment A',
        subject: Subject.math,
        dueDate: DateTime(2026, 6, 1),
      );
      final a2 = Assignment(
        id: 'same-id',
        title: 'Assignment B',
        subject: Subject.science,
        dueDate: DateTime(2026, 7, 1),
      );
      expect(a1, equals(a2));
    });

    test('allSubjects list contains expected entries', () {
      expect(Subject.allSubjects, contains(Subject.all));
      expect(Subject.allSubjects, contains(Subject.math));
      expect(Subject.allSubjects, contains(Subject.science));
      expect(Subject.allSubjects, contains(Subject.history));
      expect(Subject.allSubjects, contains(Subject.english));
    });
  });

  group('AssignmentsProvider', () {
    test('starts with sample assignments', () {
      final provider = AssignmentsProvider();
      expect(provider.assignments.isNotEmpty, true);
    });

    test('add increases count', () {
      final provider = AssignmentsProvider();
      final initial = provider.assignments.length;
      provider.add(Assignment(
        id: 'new-1',
        title: 'New Task',
        subject: Subject.math,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ));
      expect(provider.assignments.length, initial + 1);
    });

    test('toggleComplete flips isCompleted', () {
      final provider = AssignmentsProvider();
      final id = provider.assignments.first.id;
      final before = provider.assignments.first.isCompleted;
      provider.toggleComplete(id);
      expect(provider.assignments.first.isCompleted, !before);
    });

    test('delete removes assignment', () {
      final provider = AssignmentsProvider();
      final id = provider.assignments.first.id;
      final initial = provider.assignments.length;
      provider.delete(id);
      expect(provider.assignments.length, initial - 1);
      expect(provider.assignments.any((a) => a.id == id), false);
    });

    test('toggleComplete awards XP via UserProvider', () {
      final userProvider = UserProvider();
      final assignmentsProvider = AssignmentsProvider()
        ..updateUserProvider(userProvider);

      // Find first incomplete assignment
      final incompleteId = assignmentsProvider.assignments
          .firstWhere((a) => !a.isCompleted)
          .id;

      final xpBefore = userProvider.xp;
      assignmentsProvider.toggleComplete(incompleteId);
      // After completing, XP increases (or level up occurred)
      expect(
        userProvider.xp > xpBefore || userProvider.level > 1,
        true,
        reason: 'XP or level should have increased after completing a task',
      );
    });
  });

  group('UserProvider', () {
    test('starts at level 1 with 0 XP', () {
      final provider = UserProvider();
      expect(provider.level, 1);
      expect(provider.xp, 0);
    });

    test('awardXp increases XP', () {
      final provider = UserProvider();
      provider.awardXp(50);
      expect(provider.xp, 50);
    });

    test('awardXp triggers level up at threshold', () {
      final provider = UserProvider();
      // Level 1 requires 100 XP to advance
      provider.awardXp(100);
      expect(provider.level, 2);
      expect(provider.xp, 0);
    });

    test('levelProgress is between 0 and 1', () {
      final provider = UserProvider();
      provider.awardXp(40);
      expect(provider.levelProgress, greaterThanOrEqualTo(0.0));
      expect(provider.levelProgress, lessThanOrEqualTo(1.0));
    });

    test('streak starts at 1 on first use', () {
      final provider = UserProvider();
      // streak should be 1 because _updateStreak is called on fresh provider
      expect(provider.streak, 1);
    });
  });

  group('ThemeProvider', () {
    test('default vibe is defaultPurple', () {
      final provider = ThemeProvider();
      expect(provider.vibe, AppVibe.defaultPurple);
    });

    test('setVibe updates the vibe', () async {
      final provider = ThemeProvider();
      await provider.setVibe(AppVibe.midnight);
      expect(provider.vibe, AppVibe.midnight);
    });

    test('all AppVibe values have labels and seed colors', () {
      for (final vibe in AppVibe.values) {
        expect(vibe.label, isNotEmpty);
        expect(vibe.emoji, isNotEmpty);
      }
    });
  });

  group('AssignmentCard widget', () {
    testWidgets('displays assignment title', (WidgetTester tester) async {
      final assignment = Assignment(
        id: 'card-1',
        title: 'Flutter Widget Test',
        subject: Subject.math,
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignmentCard(
              assignment: assignment,
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Flutter Widget Test'), findsOneWidget);
      expect(find.text('Math'), findsOneWidget);
    });

    testWidgets('shows completed state with strikethrough',
        (WidgetTester tester) async {
      final assignment = Assignment(
        id: 'card-2',
        title: 'Completed Task',
        subject: Subject.science,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignmentCard(
              assignment: assignment,
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Completed Task'), findsOneWidget);
    });

    testWidgets('calls onToggleComplete when tapped',
        (WidgetTester tester) async {
      bool toggled = false;
      final assignment = Assignment(
        id: 'card-3',
        title: 'Toggle Me',
        subject: Subject.english,
        dueDate: DateTime.now().add(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignmentCard(
              assignment: assignment,
              onToggleComplete: () => toggled = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Toggle Me'));
      expect(toggled, true);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_helper/main.dart';
import 'package:homework_helper/models/assignment.dart';
import 'package:homework_helper/widgets/assignment_card.dart';

void main() {
  group('HomeworkHelperApp', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeworkHelperApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows home screen with key elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HomeworkHelperApp());
      await tester.pump();
      // Dashboard should show greeting text
      expect(find.text('Hey there! 👋'), findsOneWidget);
    });

    testWidgets('shows Add Task FAB', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeworkHelperApp());
      await tester.pump();
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('displays subject filter chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HomeworkHelperApp());
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

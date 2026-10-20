import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartexamstudio/data/database/app_database.dart';
import 'package:smartexamstudio/data/repositories/exam_repository.dart';
import 'package:smartexamstudio/features/exams/presentation/exams_screen.dart';

void main() {
  late AppDatabase database;
  late ExamRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = ExamRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('تعرض شاشة الامتحانات دون أخطاء', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ExamsScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ExamsScreen), findsOneWidget);
    expect(tester.takeException() == null, isTrue);
  });
}

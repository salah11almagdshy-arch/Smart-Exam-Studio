import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.steps.dart';

import 'tables/exams.dart';
import 'tables/exam_sections.dart';
import 'tables/questions.dart';
import 'tables/question_options.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Exams, ExamSections, Questions, QuestionOptions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: stepByStep(
      from1To2: (Migrator m, schema) async {
        await m.createTable(schema.examSections);
        await m.createTable(schema.questions);
        await m.createTable(schema.questionOptions);
      },
    ),
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'smart_exam_studio');
}

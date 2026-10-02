import 'package:drift/drift.dart';

import 'exams.dart';

class ExamSections extends Table {
  TextColumn get id => text()();

  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text()();

  TextColumn get description => text().nullable()();

  IntColumn get orderIndex => integer()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

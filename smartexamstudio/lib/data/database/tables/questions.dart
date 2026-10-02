import 'package:drift/drift.dart';

import 'exam_sections.dart';

class Questions extends Table {
  TextColumn get id => text()();

  TextColumn get sectionId =>
      text().references(ExamSections, #id, onDelete: KeyAction.cascade)();

  TextColumn get questionType => text()();

  TextColumn get contentJson => text()();

  TextColumn get answerJson => text().nullable()();

  TextColumn get explanationJson => text().nullable()();

  IntColumn get marks => integer().withDefault(const Constant(1))();

  IntColumn get orderIndex => integer()();

  IntColumn get difficulty => integer().nullable()();

  TextColumn get bloomLevel => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

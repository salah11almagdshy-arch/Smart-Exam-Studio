import 'package:drift/drift.dart';

import 'questions.dart';

class QuestionOptions extends Table {
  TextColumn get id => text()();

  TextColumn get questionId =>
      text().references(Questions, #id, onDelete: KeyAction.cascade)();

  TextColumn get contentJson => text()();

  BoolColumn get isCorrect => boolean().withDefault(const Constant(false))();

  IntColumn get orderIndex => integer()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

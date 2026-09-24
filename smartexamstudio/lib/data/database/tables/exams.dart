import 'package:drift/drift.dart';

class Exams extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get description => text().nullable()();

  TextColumn get subject => text().nullable()();

  IntColumn get durationMinutes => integer().nullable()();

  IntColumn get totalMarks => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class ExamRepository {
  ExamRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<String> createExam({
    required String title,
    String? description,
    String? subject,
    int? durationMinutes,
    int totalMarks = 0,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _database
        .into(_database.exams)
        .insert(
          ExamsCompanion.insert(
            id: id,
            title: title,
            description: description == null
                ? const Value.absent()
                : Value(description),
            subject: subject == null ? const Value.absent() : Value(subject),
            durationMinutes: durationMinutes == null
                ? const Value.absent()
                : Value(durationMinutes),
            totalMarks: Value(totalMarks),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<Exam?> getExam(String id) {
    return (_database.select(
      _database.exams,
    )..where((exam) => exam.id.equals(id))).getSingleOrNull();
  }

  Future<List<Exam>> getAllExams() {
    return (_database.select(_database.exams)..orderBy([
          (exam) =>
              OrderingTerm(expression: exam.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<bool> updateExam({
    required String id,
    String? title,
    String? description,
    String? subject,
    int? durationMinutes,
    int? totalMarks,
  }) async {
    final existing = await getExam(id);

    if (existing == null) {
      return false;
    }

    final updatedTitle = title ?? existing.title;
    final updatedDescription = description ?? existing.description;
    final updatedSubject = subject ?? existing.subject;
    final updatedDuration = durationMinutes ?? existing.durationMinutes;
    final updatedTotalMarks = totalMarks ?? existing.totalMarks;

    final updated =
        await (_database.update(
          _database.exams,
        )..where((exam) => exam.id.equals(id))).write(
          ExamsCompanion(
            title: Value(updatedTitle),
            description: Value(updatedDescription),
            subject: Value(updatedSubject),
            durationMinutes: Value(updatedDuration),
            totalMarks: Value(updatedTotalMarks),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updated == 1;
  }

  Future<bool> deleteExam(String id) async {
    final deleted = await (_database.delete(
      _database.exams,
    )..where((exam) => exam.id.equals(id))).go();

    return deleted == 1;
  }
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class ExamRepository {
  ExamRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  // ------------------------------------------------------------
  // Exams
  // ------------------------------------------------------------

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

  Future<Exam?> getExam(String id) async {
    return (_database.select(
      _database.exams,
    )..where((exam) => exam.id.equals(id))).getSingleOrNull();
  }

  Future<List<Exam>> getAllExams() async {
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

    final updated =
        await (_database.update(
          _database.exams,
        )..where((exam) => exam.id.equals(id))).write(
          ExamsCompanion(
            title: Value(title ?? existing.title),
            description: Value(description ?? existing.description),
            subject: Value(subject ?? existing.subject),
            durationMinutes: Value(durationMinutes ?? existing.durationMinutes),
            totalMarks: Value(totalMarks ?? existing.totalMarks),
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

  // ------------------------------------------------------------
  // Sections
  // ------------------------------------------------------------

  Future<String> createSection({
    required String examId,
    required String title,
    String? description,
    required int orderIndex,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _database
        .into(_database.examSections)
        .insert(
          ExamSectionsCompanion.insert(
            id: id,
            examId: examId,
            title: title,
            description: description == null
                ? const Value.absent()
                : Value(description),
            orderIndex: orderIndex,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<List<ExamSection>> getSections(String examId) {
    return (_database.select(_database.examSections)
          ..where((section) => section.examId.equals(examId))
          ..orderBy([
            (section) => OrderingTerm(expression: section.orderIndex),
          ]))
        .get();
  }

  // ------------------------------------------------------------
  // Questions
  // ------------------------------------------------------------

  Future<String> createQuestion({
    required String sectionId,
    required String questionType,
    required String contentJson,
    String? answerJson,
    String? explanationJson,
    int marks = 1,
    required int orderIndex,
    int? difficulty,
    String? bloomLevel,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _database
        .into(_database.questions)
        .insert(
          QuestionsCompanion.insert(
            id: id,
            sectionId: sectionId,
            questionType: questionType,
            contentJson: contentJson,
            answerJson: answerJson == null
                ? const Value.absent()
                : Value(answerJson),
            explanationJson: explanationJson == null
                ? const Value.absent()
                : Value(explanationJson),
            marks: Value(marks),
            orderIndex: orderIndex,
            difficulty: difficulty == null
                ? const Value.absent()
                : Value(difficulty),
            bloomLevel: bloomLevel == null
                ? const Value.absent()
                : Value(bloomLevel),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<List<Question>> getQuestions(String sectionId) {
    return (_database.select(_database.questions)
          ..where((question) => question.sectionId.equals(sectionId))
          ..orderBy([
            (question) => OrderingTerm(expression: question.orderIndex),
          ]))
        .get();
  }

  // ------------------------------------------------------------
  // Options
  // ------------------------------------------------------------

  Future<String> createOption({
    required String questionId,
    required String contentJson,
    bool isCorrect = false,
    required int orderIndex,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _database
        .into(_database.questionOptions)
        .insert(
          QuestionOptionsCompanion.insert(
            id: id,
            questionId: questionId,
            contentJson: contentJson,
            isCorrect: Value(isCorrect),
            orderIndex: orderIndex,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<List<QuestionOption>> getOptions(String questionId) {
    return (_database.select(_database.questionOptions)
          ..where((option) => option.questionId.equals(questionId))
          ..orderBy([(option) => OrderingTerm(expression: option.orderIndex)]))
        .get();
  }
}

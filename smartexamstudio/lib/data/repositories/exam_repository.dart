import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class ExamRepository {
  ExamRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // Exams
  // ---------------------------------------------------------------------------

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

  Stream<List<Exam>> watchAllExams() {
    return (_database.select(_database.exams)..orderBy([
          (exam) =>
              OrderingTerm(expression: exam.updatedAt, mode: OrderingMode.desc),
        ]))
        .watch();
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
            title: title == null ? const Value.absent() : Value(title),
            description: description == null
                ? const Value.absent()
                : Value(description),
            subject: subject == null ? const Value.absent() : Value(subject),
            durationMinutes: durationMinutes == null
                ? const Value.absent()
                : Value(durationMinutes),
            totalMarks: totalMarks == null
                ? const Value.absent()
                : Value(totalMarks),
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

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Future<String> createSection({
    required String examId,
    required String title,
    String? description,
    required int orderIndex,
  }) async {
    final exam = await getExam(examId);

    if (exam == null) {
      throw StateError('Exam not found: $examId');
    }

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

  Future<ExamSection?> getSection(String id) {
    return (_database.select(
      _database.examSections,
    )..where((section) => section.id.equals(id))).getSingleOrNull();
  }

  Future<List<ExamSection>> getSections(String examId) {
    return (_database.select(_database.examSections)
          ..where((section) => section.examId.equals(examId))
          ..orderBy([
            (section) => OrderingTerm(expression: section.orderIndex),
          ]))
        .get();
  }

  Stream<List<ExamSection>> watchSections(String examId) {
    return (_database.select(_database.examSections)
          ..where((section) => section.examId.equals(examId))
          ..orderBy([
            (section) => OrderingTerm(expression: section.orderIndex),
          ]))
        .watch();
  }

  Future<bool> updateSection({
    required String id,
    String? title,
    String? description,
  }) async {
    final existing = await getSection(id);

    if (existing == null) {
      return false;
    }

    final updated =
        await (_database.update(
          _database.examSections,
        )..where((section) => section.id.equals(id))).write(
          ExamSectionsCompanion(
            title: title == null ? const Value.absent() : Value(title),
            description: description == null
                ? const Value.absent()
                : Value(description),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updated == 1;
  }

  Future<bool> deleteSection(String id) async {
    final deleted = await (_database.delete(
      _database.examSections,
    )..where((section) => section.id.equals(id))).go();

    return deleted == 1;
  }

  Future<void> reorderSections(
    String examId,
    List<String> orderedSectionIds,
  ) async {
    await _database.transaction(() async {
      final existing = await getSections(examId);
      final existingIds = existing.map((section) => section.id).toSet();
      final requestedIds = orderedSectionIds.toSet();

      if (existingIds.length != orderedSectionIds.length ||
          existingIds.length != requestedIds.length ||
          !existingIds.containsAll(requestedIds)) {
        throw StateError(
          'Reorder list must contain exactly all sections of the exam.',
        );
      }

      for (var index = 0; index < orderedSectionIds.length; index++) {
        await (_database.update(_database.examSections)
              ..where((section) => section.id.equals(orderedSectionIds[index])))
            .write(
              ExamSectionsCompanion(
                orderIndex: Value(index),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Questions
  // ---------------------------------------------------------------------------

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
    final section = await getSection(sectionId);

    if (section == null) {
      throw StateError('Section not found: $sectionId');
    }

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

  Future<Question?> getQuestion(String id) {
    return (_database.select(
      _database.questions,
    )..where((question) => question.id.equals(id))).getSingleOrNull();
  }

  Future<List<Question>> getQuestions(String sectionId) {
    return (_database.select(_database.questions)
          ..where((question) => question.sectionId.equals(sectionId))
          ..orderBy([
            (question) => OrderingTerm(expression: question.orderIndex),
          ]))
        .get();
  }

  Stream<List<Question>> watchQuestions(String sectionId) {
    return (_database.select(_database.questions)
          ..where((question) => question.sectionId.equals(sectionId))
          ..orderBy([
            (question) => OrderingTerm(expression: question.orderIndex),
          ]))
        .watch();
  }

  Future<bool> updateQuestion({
    required String id,
    String? questionType,
    String? contentJson,
    String? answerJson,
    String? explanationJson,
    int? marks,
    int? difficulty,
    String? bloomLevel,
  }) async {
    final existing = await getQuestion(id);

    if (existing == null) {
      return false;
    }

    final updated =
        await (_database.update(
          _database.questions,
        )..where((question) => question.id.equals(id))).write(
          QuestionsCompanion(
            questionType: questionType == null
                ? const Value.absent()
                : Value(questionType),
            contentJson: contentJson == null
                ? const Value.absent()
                : Value(contentJson),
            answerJson: answerJson == null
                ? const Value.absent()
                : Value(answerJson),
            explanationJson: explanationJson == null
                ? const Value.absent()
                : Value(explanationJson),
            marks: marks == null ? const Value.absent() : Value(marks),
            difficulty: difficulty == null
                ? const Value.absent()
                : Value(difficulty),
            bloomLevel: bloomLevel == null
                ? const Value.absent()
                : Value(bloomLevel),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updated == 1;
  }

  Future<bool> deleteQuestion(String id) async {
    final deleted = await (_database.delete(
      _database.questions,
    )..where((question) => question.id.equals(id))).go();

    return deleted == 1;
  }

  Future<void> reorderQuestions(
    String sectionId,
    List<String> orderedQuestionIds,
  ) async {
    await _database.transaction(() async {
      final existing = await getQuestions(sectionId);
      final existingIds = existing.map((question) => question.id).toSet();
      final requestedIds = orderedQuestionIds.toSet();

      if (existingIds.length != orderedQuestionIds.length ||
          existingIds.length != requestedIds.length ||
          !existingIds.containsAll(requestedIds)) {
        throw StateError(
          'Reorder list must contain exactly all questions of the section.',
        );
      }

      for (var index = 0; index < orderedQuestionIds.length; index++) {
        await (_database.update(_database.questions)..where(
              (question) => question.id.equals(orderedQuestionIds[index]),
            ))
            .write(
              QuestionsCompanion(
                orderIndex: Value(index),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Options
  // ---------------------------------------------------------------------------

  Future<String> createOption({
    required String questionId,
    required String contentJson,
    bool isCorrect = false,
    required int orderIndex,
  }) async {
    final question = await getQuestion(questionId);

    if (question == null) {
      throw StateError('Question not found: $questionId');
    }

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

  Future<QuestionOption?> getOption(String id) {
    return (_database.select(
      _database.questionOptions,
    )..where((option) => option.id.equals(id))).getSingleOrNull();
  }

  Future<List<QuestionOption>> getOptions(String questionId) {
    return (_database.select(_database.questionOptions)
          ..where((option) => option.questionId.equals(questionId))
          ..orderBy([(option) => OrderingTerm(expression: option.orderIndex)]))
        .get();
  }

  Stream<List<QuestionOption>> watchOptions(String questionId) {
    return (_database.select(_database.questionOptions)
          ..where((option) => option.questionId.equals(questionId))
          ..orderBy([(option) => OrderingTerm(expression: option.orderIndex)]))
        .watch();
  }

  Future<bool> updateOption({
    required String id,
    String? contentJson,
    bool? isCorrect,
  }) async {
    final existing = await getOption(id);

    if (existing == null) {
      return false;
    }

    final updated =
        await (_database.update(
          _database.questionOptions,
        )..where((option) => option.id.equals(id))).write(
          QuestionOptionsCompanion(
            contentJson: contentJson == null
                ? const Value.absent()
                : Value(contentJson),
            isCorrect: isCorrect == null
                ? const Value.absent()
                : Value(isCorrect),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updated == 1;
  }

  Future<bool> deleteOption(String id) async {
    final deleted = await (_database.delete(
      _database.questionOptions,
    )..where((option) => option.id.equals(id))).go();

    return deleted == 1;
  }

  Future<void> reorderOptions(
    String questionId,
    List<String> orderedOptionIds,
  ) async {
    await _database.transaction(() async {
      final existing = await getOptions(questionId);
      final existingIds = existing.map((option) => option.id).toSet();
      final requestedIds = orderedOptionIds.toSet();

      if (existingIds.length != orderedOptionIds.length ||
          existingIds.length != requestedIds.length ||
          !existingIds.containsAll(requestedIds)) {
        throw StateError(
          'Reorder list must contain exactly all options of the question.',
        );
      }

      for (var index = 0; index < orderedOptionIds.length; index++) {
        await (_database.update(
          _database.questionOptions,
        )..where((option) => option.id.equals(orderedOptionIds[index]))).write(
          QuestionOptionsCompanion(
            orderIndex: Value(index),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}

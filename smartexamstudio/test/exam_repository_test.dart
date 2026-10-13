import 'dart:async';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartexamstudio/data/database/app_database.dart';
import 'package:smartexamstudio/data/repositories/exam_repository.dart';

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

  group('ExamRepository - Exams', () {
    test('creates and reads an exam', () async {
      final examId = await repository.createExam(
        title: 'Mathematics Exam',
        description: 'First semester exam',
        subject: 'Mathematics',
        durationMinutes: 60,
        totalMarks: 50,
      );

      final exam = await repository.getExam(examId);

      expect(exam, isNotNull);
      expect(exam!.id, examId);
      expect(exam.title, 'Mathematics Exam');
      expect(exam.description, 'First semester exam');
      expect(exam.subject, 'Mathematics');
      expect(exam.durationMinutes, 60);
      expect(exam.totalMarks, 50);
    });

    test('updates an exam', () async {
      final examId = await repository.createExam(
        title: 'Old Title',
        totalMarks: 20,
      );

      final updated = await repository.updateExam(
        id: examId,
        title: 'New Title',
        totalMarks: 40,
      );

      final exam = await repository.getExam(examId);

      expect(updated, isTrue);
      expect(exam!.title, 'New Title');
      expect(exam.totalMarks, 40);
    });

    test('deletes an exam', () async {
      final examId = await repository.createExam(title: 'Temporary Exam');

      final deleted = await repository.deleteExam(examId);
      final exam = await repository.getExam(examId);

      expect(deleted, isTrue);
      expect(exam, isNull);
    });

    test('returns exams ordered by updatedAt descending', () async {
      final firstId = await repository.createExam(title: 'First Exam');
      final secondId = await repository.createExam(title: 'Second Exam');

      final futureTime = DateTime.now().add(const Duration(seconds: 2));

      await (database.update(database.exams)
            ..where((exam) => exam.id.equals(secondId)))
          .write(ExamsCompanion(updatedAt: Value(futureTime)));

      final exams = await repository.getAllExams();

      expect(exams.length, 2);
      expect(exams.first.id, secondId);
      expect(exams.last.id, firstId);
    });
  });

  group('ExamRepository - Sections', () {
    test('creates and reads sections', () async {
      final examId = await repository.createExam(title: 'Physics Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Multiple Choice',
        description: 'Choose one correct answer',
        orderIndex: 0,
      );

      final section = await repository.getSection(sectionId);
      final sections = await repository.getSections(examId);

      expect(section, isNotNull);
      expect(section!.examId, examId);
      expect(section.title, 'Multiple Choice');
      expect(sections.length, 1);
      expect(sections.first.id, sectionId);
    });

    test('rejects creating a section for a missing exam', () async {
      expect(
        () => repository.createSection(
          examId: 'missing-exam',
          title: 'Invalid Section',
          orderIndex: 0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('updates and deletes a section', () async {
      final examId = await repository.createExam(title: 'English Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Old Section',
        orderIndex: 0,
      );

      final updated = await repository.updateSection(
        id: sectionId,
        title: 'New Section',
      );

      expect(updated, isTrue);
      expect((await repository.getSection(sectionId))!.title, 'New Section');

      final deleted = await repository.deleteSection(sectionId);

      expect(deleted, isTrue);
      expect(await repository.getSection(sectionId), isNull);
    });

    test('reorders sections correctly', () async {
      final examId = await repository.createExam(title: 'Chemistry Exam');

      final sectionA = await repository.createSection(
        examId: examId,
        title: 'Section A',
        orderIndex: 0,
      );

      final sectionB = await repository.createSection(
        examId: examId,
        title: 'Section B',
        orderIndex: 1,
      );

      final sectionC = await repository.createSection(
        examId: examId,
        title: 'Section C',
        orderIndex: 2,
      );

      await repository.reorderSections(examId, [sectionC, sectionA, sectionB]);

      final sections = await repository.getSections(examId);

      expect(sections.map((section) => section.id).toList(), [
        sectionC,
        sectionA,
        sectionB,
      ]);

      expect(sections[0].orderIndex, 0);
      expect(sections[1].orderIndex, 1);
      expect(sections[2].orderIndex, 2);
    });
  });

  group('ExamRepository - Questions', () {
    test('creates and reads questions', () async {
      final examId = await repository.createExam(title: 'Biology Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Section 1',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{"text":"What is DNA?"}',
        answerJson: '{"answer":"Genetic material"}',
        marks: 2,
        orderIndex: 0,
        difficulty: 2,
        bloomLevel: 'understand',
      );

      final question = await repository.getQuestion(questionId);
      final questions = await repository.getQuestions(sectionId);

      expect(question, isNotNull);
      expect(question!.sectionId, sectionId);
      expect(question.questionType, 'mcq');
      expect(question.marks, 2);
      expect(question.difficulty, 2);
      expect(question.bloomLevel, 'understand');
      expect(questions.length, 1);
    });

    test('rejects creating a question for a missing section', () async {
      expect(
        () => repository.createQuestion(
          sectionId: 'missing-section',
          questionType: 'mcq',
          contentJson: '{}',
          orderIndex: 0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('updates and deletes a question', () async {
      final examId = await repository.createExam(
        title: 'Computer Science Exam',
      );

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Programming',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'short_answer',
        contentJson: '{"text":"Old question"}',
        orderIndex: 0,
      );

      final updated = await repository.updateQuestion(
        id: questionId,
        contentJson: '{"text":"New question"}',
        marks: 5,
      );

      final question = await repository.getQuestion(questionId);

      expect(updated, isTrue);
      expect(question!.contentJson, '{"text":"New question"}');
      expect(question.marks, 5);

      final deleted = await repository.deleteQuestion(questionId);

      expect(deleted, isTrue);
      expect(await repository.getQuestion(questionId), isNull);
    });

    test('reorders questions correctly', () async {
      final examId = await repository.createExam(title: 'Arabic Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Grammar',
        orderIndex: 0,
      );

      final questionA = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{"text":"A"}',
        orderIndex: 0,
      );

      final questionB = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{"text":"B"}',
        orderIndex: 1,
      );

      final questionC = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{"text":"C"}',
        orderIndex: 2,
      );

      await repository.reorderQuestions(sectionId, [
        questionC,
        questionA,
        questionB,
      ]);

      final questions = await repository.getQuestions(sectionId);

      expect(questions.map((question) => question.id).toList(), [
        questionC,
        questionA,
        questionB,
      ]);

      expect(questions[0].orderIndex, 0);
      expect(questions[1].orderIndex, 1);
      expect(questions[2].orderIndex, 2);
    });
  });

  group('ExamRepository - Options', () {
    test('creates and reads options', () async {
      final examId = await repository.createExam(
        title: 'General Knowledge Exam',
      );

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Section 1',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{"text":"2 + 2 = ?"}',
        orderIndex: 0,
      );

      final optionId = await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"4"}',
        isCorrect: true,
        orderIndex: 0,
      );

      final option = await repository.getOption(optionId);
      final options = await repository.getOptions(questionId);

      expect(option, isNotNull);
      expect(option!.questionId, questionId);
      expect(option.isCorrect, isTrue);
      expect(options.length, 1);
    });

    test('updates and deletes an option', () async {
      final examId = await repository.createExam(title: 'Test Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Section 1',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 0,
      );

      final optionId = await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"Wrong"}',
        isCorrect: false,
        orderIndex: 0,
      );

      final updated = await repository.updateOption(
        id: optionId,
        contentJson: '{"text":"Correct"}',
        isCorrect: true,
      );

      final option = await repository.getOption(optionId);

      expect(updated, isTrue);
      expect(option!.contentJson, '{"text":"Correct"}');
      expect(option.isCorrect, isTrue);

      final deleted = await repository.deleteOption(optionId);

      expect(deleted, isTrue);
      expect(await repository.getOption(optionId), isNull);
    });

    test('reorders options correctly', () async {
      final examId = await repository.createExam(title: 'Options Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Section 1',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 0,
      );

      final optionA = await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"A"}',
        orderIndex: 0,
      );

      final optionB = await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"B"}',
        orderIndex: 1,
      );

      final optionC = await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"C"}',
        orderIndex: 2,
      );

      await repository.reorderOptions(questionId, [optionC, optionA, optionB]);

      final options = await repository.getOptions(questionId);

      expect(options.map((option) => option.id).toList(), [
        optionC,
        optionA,
        optionB,
      ]);

      expect(options[0].orderIndex, 0);
      expect(options[1].orderIndex, 1);
      expect(options[2].orderIndex, 2);
    });
  });

  group('Cascade delete', () {
    test('deleting an exam deletes sections, questions and options', () async {
      final examId = await repository.createExam(title: 'Cascade Test');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Section 1',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 0,
      );

      final optionId = await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"Option"}',
        isCorrect: true,
        orderIndex: 0,
      );

      expect(await repository.getSection(sectionId), isNotNull);
      expect(await repository.getQuestion(questionId), isNotNull);
      expect(await repository.getOption(optionId), isNotNull);

      final deleted = await repository.deleteExam(examId);

      expect(deleted, isTrue);

      expect(await repository.getExam(examId), isNull);
      expect(await repository.getSection(sectionId), isNull);
      expect(await repository.getQuestion(questionId), isNull);
      expect(await repository.getOption(optionId), isNull);
    });
  });

  group('ExamRepository - Streams', () {
    test('watchAllExams emits initial data and updates after insert', () async {
      final iterator = StreamIterator(
        repository.watchAllExams().map((exams) => exams.length),
      );

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, 0);

      final update = iterator.moveNext();

      await repository.createExam(title: 'Stream Exam');

      expect(await update, isTrue);
      expect(iterator.current, 1);

      await iterator.cancel();
    });

    test('watchSections emits updates after section changes', () async {
      final examId = await repository.createExam(title: 'Stream Section Exam');

      final stream = repository.watchSections(examId);

      final expectation = expectLater(
        stream.map((sections) => sections.length),
        emitsInOrder([0, 1, 2]),
      );

      await repository.createSection(
        examId: examId,
        title: 'Section 1',
        orderIndex: 0,
      );

      await repository.createSection(
        examId: examId,
        title: 'Section 2',
        orderIndex: 1,
      );

      await expectation;
    });

    test('watchQuestions emits updates after question changes', () async {
      final examId = await repository.createExam(title: 'Stream Question Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Questions',
        orderIndex: 0,
      );

      final stream = repository.watchQuestions(sectionId);

      final expectation = expectLater(
        stream.map((questions) => questions.length),
        emitsInOrder([0, 1]),
      );

      await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 0,
      );

      await expectation;
    });

    test('watchOptions emits updates after option changes', () async {
      final examId = await repository.createExam(title: 'Stream Option Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Options',
        orderIndex: 0,
      );

      final questionId = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 0,
      );

      final stream = repository.watchOptions(questionId);

      final expectation = expectLater(
        stream.map((options) => options.length),
        emitsInOrder([0, 1]),
      );

      await repository.createOption(
        questionId: questionId,
        contentJson: '{"text":"Option 1"}',
        orderIndex: 0,
      );

      await expectation;
    });
  });

  group('Validation', () {
    test('reorderSections rejects an incomplete list', () async {
      final examId = await repository.createExam(title: 'Validation Exam');

      final sectionA = await repository.createSection(
        examId: examId,
        title: 'A',
        orderIndex: 0,
      );

      await repository.createSection(examId: examId, title: 'B', orderIndex: 1);

      expect(
        () => repository.reorderSections(examId, [sectionA]),
        throwsA(isA<StateError>()),
      );
    });

    test('reorderQuestions rejects duplicate IDs', () async {
      final examId = await repository.createExam(title: 'Validation Exam');

      final sectionId = await repository.createSection(
        examId: examId,
        title: 'Section',
        orderIndex: 0,
      );

      final questionA = await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 0,
      );

      await repository.createQuestion(
        sectionId: sectionId,
        questionType: 'mcq',
        contentJson: '{}',
        orderIndex: 1,
      );

      expect(
        () => repository.reorderQuestions(sectionId, [questionA, questionA]),
        throwsA(isA<StateError>()),
      );
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartexamstudio/data/database/app_database.dart';
import 'package:smartexamstudio/data/repositories/exam_repository.dart';

void main() {
  late AppDatabase database;
  late ExamRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ExamRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('create exam with section, question, and options', () async {
    // ----------------------------------------------------------
    // EXAM
    // ----------------------------------------------------------

    final examId = await repository.createExam(
      title: 'Cybersecurity Fundamentals',
      subject: 'Cybersecurity',
      durationMinutes: 60,
      totalMarks: 100,
    );

    final exam = await repository.getExam(examId);

    expect(exam, isNotNull);
    expect(exam!.title, 'Cybersecurity Fundamentals');

    // ----------------------------------------------------------
    // SECTION
    // ----------------------------------------------------------

    final sectionId = await repository.createSection(
      examId: examId,
      title: 'Network Security',
      description: 'Fundamental network security questions',
      orderIndex: 0,
    );

    final sections = await repository.getSections(examId);

    expect(sections, hasLength(1));
    expect(sections.first.id, sectionId);
    expect(sections.first.title, 'Network Security');

    // ----------------------------------------------------------
    // QUESTION
    // ----------------------------------------------------------

    final questionId = await repository.createQuestion(
      sectionId: sectionId,
      questionType: 'mcq',
      contentJson: '{"text":"What does CIA stand for?"}',
      answerJson: '{"type":"single","correctOptionIndex":0}',
      marks: 5,
      orderIndex: 0,
      difficulty: 2,
      bloomLevel: 'understand',
    );

    final questions = await repository.getQuestions(sectionId);

    expect(questions, hasLength(1));
    expect(questions.first.id, questionId);
    expect(questions.first.questionType, 'mcq');
    expect(questions.first.marks, 5);
    expect(questions.first.difficulty, 2);
    expect(questions.first.bloomLevel, 'understand');

    // ----------------------------------------------------------
    // OPTIONS
    // ----------------------------------------------------------

    await repository.createOption(
      questionId: questionId,
      contentJson: '{"text":"Confidentiality, Integrity, Availability"}',
      isCorrect: true,
      orderIndex: 0,
    );

    await repository.createOption(
      questionId: questionId,
      contentJson: '{"text":"Control, Identity, Authentication"}',
      orderIndex: 1,
    );

    await repository.createOption(
      questionId: questionId,
      contentJson: '{"text":"Cloud, Internet, Access"}',
      orderIndex: 2,
    );

    await repository.createOption(
      questionId: questionId,
      contentJson: '{"text":"Computer, Information, Administration"}',
      orderIndex: 3,
    );

    final options = await repository.getOptions(questionId);

    expect(options, hasLength(4));

    expect(options[0].orderIndex, 0);
    expect(options[1].orderIndex, 1);
    expect(options[2].orderIndex, 2);
    expect(options[3].orderIndex, 3);

    expect(options[0].isCorrect, isTrue);
    expect(options[1].isCorrect, isFalse);
    expect(options[2].isCorrect, isFalse);
    expect(options[3].isCorrect, isFalse);
  });
}

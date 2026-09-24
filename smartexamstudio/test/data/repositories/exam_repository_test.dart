import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartexamstudio/data/database/app_database.dart';
import 'package:smartexamstudio/data/repositories/exam_repository.dart';

void main() {
  late AppDatabase database;
  late ExamRepository repository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    repository = ExamRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('CRUD: create, read, update, list, delete exam', () async {
    // CREATE
    final id = await repository.createExam(
      title: 'Network Security Exam',
      description: 'Basic network security assessment',
      subject: 'Cybersecurity',
      durationMinutes: 60,
      totalMarks: 100,
    );

    expect(id, isNotEmpty);

    // READ
    final created = await repository.getExam(id);

    expect(created, isNotNull);
    expect(created!.id, id);
    expect(created.title, 'Network Security Exam');
    expect(created.subject, 'Cybersecurity');
    expect(created.durationMinutes, 60);
    expect(created.totalMarks, 100);

    // UPDATE
    final updated = await repository.updateExam(
      id: id,
      title: 'Advanced Network Security Exam',
      totalMarks: 120,
    );

    expect(updated, isTrue);

    final afterUpdate = await repository.getExam(id);

    expect(afterUpdate, isNotNull);
    expect(afterUpdate!.title, 'Advanced Network Security Exam');
    expect(afterUpdate.totalMarks, 120);
    expect(afterUpdate.subject, 'Cybersecurity');

    // LIST
    final exams = await repository.getAllExams();

    expect(exams, hasLength(1));
    expect(exams.first.id, id);

    // DELETE
    final deleted = await repository.deleteExam(id);

    expect(deleted, isTrue);

    final afterDelete = await repository.getExam(id);

    expect(afterDelete, isNull);

    final emptyList = await repository.getAllExams();

    expect(emptyList, isEmpty);
  });

  test('getExam returns null for an unknown ID', () async {
    final result = await repository.getExam('does-not-exist');

    expect(result, isNull);
  });

  test('updateExam returns false for an unknown ID', () async {
    final result = await repository.updateExam(
      id: 'does-not-exist',
      title: 'Updated',
    );

    expect(result, isFalse);
  });

  test('deleteExam returns false for an unknown ID', () async {
    final result = await repository.deleteExam('does-not-exist');

    expect(result, isFalse);
  });
}

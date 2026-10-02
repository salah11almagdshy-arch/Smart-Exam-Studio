// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:smartexamstudio/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with
    // a simple (no data) migration.
    const versions = GeneratedHelper.versions;

    for (final (i, fromVersion) in versions.indexed) {
      group('$fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('$toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());

            await verifier.migrateAndValidate(db, toVersion);

            await db.close();
          });
        }
      });
    }
  });

  test('migration from v1 to v2 preserves existing exam data', () async {
    final oldExamsData = <v1.ExamsData>[
      v1.ExamsData(
        id: 'legacy-exam-001',
        title: 'Legacy Mathematics Exam',
        description: 'Exam created before schema version 2',
        subject: 'Mathematics',
        durationMinutes: 60,
        totalMarks: 50,
        createdAt: 1750000000000,
        updatedAt: 1750000060000,
      ),
    ];

    final expectedNewExamsData = <v2.ExamsData>[
      v2.ExamsData(
        id: 'legacy-exam-001',
        title: 'Legacy Mathematics Exam',
        description: 'Exam created before schema version 2',
        subject: 'Mathematics',
        durationMinutes: 60,
        totalMarks: 50,
        createdAt: 1750000000000,
        updatedAt: 1750000060000,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.exams, oldExamsData);
      },
      validateItems: (newDb) async {
        final actualExams = await newDb.select(newDb.exams).get();

        expect(actualExams, expectedNewExamsData);
      },
    );
  });
}

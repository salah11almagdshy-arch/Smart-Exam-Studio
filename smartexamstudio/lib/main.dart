import 'package:flutter/material.dart';

import 'data/database/app_database.dart';
import 'data/repositories/exam_repository.dart';
import 'features/exams/presentation/exams_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartExamStudioApp());
}

class SmartExamStudioApp extends StatefulWidget {
  const SmartExamStudioApp({super.key});

  @override
  State<SmartExamStudioApp> createState() => _SmartExamStudioAppState();
}

class _SmartExamStudioAppState extends State<SmartExamStudioApp> {
  late final AppDatabase _database;
  late final ExamRepository _examRepository;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _examRepository = ExamRepository(_database);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2457C5);

    return MaterialApp(
      title: 'Smart Exam Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FC),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8EAF0)),
          ),
        ),
      ),
      home: ExamsScreen(repository: _examRepository),
    );
  }
}

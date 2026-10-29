import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/exam_repository.dart';

class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.repository,
  });

  final String examId;
  final String examTitle;
  final ExamRepository repository;

  @override
  State<QuestionEditorScreen> createState() =>
      _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  String? _selectedSectionId;
  bool _creatingSection = false;

  Future<void> _addSection() async {
    final controller = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قسم جديد'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم القسم',
            hintText: 'مثال: القسم الأول',
          ),
          onSubmitted: (_) {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(context, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (title == null || title.trim().isEmpty || !mounted) {
      return;
    }

    setState(() => _creatingSection = true);

    try {
      final sections =
          await widget.repository.getSections(widget.examId);

      final id = await widget.repository.createSection(
        examId: widget.examId,
        title: title.trim(),
        orderIndex: sections.length,
      );

      if (!mounted) return;

      setState(() {
        _selectedSectionId = id;
        _creatingSection = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء القسم')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _creatingSection = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء القسم: $error')),
      );
    }
  }

  Future<void> _addQuestion(String sectionId) async {
    try {
      final questions =
          await widget.repository.getQuestions(sectionId);

      final id = await widget.repository.createQuestion(
        sectionId: sectionId,
        questionType: 'essay',
        contentJson: jsonEncode([
          {'insert': '\n'},
        ]),
        marks: 1,
        orderIndex: questions.length,
      );

      if (!mounted) return;

      final question = await widget.repository.getQuestion(id);

      if (question == null || !mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionContentEditorScreen(
            question: question,
            repository: widget.repository,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء السؤال: $error')),
      );
    }
  }

  Future<void> _openQuestion(Question question) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionContentEditorScreen(
          question: question,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السؤال'),
        content: const Text('هل تريد حذف هذا السؤال نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteQuestion(question.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف السؤال')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف السؤال: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.examTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<List<ExamSection>>(
        stream: widget.repository.watchSections(widget.examId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('تعذر تحميل الأقسام: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final sections = snapshot.data!;

          if (sections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.library_books_outlined,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ابدأ ببناء امتحانك',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أنشئ قسمًا أولًا، ثم أضف الأسئلة إليه.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed:
                          _creatingSection ? null : _addSection,
                      icon: const Icon(Icons.create_new_folder),
                      label: const Text('إنشاء القسم الأول'),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedId = sections.any(
            (section) => section.id == _selectedSectionId,
          )
              ? _selectedSectionId!
              : sections.first.id;

          if (_selectedSectionId != selectedId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedSectionId = selectedId;
                });
              }
            });
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(selectedId),
                        initialValue: selectedId,
                        decoration: const InputDecoration(
                          labelText: 'القسم الحالي',
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                        items: sections.map((section) {
                          return DropdownMenuItem<String>(
                            value: section.id,
                            child: Text(
                              section.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSectionId = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'إضافة قسم',
                      onPressed:
                          _creatingSection ? null : _addSection,
                      icon: const Icon(Icons.create_new_folder_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Question>>(
                  key: ValueKey(selectedId),
                  stream:
                      widget.repository.watchQuestions(selectedId),
                  builder: (context, questionSnapshot) {
                    if (questionSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'تعذر تحميل الأسئلة: '
                          '${questionSnapshot.error}',
                        ),
                      );
                    }

                    if (!questionSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final questions = questionSnapshot.data!;

                    if (questions.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد أسئلة في هذا القسم بعد.',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final question = questions[index];

                        String preview;
                        try {
                          final document = Document.fromJson(
                            jsonDecode(question.contentJson)
                                as List<dynamic>,
                          );
                          preview = document.toPlainText().trim();
                        } catch (_) {
                          preview = question.contentJson;
                        }

                        if (preview.isEmpty) {
                          preview = 'سؤال جديد';
                        }

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'الدرجة: ${question.marks} '
                              '• النوع: ${question.questionType}',
                            ),
                            onTap: () => _openQuestion(question),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openQuestion(question);
                                } else if (value == 'delete') {
                                  _deleteQuestion(question);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تحرير'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _addQuestion(selectedId),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة سؤال'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class QuestionContentEditorScreen extends StatefulWidget {
  const QuestionContentEditorScreen({
    super.key,
    required this.question,
    required this.repository,
  });

  final Question question;
  final ExamRepository repository;

  @override
  State<QuestionContentEditorScreen> createState() =>
      _QuestionContentEditorScreenState();
}

class _QuestionContentEditorScreenState
    extends State<QuestionContentEditorScreen> {
  late final QuillController _controller;
  late final TextEditingController _marksController;

  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();

    Document document;

    try {
      document = Document.fromJson(
        jsonDecode(widget.question.contentJson) as List<dynamic>,
      );
    } catch (_) {
      document = Document()..insert(0, '\n');
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _marksController = TextEditingController(
      text: '${widget.question.marks}',
    );

    _controller.addListener(_onDocumentChanged);
  }

  void _onDocumentChanged() {
    _dirty = true;
  }

  Future<void> _save() async {
    if (_saving) return;

    final marks = int.tryParse(_marksController.text.trim());

    if (marks == null || marks < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل درجة صحيحة لا تقل عن صفر.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final contentJson = jsonEncode(
        _controller.document.toDelta().toJson(),
      );

      final updated = await widget.repository.updateQuestion(
        id: widget.question.id,
        contentJson: contentJson,
        marks: marks,
      );

      if (!mounted) return;

      if (!updated) {
        throw StateError('لم يتم العثور على السؤال في قاعدة البيانات.');
      }

      setState(() {
        _saving = false;
        _dirty = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ السؤال بنجاح'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ السؤال: $error')),
      );
    }
  }

  Future<bool> _confirmLeave() async {
if (!_dirty) return true;

final leave = await showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('تغييرات غير محفوظة'),
    content: const Text(
      'هل تريد الخروج دون حفظ التغييرات؟',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext, false),
        child: const Text('البقاء'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(dialogContext, true),
        child: const Text('الخروج'),
      ),
    ],
  ),
);

if (!mounted) return false;

return leave ?? false;

  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldLeave = await _confirmLeave();

        if (shouldLeave && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحرير السؤال'),
          actions: [
            IconButton(
              tooltip: 'حفظ',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _marksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'درجة السؤال',
                    prefixIcon: Icon(Icons.grade_outlined),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: QuillSimpleToolbar(
                  controller: _controller,
                  config: const QuillSimpleToolbarConfig(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: QuillEditor.basic(
                    controller: _controller,
                    config: const QuillEditorConfig(
                      placeholder: 'اكتب نص السؤال هنا...',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _saving ? 'جارٍ الحفظ...' : 'حفظ السؤال',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/exam_repository.dart';
import 'question_editor_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key, required this.repository});

  final ExamRepository repository;

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

 void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openExam(Exam exam) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionEditorScreen(
          examId: exam.id,
          examTitle: exam.title,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _showCreateExamDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    final marksController = TextEditingController(text: '100');

    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('إنشاء امتحان جديد'),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            autofocus: true,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'عنوان الامتحان *',
                              hintText: 'مثال: امتحان الفصل الأول',
                              prefixIcon: Icon(Icons.edit_note),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'أدخل عنوان الامتحان';
                              }
                              if (value.trim().length > 200) {
                                return 'العنوان طويل جدًا';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: subjectController,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'المادة الدراسية',
                              prefixIcon: Icon(Icons.menu_book_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'وصف الامتحان',
                              prefixIcon: Icon(Icons.description_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'المدة بالدقائق',
                              prefixIcon: Icon(Icons.timer_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final number = int.tryParse(text);
                              if (number == null || number <= 0) {
                                return 'أدخل مدة صحيحة أكبر من صفر';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: marksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الدرجة الكلية',
                              prefixIcon: Icon(Icons.grade_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = int.tryParse(value?.trim() ?? '');
                              if (number == null || number < 0) {
                                return 'أدخل درجة صحيحة (صفر أو أكثر)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setDialogState(() => saving = true);

                            try {
                              await widget.repository.createExam(
                                title: titleController.text.trim(),
                                subject: subjectController.text.trim().isEmpty
                                    ? null
                                    : subjectController.text.trim(),
                                description:
                                    descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                durationMinutes:
                                    durationController.text.trim().isEmpty
                                    ? null
                                    : int.parse(durationController.text.trim()),
                                totalMarks: int.parse(
                                  marksController.text.trim(),
                                ),
                              );

                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              _showMessage('تم إنشاء الامتحان بنجاح');
                            } catch (error) {
                              setDialogState(() => saving = false);
                              _showMessage('تعذر إنشاء الامتحان: $error');
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ الامتحان'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      subjectController.dispose();
      descriptionController.dispose();
      durationController.dispose();
      marksController.dispose();
    }
  }

  Future<void> _confirmDelete(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الامتحان؟'),
        content: Text(
          'هل تريد حذف «${exam.title}»؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deleted = await widget.repository.deleteExam(exam.id);
      if (!mounted) return;

      _showMessage(
        deleted ? 'تم حذف الامتحان' : 'الامتحان غير موجود أو حُذف مسبقًا',
      );
    } catch (error) {
      _showMessage('تعذر حذف الامتحان: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'استوديو الامتحانات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'إنشاء امتحان',
              onPressed: _showCreateExamDialog,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateExamDialog,
          icon: const Icon(Icons.add),
          label: const Text('امتحان جديد'),
        ),
        body: SafeArea(
          child: StreamBuilder<List<Exam>>(
            stream: widget.repository.watchAllExams(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _StatusView(
                  icon: Icons.error_outline,
                  title: 'تعذر تحميل الامتحانات',
                  message: 'حدث خطأ أثناء قراءة قاعدة البيانات.',
                  actionLabel: 'إعادة المحاولة',
                  onAction: () => setState(() {}),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final exams = snapshot.data ?? const <Exam>[];
              final query = _searchQuery.trim().toLowerCase();
              final filteredExams = exams.where((exam) {
                return exam.title.toLowerCase().contains(query) ||
                    (exam.subject?.toLowerCase().contains(query) ?? false) ||
                    (exam.description?.toLowerCase().contains(query) ?? false);
              }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [colors.primary, colors.primaryContainer],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: colors.onPrimary,
                          size: 30,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'أنشئ امتحاناتك بذكاء',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نظّم امتحاناتك وموادك من مكان واحد.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _SummaryChip(
                              icon: Icons.assignment_outlined,
                              label: 'إجمالي الامتحانات: ${exams.length}',
                              foreground: colors.onPrimary,
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _showCreateExamDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('إنشاء امتحان'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'امتحاناتي',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالعنوان أو المادة...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (exams.isEmpty)
                    _StatusView(
                      icon: Icons.library_add_outlined,
                      title: 'لا توجد امتحانات حتى الآن',
                      message:
                          'أنشئ امتحانك الأول، وستظهر بياناته هنا بعد حفظه.',
                      actionLabel: 'إنشاء أول امتحان',
                      onAction: _showCreateExamDialog,
                    )
                  else if (filteredExams.isEmpty)
                    const _StatusView(
                      icon: Icons.search_off,
                      title: 'لا توجد نتائج',
                      message: 'جرّب البحث بعنوان أو مادة مختلفة.',
                    )
                  else
                   ...filteredExams.map(
                      (exam) => _ExamCard(
                        exam: exam,
                        onOpen: () => _openExam(exam),
                        onDelete: () => _confirmDelete(exam),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.onOpen,
    required this.onDelete,
  });

  final Exam exam;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exam.subject != null &&
                        exam.subject!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('المادة: ${exam.subject}'),
                    ],
                    if (exam.description != null &&
                        exam.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exam.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _MetadataItem(
                          icon: Icons.grade_outlined,
                          text: '${exam.totalMarks} درجة',
                        ),
                       if (exam.durationMinutes != null)
                          _MetadataItem(
                            icon: Icons.timer_outlined,
                            text: '${exam.durationMinutes} دقيقة',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'حذف الامتحان',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: foreground, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

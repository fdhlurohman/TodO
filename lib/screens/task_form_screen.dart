// ============================================================
// LAYAR: FORM TAMBAH/EDIT TUGAS
// Satu layar untuk membuat tugas baru dan mengedit yang sudah ada.
// Fitur input:
//  - Judul (wajib) & catatan
//  - Kategori (pilihan dari CategoryProvider)
//  - Prioritas (High/Medium/Low sebagai SegmentedButton)
//  - Deadline: date picker + time picker
//  - Pengulangan: Tidak/Harian/Mingguan/Bulanan
//  - Sub-tugas: tambah/hapus/centang
//  - Tombol simpan -> TaskProvider.addTask / updateTask
//    + otomatis menjadwalkan pengingat notifikasi
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:premium_todo/core/utils/date_utils.dart';
import 'package:premium_todo/core/utils/id_generator.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/models/subtask.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/models/task_priority.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  /// Jika tidak null berarti mode edit.
  final Task? existing;
  const TaskFormScreen({super.key, this.existing});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _notesCtrl = TextEditingController(
    text: widget.existing?.notes ?? '',
  );

  // ---------------- STATE FORM ----------------
  Category? _category; // kategori terpilih
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate; // deadline (tanggal + jam)
  Recurrence _recurrence = Recurrence.none;
  final List<SubTask> _subtasks = [];
  bool _reminder = true; // jadwalkan notifikasi?

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      // Prefill saat mode edit.
      _category = context.read<CategoryProvider>().byId(t.categoryIdRef);
      _priority = t.priority;
      _dueDate = t.dueDate;
      _recurrence = t.recurrence;
      _reminder = t.reminderEnabled;
      _subtasks.addAll(t.subtasks);
    }
  }

  // ---------------- SUB-TUGAS ----------------
  final TextEditingController _subtaskCtrl = TextEditingController();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  static const _stepTitles = [
    'Detail tugas',
    'Kategori & prioritas',
    'Jadwal',
    'Sub-tugas',
  ];

  void _addSubtask() {
    final text = _subtaskCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask.create(text));
      _subtaskCtrl.clear();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _subtaskCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Tugas Baru' : 'Edit Tugas'),
      ),
      body: widget.existing == null
          ? _buildTaskWizard(categories)
          : _buildEditForm(categories),
    );
  }

  Widget _buildTaskWizard(List<Category> categories) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tahap ${_currentStep + 1} dari ${_stepTitles.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _stepTitles.length,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 12),
                Text(
                  _stepTitles[_currentStep],
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _wizardPage(0, _buildDetailsFields()),
                _wizardPage(1, _buildCategoryPriorityFields(categories)),
                _wizardPage(2, _buildScheduleFields()),
                _wizardPage(3, _buildSubtaskFields()),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _previousStep,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Kembali'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : _currentStep == _stepTitles.length - 1
                          ? _save
                          : _nextStep,
                      icon: Icon(
                        _currentStep == _stepTitles.length - 1
                            ? Icons.save_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _currentStep == _stepTitles.length - 1
                            ? 'Simpan Tugas'
                            : 'Berikutnya',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wizardPage(int step, List<Widget> children) => ListView(
    key: PageStorageKey<int>(step),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: children,
  );

  Widget _buildEditForm(List<Category> categories) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._buildDetailsFields(),
        ..._buildCategoryPriorityFields(categories),
        ..._buildScheduleFields(),
        ..._buildSubtaskFields(),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Perbarui Tugas'),
          onPressed: _save,
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  List<Widget> _buildDetailsFields() => [
    TextFormField(
      controller: _titleCtrl,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Judul tugas *',
        hintText: 'cth: Kirim laporan bulanan',
        prefixIcon: Icon(Icons.edit_rounded),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
    ),
    const SizedBox(height: 12),
    TextFormField(
      controller: _notesCtrl,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Catatan (opsional)',
        prefixIcon: Icon(Icons.notes_rounded),
        alignLabelWithHint: true,
      ),
    ),
    const SizedBox(height: 16),
  ];

  List<Widget> _buildCategoryPriorityFields(List<Category> categories) => [
    _sectionTitle('Kategori'),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Tanpa kategori'),
          selected: _category == null,
          onSelected: (_) => setState(() => _category = null),
        ),
        ...categories.map(
          (category) => ChoiceChip(
            label: Text(category.name),
            selected: _category?.id == category.id,
            onSelected: (_) => setState(() => _category = category),
            avatar: Icon(category.icon, size: 16, color: category.color),
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
    _sectionTitle('Prioritas'),
    const SizedBox(height: 8),
    SegmentedButton<TaskPriority>(
      segments: TaskPriority.values
          .map(
            (priority) => ButtonSegment(
              value: priority,
              label: Text(priority.label),
              icon: Icon(
                priorityIcon(priority),
                size: 16,
                color: Color(priority.colorValue),
              ),
            ),
          )
          .toList(),
      selected: {_priority},
      onSelectionChanged: (set) => setState(() => _priority = set.first),
    ),
  ];

  List<Widget> _buildScheduleFields() => [
    _sectionTitle('Deadline'),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(
              _dueDate == null
                  ? 'Pilih tanggal'
                  : AppDateUtils.formatDate(_dueDate!),
            ),
            onPressed: _pickDate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.schedule_rounded),
            label: Text(
              _dueDate == null
                  ? 'Pilih jam'
                  : AppDateUtils.formatTime(_dueDate!),
            ),
            onPressed: _dueDate == null ? null : _pickTime,
          ),
        ),
        if (_dueDate != null)
          IconButton(
            tooltip: 'Hapus deadline',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(() => _dueDate = null),
          ),
      ],
    ),
    const SizedBox(height: 20),
    _sectionTitle('Pengulangan'),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Recurrence.values
          .map(
            (recurrence) => ChoiceChip(
              label: Text(recurrence.label),
              selected: _recurrence == recurrence,
              onSelected: (_) => setState(() => _recurrence = recurrence),
            ),
          )
          .toList(),
    ),
    const SizedBox(height: 16),
    Builder(
      builder: (context) {
        final reminderMinutesBefore = context.select<TaskProvider, int>(
          (provider) => provider.reminderMinutesBefore,
        );
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pengingat notifikasi'),
          subtitle: Text(
            'Notifikasi $reminderMinutesBefore menit sebelum deadline '
            '(diatur di Pengaturan)',
          ),
          value: _reminder,
          onChanged: (value) => setState(() => _reminder = value),
        );
      },
    ),
  ];

  List<Widget> _buildSubtaskFields() => [
    _sectionTitle('Sub-tugas (${_subtasks.length})'),
    const SizedBox(height: 8),
    ..._subtasks.asMap().entries.map(
      (entry) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Checkbox(
          value: entry.value.isDone,
          onChanged: (value) =>
              setState(() => entry.value.isDone = value ?? false),
        ),
        title: Text(
          entry.value.title,
          style: TextStyle(
            decoration: entry.value.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Hapus sub-tugas',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => setState(() => _subtasks.removeAt(entry.key)),
        ),
      ),
    ),
    TextField(
      controller: _subtaskCtrl,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'Tambah sub-tugas...',
        prefixIcon: const Icon(Icons.add_rounded),
        suffixIcon: IconButton(
          tooltip: 'Tambah sub-tugas',
          icon: const Icon(Icons.check_rounded),
          onPressed: _addSubtask,
        ),
      ),
      onSubmitted: (_) => _addSubtask(),
    ),
    const SizedBox(height: 12),
    Text(
      'Sub-tugas bersifat opsional. Kamu bisa langsung menyimpan tugas.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ];

  Widget _sectionTitle(String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  );

  Future<void> _nextStep() async {
    if (_currentStep == 0 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _currentStep++);
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _previousStep() async {
    setState(() => _currentStep--);
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // ---------------- PICKER TANGGAL & JAM ----------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      // Pertahankan jam jika sudah dipilih sebelumnya.
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueDate?.hour ?? 9,
        _dueDate?.minute ?? 0,
      );
    });
  }

  Future<void> _pickTime() async {
    if (_dueDate == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate!),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  // ---------------- SIMPAN ----------------
  Future<void> _save() async {
    if (widget.existing != null &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      if (widget.existing == null && _currentStep != 0) {
        setState(() => _currentStep = 0);
        await _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<TaskProvider>();
      final now = DateTime.now();
      var notificationSyncSucceeded = true;

      if (widget.existing == null) {
        final task = Task(
          id: genId(),
          title: _titleCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          categoryIdRef: _category?.id,
          priority: _priority,
          recurrence: _recurrence,
          dueDate: _dueDate,
          createdAt: now,
          subtasks: List.from(_subtasks),
          reminderEnabled: _reminder,
        );
        notificationSyncSucceeded = await provider.addTask(task);
      } else {
        final task = widget.existing!;
        final previousDueDate = task.dueDate;
        final previousRecurrence = task.recurrence;
        task.title = _titleCtrl.text.trim();
        task.notes = _notesCtrl.text.trim();
        task.categoryIdRef = _category?.id;
        task.priority = _priority;
        task.recurrence = _recurrence;
        task.dueDate = _dueDate;
        if (_recurrence == Recurrence.monthly) {
          if (previousRecurrence != Recurrence.monthly ||
              previousDueDate != _dueDate ||
              task.recurrenceDayOfMonth == null) {
            task.recurrenceDayOfMonth = _dueDate?.day;
          }
        } else {
          task.recurrenceDayOfMonth = null;
        }
        task.subtasks = List.from(_subtasks);
        task.reminderEnabled = _reminder;
        notificationSyncSucceeded = await provider.updateTask(task);
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        if (!notificationSyncSucceeded) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Tugas tersimpan, tetapi pengingat gagal dijadwalkan. '
                'Periksa izin notifikasi.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        final message = error is PlatformException
            ? error.message ?? 'Periksa izin notifikasi di Pengaturan Android.'
            : 'Periksa judul tugas lalu coba lagi.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tugas gagal disimpan: $message')),
        );
      }
    }
  }
}

/// Ikon Material sesuai prioritas (dipakai SegmentedButton).
IconData priorityIcon(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return Icons.low_priority_rounded;
    case TaskPriority.medium:
      return Icons.remove_rounded;
    case TaskPriority.high:
      return Icons.keyboard_double_arrow_up_rounded;
  }
}

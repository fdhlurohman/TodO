// ============================================================
// MODEL: TUGAS (TASK)
// Entitas utama aplikasi. Disimpan di box Hive 'tasks'
// dengan key = task.id, value = Map hasil toMap().
// ============================================================
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/models/subtask.dart';
import 'package:premium_todo/models/task_priority.dart';

class Task {
  String id;
  String title;
  String notes; // catatan tambahan (boleh kosong)
  String? categoryIdRef; // id kategori yang dirujuk (null = tanpa kategori)
  List<SubTask> subtasks;
  TaskPriority priority;
  Recurrence recurrence;
  DateTime? dueDate; // deadline (nullable = tanpa deadline)
  DateTime createdAt;
  DateTime? completedAt; // diisi saat tugas ditandai selesai
  bool isPinned; // pin tugas penting agar selalu tampil di atas
  bool reminderEnabled;
  int? recurrenceDayOfMonth;

  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.categoryIdRef,
    this.subtasks = const [],
    this.priority = TaskPriority.medium,
    this.recurrence = Recurrence.none,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.isPinned = false,
    this.reminderEnabled = true,
    int? recurrenceDayOfMonth,
  }) : recurrenceDayOfMonth = recurrenceDayOfMonth ??
            (recurrence == Recurrence.monthly ? dueDate?.day : null);

  // ------------------------------------------------------------
  // STATUS & HELPER
  // ------------------------------------------------------------
  bool get isCompleted => completedAt != null;

  /// Progres sub-tugas 0.0 - 1.0 (1.0 jika tidak ada sub-tugas).
  double get subtaskProgress {
    if (subtasks.isEmpty) return 1.0;
    final done = subtasks.where((s) => s.isDone).length;
    return done / subtasks.length;
  }

  /// Apakah tugas ini sudah melewati deadline & belum selesai.
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// Tenggat berikutnya untuk tugas berulang setelah [from].
  DateTime? nextDueAfter(DateTime from) {
    recurrenceDayOfMonth ??= recurrence == Recurrence.monthly ? from.day : null;
    return recurrence.nextAfter(
      from,
      dayOfMonth: recurrenceDayOfMonth,
    );
  }

  // ------------------------------------------------------------
  // SERIALIZASI HIVE (Map <-> Task)
  // ------------------------------------------------------------
  factory Task.fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String? ?? '',
      categoryIdRef: map['categoryId'] as String?,
      subtasks: ((map['subtasks'] as List?) ?? [])
          .map((e) => SubTask.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList(),
      priority: TaskPriority.fromInt(map['priority'] as int? ?? 1),
      recurrence: Recurrence.fromString(map['recurrence'] as String? ?? 'none'),
      dueDate: map['dueDate'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int),
      isPinned: map['isPinned'] as bool? ?? false,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      recurrenceDayOfMonth: map['recurrenceDayOfMonth'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'categoryId': categoryIdRef,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'priority': priority.toInt,
        'recurrence': recurrence.toStore,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'isPinned': isPinned,
        'reminderEnabled': reminderEnabled,
        'recurrenceDayOfMonth': recurrenceDayOfMonth,
      };
}

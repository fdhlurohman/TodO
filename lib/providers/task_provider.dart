// ============================================================
// PROVIDER: TUGAS (LOGIKA UTAMA APLIKASI)
// Bertanggung jawab atas:
//  - CRUD tugas -> HiveRepository
//  - Filter: kategori, prioritas, status selesai
//  - Pencarian judul/catatan/sub-tugas
//  - Sorting: deadline / prioritas / dibuat / judul
//  - Siklus tugas berulang (saat selesai -> jadwal baru)
//  - Seed tugas contoh saat aplikasi pertama kali dijalankan
// ============================================================
import 'package:flutter/foundation.dart' hide Category;
import 'package:premium_todo/core/utils/id_generator.dart';
import 'package:premium_todo/data/task_repository.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/models/subtask.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/models/task_priority.dart';
import 'package:premium_todo/services/notification_service.dart';
import 'package:premium_todo/services/task_notification_manager.dart';

/// Mode pengurutan daftar tugas.
enum TaskSort { dueDate, priority, createdNewest, title }

/// Filter status tampilan.
enum StatusFilter { all, active, completed }

class TaskProvider extends ChangeNotifier {
  static const _supportedReminderIntervals = {5, 10, 15, 30, 60};

  final TaskRepository _repo;
  final TaskNotificationManager _notifications;
  TaskProvider(this._repo, {TaskNotificationManager? notifications})
    : _notifications = notifications ?? NotificationService.instance;

  /// Semua tugas (master list, tidak terfilter).
  List<Task> _tasks = [];
  bool _onboardingCompleted = false;
  bool _tutorialCompleted = false;
  bool get needsOnboarding => !_onboardingCompleted;
  bool get needsTutorial => !_tutorialCompleted;
  int get reminderMinutesBefore {
    final configured = _repo.getSetting<int>('reminderMinutesBefore');
    return _supportedReminderIntervals.contains(configured) ? configured! : 15;
  }

  // ---------------- STATE FILTER ----------------
  String searchQuery = '';
  String? filterCategoryId; // null = semua kategori
  TaskPriority? filterPriority; // null = semua prioritas
  StatusFilter statusFilter = StatusFilter.active;
  TaskSort sortMode = TaskSort.dueDate;

  /// Daftar tugas hasil filter + sorting (dipakai UI).
  List<Task> get filteredTasks {
    Iterable<Task> result = _tasks;

    // 1. Filter status
    result = switch (statusFilter) {
      StatusFilter.all => result,
      StatusFilter.active => result.where((t) => !t.isCompleted),
      StatusFilter.completed => result.where((t) => t.isCompleted),
    };

    // 2. Filter kategori
    if (filterCategoryId != null) {
      result = result.where((t) => t.categoryIdRef == filterCategoryId);
    }

    // 3. Filter prioritas
    if (filterPriority != null) {
      result = result.where((t) => t.priority == filterPriority);
    }

    // 4. Pencarian (judul, catatan, judul sub-tugas) - case-insensitive
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((t) {
        final inTitle = t.title.toLowerCase().contains(q);
        final inNotes = t.notes.toLowerCase().contains(q);
        final inSubs = t.subtasks.any((s) => s.title.toLowerCase().contains(q));
        return inTitle || inNotes || inSubs;
      });
    }

    // 5. Sorting (pinned selalu di atas)
    final list = result.toList();
    list.sort(_comparator);
    return list;
  }

  /// Pembanding sesuai mode sorting; pinned dianggap lebih kecil
  /// (tampil paling atas) di semua mode.
  int _comparator(Task a, Task b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    switch (sortMode) {
      case TaskSort.dueDate:
        // Tanpa deadline diletakkan paling akhir.
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      case TaskSort.priority:
        final cmp = b.priority.toInt.compareTo(a.priority.toInt);
        if (cmp != 0) return cmp;
        // Prioritas sama -> bandingkan deadline.
        return _comparatorByDue(a, b);
      case TaskSort.createdNewest:
        return b.createdAt.compareTo(a.createdAt);
      case TaskSort.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  }

  int _comparatorByDue(Task a, Task b) {
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  // ---------------- GETTER STATISTIK CEPAT ----------------
  int get totalCount => _tasks.length;
  int get activeCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  /// Tugas aktif yang jatuh tempo pada [day] (dipakai kalender).
  List<Task> tasksForDay(DateTime day) => _tasks.where((t) {
    final due = t.dueDate;
    if (due == null) return false;
    return due.year == day.year && due.month == day.month && due.day == day.day;
  }).toList();

  /// Semua tugas ber-deadline (dipakai untuk marker kalender).
  List<Task> getAllTasksForCalendar() =>
      _tasks.where((t) => t.dueDate != null).toList();

  /// Salinan semua tugas tanpa filter (dipakai analitik/statistik).
  List<Task> get allTasks => List.unmodifiable(_tasks);

  /// Tugas yang sedang di-link ke pomodoro (dipilih di layar timer).
  Task? pomodoroLinkedTask;

  void linkPomodoroTask(Task? task) {
    // Cegah link ke tugas yang sudah tidak ada di daftar.
    if (task != null && _findTaskOrNull(task.id) == null) task = null;
    pomodoroLinkedTask = task;
    notifyListeners();
  }

  /// Cari tugas by id tanpa melempar error (null jika tidak ada).
  Task? _findTaskOrNull(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Sinkronkan link pomodoro setelah daftar tugas dimuat ulang agar
  /// tidak menunjuk objek lama yang sudah basi/terhapus.
  void _refreshPomodoroLink() {
    final linked = pomodoroLinkedTask;
    if (linked == null) return;
    pomodoroLinkedTask = _findTaskOrNull(linked.id);
  }

  // ---------------- LOAD ----------------
  Future<void> load() async {
    _tasks = _repo.getAllTasks();
    _tutorialCompleted = _repo.getSetting<bool>('tutorialCompleted') ?? false;
    _onboardingCompleted =
        _repo.getSetting<bool>('onboardingCompleted') ??
        (_repo.getSetting<bool>('seeded') ?? false);
    _refreshPomodoroLink();
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    if (_tutorialCompleted) return;
    await _repo.setSetting('tutorialCompleted', true);
    _tutorialCompleted = true;
    notifyListeners();
  }

  Future<void> syncNotificationSchedules() async {
    await _notifications.syncTaskReminders(_tasks);
    await _notifications.refreshDailySummary(activeCount);
  }

  // ---------------- CRUD ----------------
  Future<bool> addTask(Task task) async {
    await _repo.saveTask(task);
    _tasks.add(task);
    notifyListeners();
    return _syncTaskNotifications(task);
  }

  Future<bool> updateTask(Task task) async {
    await _repo.saveTask(task);
    _tasks = _repo.getAllTasks(); // reload agar konsisten
    _refreshPomodoroLink();
    notifyListeners();
    return _syncTaskNotifications(task);
  }

  Future<bool> deleteTask(String id) async {
    await _repo.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    if (pomodoroLinkedTask?.id == id) pomodoroLinkedTask = null;
    notifyListeners();
    try {
      await _notifications.cancelTaskReminder(id);
      await _notifications.refreshDailySummary(activeCount);
      return true;
    } catch (error, stackTrace) {
      _reportNotificationError('Menghapus pengingat tugas', error, stackTrace);
      return false;
    }
  }

  /// Toggle selesai/belum. Untuk tugas berulang yang selesai:
  /// deadline digeser ke siklus berikutnya dan status aktif kembali.
  Future<bool> toggleComplete(String id) async {
    final task = _findTaskOrNull(id);
    if (task == null) return false; // tugas sudah terhapus di tempat lain
    if (!task.isCompleted) {
      // ---- Menandai SELESAI ----
      if (task.recurrence != Recurrence.none && task.dueDate != null) {
        // Tugas berulang: geser deadline ke siklus berikutnya.
        task.dueDate = task.nextDueAfter(task.dueDate!);
        task.completedAt = null;
      } else {
        task.completedAt = DateTime.now();
      }
    } else {
      // ---- Membatalkan status selesai ----
      task.completedAt = null;
    }
    await _repo.saveTask(task);
    _tasks = _repo.getAllTasks();
    _refreshPomodoroLink();
    notifyListeners();
    return _syncTaskNotifications(task);
  }

  Future<bool> _syncTaskNotifications(Task task) async {
    try {
      if (task.reminderEnabled &&
          _notifications.taskRemindersEnabled &&
          !task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.isAfter(DateTime.now())) {
        await _notifications.requestNotificationPermission();
      }
      await _notifications.syncTaskReminder(task);
      await _notifications.refreshDailySummary(activeCount);
      return true;
    } catch (error, stackTrace) {
      _reportNotificationError(
        'Menyinkronkan notifikasi tugas',
        error,
        stackTrace,
      );
      return false;
    }
  }

  void _reportNotificationError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('$operation gagal: $error\n$stackTrace');
  }

  /// Toggle pin tugas.
  Future<void> togglePin(String id) async {
    final task = _findTaskOrNull(id);
    if (task == null) return;
    task.isPinned = !task.isPinned;
    await _repo.saveTask(task);
    notifyListeners();
  }

  /// Perbarui satu sub-tugas dalam tugas.
  Future<void> updateSubtask(String taskId, SubTask subtask) async {
    final task = _findTaskOrNull(taskId);
    if (task == null) return;
    final idx = task.subtasks.indexWhere((s) => s.id == subtask.id);
    if (idx == -1) {
      task.subtasks.add(subtask);
    } else {
      task.subtasks[idx] = subtask;
    }
    await _repo.saveTask(task);
    notifyListeners();
  }

  /// Hapus satu sub-tugas.
  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final task = _findTaskOrNull(taskId);
    if (task == null) return;
    task.subtasks.removeWhere((s) => s.id == subtaskId);
    await _repo.saveTask(task);
    notifyListeners();
  }

  /// Ubah filter kategori (null = semua).
  void setCategoryFilter(String? categoryId) {
    filterCategoryId = categoryId;
    notifyListeners();
  }

  // ---------------- PENGATURAN FILTER/SORT ----------------
  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? p) {
    filterPriority = p;
    notifyListeners();
  }

  void setStatusFilter(StatusFilter s) {
    statusFilter = s;
    notifyListeners();
  }

  void setSortMode(TaskSort s) {
    sortMode = s;
    notifyListeners();
  }

  /// Reset semua filter ke kondisi awal.
  void resetFilters() {
    searchQuery = '';
    filterCategoryId = null;
    filterPriority = null;
    statusFilter = StatusFilter.active;
    sortMode = TaskSort.dueDate;
    notifyListeners();
  }

  // ---------------- SEED DATA CONTOH ----------------
  /// Simpan pilihan onboarding dan, bila dipilih, buat tugas contoh.
  Future<void> completeOnboarding({
    required List<Category> categories,
    required bool includeSampleTasks,
  }) async {
    if (_onboardingCompleted) return;
    if (includeSampleTasks) {
      await _seedSampleTasks(categories);
    }
    await _repo.setSetting('seeded', includeSampleTasks);
    await _repo.setSetting('onboardingCompleted', true);
    _onboardingCompleted = true;
    notifyListeners();
  }

  Future<void> _seedSampleTasks(List<Category> categories) async {
    final now = DateTime.now();
    String? categoryId(String name) {
      for (final category in categories) {
        if (category.name.toLowerCase() == name.toLowerCase()) {
          return category.id;
        }
      }
      return null;
    }

    final samples = <Task>[
      Task(
        id: genId(),
        title: 'Rapat sprint mingguan',
        notes: 'Siapkan laporan progres tim dan blocker minggu ini.',
        categoryIdRef: categoryId('Pekerjaan'),
        priority: TaskPriority.high,
        recurrence: Recurrence.weekly,
        dueDate: DateTime(now.year, now.month, now.day, 10, 0),
        createdAt: now,
        subtasks: [
          SubTask.create('Kumpulkan update tiap anggota'),
          SubTask.create('Susun agenda rapat'),
        ],
      ),
      Task(
        id: genId(),
        title: 'Belanja bahan makanan',
        categoryIdRef: categoryId('Belanja'),
        priority: TaskPriority.medium,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now,
        subtasks: [
          SubTask.create('Beras 5 kg'),
          SubTask.create('Sayuran segar'),
          SubTask.create('Buah-buahan'),
        ],
      ),
      Task(
        id: genId(),
        title: 'Olahraga 30 menit',
        notes: 'Jogging ringan atau workout di rumah.',
        categoryIdRef: categoryId('Kesehatan'),
        priority: TaskPriority.low,
        recurrence: Recurrence.daily,
        dueDate: DateTime(now.year, now.month, now.day, 18, 0),
        createdAt: now,
      ),
      Task(
        id: genId(),
        title: 'Baca 20 halaman buku',
        categoryIdRef: categoryId('Pribadi'),
        priority: TaskPriority.low,
        recurrence: Recurrence.daily,
        dueDate: DateTime(now.year, now.month, now.day, 21, 30),
        createdAt: now,
      ),
      Task(
        id: genId(),
        title: 'Bayar tagihan listrik',
        categoryIdRef: categoryId('Pribadi'),
        priority: TaskPriority.high,
        dueDate: now.add(const Duration(days: 3)),
        createdAt: now,
        isPinned: true,
      ),
    ];

    for (final t in samples) {
      await _repo.saveTask(t);
    }
    _tasks = _repo.getAllTasks();
    _refreshPomodoroLink();
    try {
      await _notifications.syncTaskReminders(_tasks);
      await _notifications.refreshDailySummary(activeCount);
    } catch (error, stackTrace) {
      _reportNotificationError(
        'Menjadwalkan notifikasi tugas contoh',
        error,
        stackTrace,
      );
    }
    notifyListeners();
  }
}

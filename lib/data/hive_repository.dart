// ============================================================
// REPOSITORY: PENYIMPANAN HIVE
// Satu-satunya tempat yang menyentuh database Hive.
// Box yang dipakai:
//   'tasks'    -> key: task.id      value: Task.toMap()
//   'categories'-> key: category.id value: Category.toMap()
//   'settings' -> key: string       value: dynamic (tema, dll)
// ============================================================
import 'package:hive_flutter/hive_flutter.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/data/task_repository.dart';

class HiveRepository implements TaskRepository {
  HiveRepository._();
  static final HiveRepository instance = HiveRepository._();

  late final Box tasksBox;
  late final Box categoriesBox;
  late final Box settingsBox;

  /// Inisialisasi Hive + buka semua box. Dipanggil sekali di main().
  Future<void> init() async {
    await Hive.initFlutter();
    tasksBox = await Hive.openBox('tasks');
    categoriesBox = await Hive.openBox('categories');
    settingsBox = await Hive.openBox('settings');
  }

  // ================= TUGAS =================

  /// Ambil semua tugas.
  @override
  List<Task> getAllTasks() => tasksBox.values
      .map((m) => Task.fromMap(Map<dynamic, dynamic>.from(m)))
      .toList();

  /// Simpan (insert atau update) satu tugas.
  @override
  Future<void> saveTask(Task task) => tasksBox.put(task.id, task.toMap());

  /// Hapus satu tugas.
  @override
  Future<void> deleteTask(String id) => tasksBox.delete(id);

  // ================= KATEGORI =================

  List<Category> getAllCategories() => categoriesBox.values
      .map((m) => Category.fromMap(Map<dynamic, dynamic>.from(m)))
      .toList();

  Future<void> saveCategory(Category c) => categoriesBox.put(c.id, c.toMap());

  Future<void> deleteCategory(String id) => categoriesBox.delete(id);

  Map<String, dynamic> createBackupData() => {
    'format': 'TodO backup',
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'tasks': tasksBox.values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(),
    'categories': categoriesBox.values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(),
    'settings': {
      for (final key in settingsBox.keys)
        if (key is String &&
            key != 'notificationSoundUri' &&
            key != 'notificationSoundName')
          key:
              key == 'notificationSoundMode' && settingsBox.get(key) == 'device'
              ? 'builtIn'
              : settingsBox.get(key),
    },
  };

  Future<void> restoreBackup({
    required List<Task> tasks,
    required List<Category> categories,
    required Map<String, dynamic> settings,
    required bool replaceExisting,
  }) async {
    final previousTasks = tasksBox.toMap();
    final previousCategories = categoriesBox.toMap();
    final previousSettings = settingsBox.toMap();

    Future<void> writeBackup({required bool replace}) async {
      if (replace) {
        await tasksBox.clear();
        await categoriesBox.clear();
        await settingsBox.clear();
      }
      await tasksBox.putAll({for (final task in tasks) task.id: task.toMap()});
      await categoriesBox.putAll({
        for (final category in categories) category.id: category.toMap(),
      });
      await settingsBox.putAll(settings);
    }

    try {
      await writeBackup(replace: replaceExisting);
    } catch (error, stackTrace) {
      try {
        await tasksBox.clear();
        await categoriesBox.clear();
        await settingsBox.clear();
        await tasksBox.putAll(previousTasks);
        await categoriesBox.putAll(previousCategories);
        await settingsBox.putAll(previousSettings);
      } catch (rollbackError) {
        Error.throwWithStackTrace(
          StateError(
            'Pemulihan backup gagal ($error) dan data sebelumnya gagal '
            'dipulihkan ($rollbackError).',
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // ================= PENGATURAN =================

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    final v = settingsBox.get(key);
    return (v is T) ? v : defaultValue;
  }

  @override
  Future<void> setSetting(String key, dynamic value) =>
      settingsBox.put(key, value);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/data/hive_repository.dart';
import 'package:premium_todo/data/task_repository.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/category_presets.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/pomodoro_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/providers/theme_provider.dart';
import 'package:premium_todo/screens/first_run_screen.dart';
import 'package:premium_todo/screens/home_shell.dart';
import 'package:premium_todo/screens/task_form_screen.dart';
import 'package:premium_todo/services/notification_service.dart';
import 'package:premium_todo/services/task_notification_manager.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestCategoryProvider categories;
  late TestTaskProvider tasks;

  setUp(() {
    categories = TestCategoryProvider();
    tasks = TestTaskProvider();
  });

  Widget buildApp({Task? existing}) => MultiProvider(
    providers: [
      ChangeNotifierProvider<CategoryProvider>.value(value: categories),
      ChangeNotifierProvider<TaskProvider>.value(value: tasks),
      ChangeNotifierProvider<ThemeProvider>.value(value: TestThemeProvider()),
      ChangeNotifierProvider<PomodoroProvider>.value(
        value: PomodoroProvider(NotificationService.instance),
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TaskFormScreen(existing: existing),
              ),
            ),
            child: const Text('Buka form'),
          ),
        ),
      ),
    ),
  );

  testWidgets('wizard validates title, supports back, then saves task', (
    tester,
  ) async {
    tasks.reminderInterval = 30;
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Buka form'));
    await tester.pumpAndSettle();

    expect(find.text('Tahap 1 dari 4'), findsOneWidget);
    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Judul wajib diisi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Tugas baru');
    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Tahap 2 dari 4'), findsOneWidget);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Tahap 3 dari 4'), findsOneWidget);
    expect(
      find.text('Notifikasi 30 menit sebelum deadline (diatur di Pengaturan)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Tahap 2 dari 4'), findsOneWidget);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Tahap 4 dari 4'), findsOneWidget);

    await tester.tap(find.text('Simpan Tugas'));
    await tester.pumpAndSettle();

    expect(tasks.createdTask?.title, 'Tugas baru');
    expect(find.text('Buka form'), findsOneWidget);
  });

  testWidgets('edit form remains a single page with existing task fields', (
    tester,
  ) async {
    tasks.reminderInterval = 60;
    final existing = Task(
      id: 'existing-task',
      title: 'Tugas lama',
      createdAt: DateTime(2026),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(existing: existing));
    await tester.tap(find.text('Buka form'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Tugas'), findsOneWidget);
    expect(find.text('Tahap 1 dari 4'), findsNothing);
    expect(find.text('Prioritas'), findsOneWidget);
    expect(find.text('Deadline'), findsOneWidget);
    expect(find.text('Perbarui Tugas'), findsOneWidget);
    expect(
      find.text('Notifikasi 60 menit sebelum deadline (diatur di Pengaturan)'),
      findsOneWidget,
    );
  });

  testWidgets('first launch shows tutorial before the start choice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tasks.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoryProvider>.value(value: categories),
          ChangeNotifierProvider<TaskProvider>.value(value: tasks),
          ChangeNotifierProvider<ThemeProvider>.value(
            value: TestThemeProvider(),
          ),
          ChangeNotifierProvider<PomodoroProvider>.value(
            value: PomodoroProvider(NotificationService.instance),
          ),
        ],
        child: const MaterialApp(home: FirstRunScreen()),
      ),
    );

    expect(find.text('Panduan TodO'), findsOneWidget);
    expect(find.text('Semua tugas, lebih teratur'), findsOneWidget);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Buat tugas dengan mudah'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Coba dengan tugas contoh'), findsOneWidget);
    expect(tasks.needsTutorial, isFalse);

    await tester.tap(find.text('Mulai dengan daftar kosong'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(tasks.allTasks, isEmpty);
  });
}

class TestCategoryProvider extends CategoryProvider {
  TestCategoryProvider() : super(HiveRepository.instance);

  @override
  List<Category> get categories => defaultCategories();

  @override
  Category? byId(String? id) =>
      id == null ? null : categories.where((item) => item.id == id).firstOrNull;
}

class TestThemeProvider extends ThemeProvider {
  TestThemeProvider() : super(HiveRepository.instance);

  @override
  bool get isDark => false;
}

class TestTaskProvider extends TaskProvider {
  TestTaskProvider()
    : super(
        InMemoryTaskRepository(),
        notifications: NoopTaskNotificationManager(),
      );

  int reminderInterval = 15;
  Task? createdTask;

  @override
  int get reminderMinutesBefore => reminderInterval;

  @override
  Future<bool> addTask(Task task) async {
    createdTask = task;
    return true;
  }

  @override
  Future<bool> updateTask(Task task) async => true;
}

class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Map<String, dynamic>> _tasks = {};
  final Map<String, dynamic> _settings = {};

  @override
  List<Task> getAllTasks() =>
      _tasks.values.map((map) => Task.fromMap(map)).toList();

  @override
  Future<void> saveTask(Task task) async => _tasks[task.id] = task.toMap();

  @override
  Future<void> deleteTask(String id) async => _tasks.remove(id);

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _settings[key];
    return value is T ? value : defaultValue;
  }

  @override
  Future<void> setSetting(String key, dynamic value) async {
    _settings[key] = value;
  }
}

class NoopTaskNotificationManager implements TaskNotificationManager {
  @override
  int get reminderMinutesBefore => 15;

  @override
  bool get taskRemindersEnabled => true;

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {}

  @override
  Future<void> refreshDailySummary(int activeCount) async {}

  @override
  Future<void> syncTaskReminder(Task task) async {}

  @override
  Future<void> syncTaskReminders(List<Task> tasks) async {}
}

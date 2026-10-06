// ============================================================
// WIDGET TEST: LAYAR POMODORO
// Menguji:
//  - Fase awal Fokus 25:00 + progress ring
//  - Mulai -> timer berjalan, Jeda -> timer berhenti
//  - Reset -> kembali ke durasi penuh
//  - Lewati fase -> pindah ke Istirahat
//  - Pemilih durasi fokus cepat (15/25/50 menit)
//  - Dropdown tugas terhubung: pilih & lepas tugas
//  - Tugas ter-link tetap ada di dropdown walau terfilter
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/data/task_repository.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/pomodoro_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/screens/pomodoro_screen.dart';
import 'package:premium_todo/services/notification_service.dart';
import 'package:premium_todo/services/task_notification_manager.dart';
import 'package:provider/provider.dart';

void main() {
  late FakeTaskRepository repository;
  late NoopTaskNotifications notifications;
  late TaskProvider tasks;
  late PomodoroProvider pomodoro;

  setUp(() {
    repository = FakeTaskRepository();
    notifications = NoopTaskNotifications();
    tasks = TaskProvider(repository, notifications: notifications);
    // NotificationService.instance aman di test: showInstantNotification
    // hanya melempar StateError yang sudah ditangani PomodoroProvider.
    pomodoro = PomodoroProvider(NotificationService.instance);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>.value(value: tasks),
          ChangeNotifierProvider<PomodoroProvider>.value(value: pomodoro),
        ],
        child: const MaterialApp(home: PomodoroScreen()),
      ),
    );
    await tester.pump();
  }

  Task newTask(String id, String title) => Task(
        id: id,
        title: title,
        createdAt: DateTime(2026, 10, 1),
      );

  testWidgets('menampilkan fase fokus awal 25:00 dengan progress nol',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Fokus'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('1500 detik tersisa'), findsOneWidget);

    // Progress ring masih 0 -> tidak ada error layout.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(pomodoro.progress, 0.0);
  });

  testWidgets('mulai lalu jeda mengubah label dan state timer',
      (tester) async {
    await pumpScreen(tester);

    // ---- Mulai ----
    await tester.tap(find.text('Mulai'));
    await tester.pump();
    expect(pomodoro.isRunning, isTrue);
    expect(find.text('Jeda'), findsOneWidget);

    // ---- Jeda ----
    await tester.tap(find.text('Jeda'));
    await tester.pump();
    expect(pomodoro.isRunning, isFalse);
    expect(find.text('Mulai'), findsOneWidget);
  });

  testWidgets('reset mengembalikan sisa waktu ke durasi penuh',
      (tester) async {
    await pumpScreen(tester);

    // Jalankan 3 detik (fake async memicu Timer.periodic).
    pomodoro.start();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(pomodoro.remainingSeconds, lessThan(25 * 60));

    // Reset -> 25:00 lagi, timer berhenti.
    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pump();

    expect(pomodoro.isRunning, isFalse);
    expect(pomodoro.remainingSeconds, 25 * 60);
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('lewati fase fokus berpindah ke istirahat', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pump();

    expect(pomodoro.phase, PomodoroPhase.shortBreak);
    expect(find.text('Istirahat'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    // Sesi fokus yang di-skip tidak dihitung selesai.
    expect(pomodoro.completedFocusSessions, 0);
  });

  testWidgets('pemilih durasi mengubah durasi fokus saat idle',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('50 mnt'));
    await tester.pump();

    expect(pomodoro.focusMinutes, 50);
    expect(pomodoro.remainingSeconds, 50 * 60);
    expect(find.text('50:00'), findsOneWidget);
  });

  testWidgets('dropdown memuat tugas aktif dan bisa memilih serta melepas',
      (tester) async {
    // Layar pomodoro tinggi; perbesar permukaan agar dropdown terlihat.
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final t1 = newTask('p-1', 'Tulis dokumentasi');
    final t2 = newTask('p-2', 'Review kode');
    await tasks.addTask(t1);
    await tasks.addTask(t2);
    // Tugas selesai tidak boleh muncul di dropdown.
    final done = newTask('p-3', 'Tugas lama selesai')
      ..completedAt = DateTime.now();
    await tasks.addTask(done);

    await pumpScreen(tester);

    // Buka dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<Task?>));
    await tester.pumpAndSettle();

    expect(find.text('Tulis dokumentasi').last, findsOneWidget);
    expect(find.text('Review kode').last, findsOneWidget);
    expect(find.text('Tugas lama selesai'), findsNothing);

    // Pilih tugas pertama.
    await tester.tap(find.text('Tulis dokumentasi').last);
    await tester.pumpAndSettle();

    expect(tasks.pomodoroLinkedTask?.id, 'p-1');

    // ---- Lepas tugas (seperti tombol close di banner Beranda) ----
    tasks.linkPomodoroTask(null);
    await tester.pumpAndSettle();
    expect(tasks.pomodoroLinkedTask, isNull);
  });

  testWidgets(
    'tugas ter-link tetap ada di dropdown walau tak memenuhi filter',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = newTask('p-link', 'Tugas tersembunyi filter');
      await tasks.addTask(linked);
      tasks.linkPomodoroTask(linked);

      // Set filter agar tugas itu tidak masuk daftar aktif terfilter.
      tasks.setSearch('xyz-tidak-ada');

      await pumpScreen(tester);

      // Regresi: sebelum perbaikan, nilai dropdown yang tidak ada di
      // daftar items memicu assertion error saat layar dibangun.
      expect(tester.takeException(), isNull);
      expect(tasks.pomodoroLinkedTask?.id, 'p-link');
      // Nilai tersimpan ditampilkan sebagai item dropdown terpilih.
      expect(find.text('Tugas tersembunyi filter'), findsOneWidget);
    },
  );
}

// ============================================================
// FAKE SEDERHANA (tanpa Hive & tanpa notifikasi nyata)
// ============================================================
class FakeTaskRepository implements TaskRepository {
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

class NoopTaskNotifications implements TaskNotificationManager {
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

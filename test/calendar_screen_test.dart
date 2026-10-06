// ============================================================
// WIDGET TEST: LAYAR KALENDER
// Menguji:
//  - Header bulan & label hari bahasa Indonesia
//  - Daftar "Tugas hari ini" (tugas selesai disembunyikan)
//  - Pilih tanggal -> judul & daftar tugas mengikuti tanggal itu
//  - Tugas selesai pada hari terpilih tetap tampil
//  - Empty state saat tidak ada tugas
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/core/utils/date_utils.dart';
import 'package:premium_todo/data/hive_repository.dart';
import 'package:premium_todo/data/task_repository.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/screens/calendar_screen.dart';
import 'package:premium_todo/services/task_notification_manager.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

void main() {
  late FakeTaskRepository repository;
  late NoopTaskNotifications notifications;
  late TaskProvider tasks;

  setUp(() {
    repository = FakeTaskRepository();
    notifications = NoopTaskNotifications();
    tasks = TaskProvider(repository, notifications: notifications);
  });

  DateTime todayAt(int hour) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour);
  }

  DateTime tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>.value(value: tasks),
          ChangeNotifierProvider<CategoryProvider>.value(
            value: CategoryProvider(HiveRepository.instance),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pilih tanggal langsung lewat callback TableCalendar agar
  /// deterministik (tidak bergantung posisi sel di layar).
  Future<void> selectDay(WidgetTester tester, DateTime day) async {
    final calendar = tester.widget<TableCalendar<Task>>(
      find.byType(TableCalendar<Task>),
    );
    calendar.onDaySelected!(day, day);
    await tester.pumpAndSettle();
  }

  Task newTask(
    String id,
    String title, {
    required DateTime dueDate,
    DateTime? completedAt,
  }) =>
      Task(
        id: id,
        title: title,
        createdAt: DateTime(2026, 10, 1),
        dueDate: dueDate,
        completedAt: completedAt,
      );

  testWidgets(
    'header kalender memakai bulan dan hari bahasa Indonesia',
    (tester) async {
      await pumpScreen(tester);

      // Label hari (Sen..Min) muncul 7 kali.
      expect(find.text('Sen'), findsOneWidget);
      expect(find.text('Sel'), findsOneWidget);
      expect(find.text('Rab'), findsOneWidget);
      expect(find.text('Kam'), findsOneWidget);
      expect(find.text('Jum'), findsOneWidget);
      expect(find.text('Sab'), findsOneWidget);
      expect(find.text('Min'), findsOneWidget);

      // Judul header = nama bulan Indonesia + tahun berjalan.
      final now = DateTime.now();
      expect(
        find.text('${_monthNames[now.month - 1]} ${now.year}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'menampilkan tugas hari ini dan menyembunyikan yang sudah selesai',
    (tester) async {
      await tasks.addTask(newTask('t-aktif', 'Rapat tim',
          dueDate: todayAt(10)));
      await tasks.addTask(
        newTask(
          't-selesai',
          'Belanja mingguan',
          dueDate: todayAt(12),
          completedAt: DateTime.now(),
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Tugas hari ini'), findsOneWidget);
      expect(find.text('Rapat tim'), findsOneWidget);
      // Tugas selesai tidak tampil saat tidak ada tanggal terpilih.
      expect(find.text('Belanja mingguan'), findsNothing);
    },
  );

  testWidgets(
    'memilih tanggal menampilkan daftar tugas tanggal tersebut',
    (tester) async {
      final tomorrowDate = tomorrow();
      await tasks.addTask(newTask('t-hari-ini', 'Rapat tim',
          dueDate: todayAt(10)));
      await tasks.addTask(newTask('t-besok', 'Kirim laporan',
          dueDate: tomorrowDate));

      await pumpScreen(tester);

      // ---- Pilih besok ----
      await selectDay(tester, tomorrowDate);

      expect(
        find.text('Tugas ${AppDateUtils.formatDate(tomorrowDate)}'),
        findsOneWidget,
      );
      expect(find.text('Kirim laporan'), findsOneWidget);
      expect(find.text('Rapat tim'), findsNothing);

      // ---- Pilih hari ini: tugas selesai hari ini ikut tampil ----
      await tasks.addTask(
        newTask(
          't-selesai-hari-ini',
          'Belanja mingguan',
          dueDate: todayAt(12),
          completedAt: DateTime.now(),
        ),
      );
      // addTask memicu rebuild; tunggu frame selesai.
      await tester.pumpAndSettle();

      final today = todayAt(0);
      await selectDay(tester, today);

      expect(
        find.text('Tugas ${AppDateUtils.formatDate(today)}'),
        findsOneWidget,
      );
      expect(find.text('Rapat tim'), findsOneWidget);
      // Tugas yang selesai PADA hari terpilih tetap ditampilkan.
      expect(find.text('Belanja mingguan'), findsOneWidget);
      expect(find.text('Kirim laporan'), findsNothing);
    },
  );

  testWidgets(
    'menampilkan empty state saat tanggal terpilih tanpa tugas',
    (tester) async {
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      await tasks.addTask(newTask('t-1', 'Rapat tim', dueDate: todayAt(10)));

      await pumpScreen(tester);
      await selectDay(tester, nextWeek);

      expect(
        find.text('Tugas ${AppDateUtils.formatDate(nextWeek)}'),
        findsOneWidget,
      );
      expect(find.text('Tidak ada tugas pada tanggal ini'), findsOneWidget);
      expect(find.text('0 tugas'), findsOneWidget);
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
  Future<void> saveTask(Task task) async =>
      _tasks[task.id] = task.toMap();

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

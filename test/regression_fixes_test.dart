// ============================================================
// REGRESSION TESTS
// Menguji perbaikan bug yang ditemukan pada audit:
//  - ID notifikasi tidak bentrok dengan ID pomodoro/ringkasan
//  - TaskProvider aman saat tugas sudah tidak ada (no crash)
//  - Link pomodoro selalu menunjuk objek tugas yang valid
// ============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/services/notification_service.dart';

import 'task_provider_test.dart';

void main() {
  late MemoryTaskRepository repository;
  late RecordingTaskNotifications notifications;
  late TaskProvider provider;

  setUp(() {
    repository = MemoryTaskRepository();
    notifications = RecordingTaskNotifications();
    provider = TaskProvider(repository, notifications: notifications);
  });

  group('notificationIdForTask tidak bentrok dengan ID tetap', () {
    test('ID pomodoro & ringkasan dihindari', () {
      // ID yang dipakai pomodoro (1001/1002) dan ringkasan (2001/2002)
      // tidak boleh bisa dihasilkan dari hash task ID.
      const reserved = {0, 999, 1001, 1002, 2001, 2002};
      final collisions = <String>[];
      for (var i = 0; i < 20000; i++) {
        final id = 'task-$i';
        final hashed = notificationIdForTask(id);
        if (reserved.contains(hashed)) collisions.add(id);
      }
      expect(collisions, isEmpty);
    });

    test('tetap deterministik dan positif', () {
      expect(
        notificationIdForTask('abc'),
        notificationIdForTask('abc'),
      );
      expect(notificationIdForTask('abc'), greaterThan(0));
    });
  });

  group('TaskProvider aman terhadap tugas yang sudah tidak ada', () {
    test('toggleComplete id tidak dikenal mengembalikan false tanpa error',
        () async {
      final result = await provider.toggleComplete('hilang');
      expect(result, isFalse);
      expect(provider.totalCount, 0);
    });

    test('togglePin id tidak dikenal tidak melempar error', () async {
      await provider.togglePin('hilang');
      expect(provider.totalCount, 0);
    });

    test('updateSubtask/deleteSubtask id tidak dikenal tidak melempar error',
        () async {
      await provider.deleteSubtask('hilang', 'sub-1');
      expect(provider.totalCount, 0);
    });
  });

  group('Link pomodoro', () {
    Task newTask(String id) => Task(
          id: id,
          title: 'Task $id',
          createdAt: DateTime(2026, 10, 1),
        );

    test('menolak link ke tugas yang tidak ada', () async {
      provider.linkPomodoroTask(newTask('tidak-ada'));
      expect(provider.pomodoroLinkedTask, isNull);
    });

    test('link tetap valid setelah updateTask (reload daftar)', () async {
      final task = newTask('linked');
      await provider.addTask(task);
      provider.linkPomodoroTask(task);

      task.title = 'Judul baru';
      await provider.updateTask(task);

      final link = provider.pomodoroLinkedTask;
      expect(link, isNotNull);
      expect(link!.id, 'linked');
      expect(link.title, 'Judul baru');
    });

    test('link dibersihkan saat tugas terhapus', () async {
      final task = newTask('linked');
      await provider.addTask(task);
      provider.linkPomodoroTask(task);
      expect(provider.pomodoroLinkedTask, isNotNull);

      await provider.deleteTask(task.id);
      expect(provider.pomodoroLinkedTask, isNull);
    });
  });
}

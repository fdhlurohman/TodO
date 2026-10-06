// ============================================================
// UNIT TEST: MODEL TESTING
// Menguji fungsionalitas model Task, SubTask, Category, dan Recurrence.
// ============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/models/subtask.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/models/task_priority.dart';

void main() {
  group('Model Task & SubTask', () {
    test('SubTask dapat dibuat dan ditandai selesai', () {
      final sub = SubTask.create('Beli susu');
      expect(sub.title, 'Beli susu');
      expect(sub.isDone, false);

      sub.isDone = true;
      expect(sub.isDone, true);
    });

    test('Perhitungan subtaskProgress pada Task akurat', () {
      final task = Task(
        id: 't1',
        title: 'Tugas Belajar',
        createdAt: DateTime.now(),
        subtasks: [
          SubTask(id: 's1', title: 'Bab 1', isDone: true),
          SubTask(id: 's2', title: 'Bab 2', isDone: false),
        ],
      );

      expect(task.subtaskProgress, 0.5);
      expect(task.isCompleted, false);

      task.completedAt = DateTime.now();
      expect(task.isCompleted, true);
    });

    test('Serialization toMap dan fromMap Task mempertahankan data', () {
      final now = DateTime.now();
      final task = Task(
        id: '123',
        title: 'Meeting Proyek TodO',
        notes: 'Catatan penting',
        priority: TaskPriority.high,
        recurrence: Recurrence.daily,
        createdAt: now,
        isPinned: true,
      );

      final map = task.toMap();
      final restored = Task.fromMap(map);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.notes, task.notes);
      expect(restored.priority, TaskPriority.high);
      expect(restored.recurrence, Recurrence.daily);
      expect(restored.isPinned, true);
    });

    test('Preferensi pengingat tersimpan dan data lama tetap diaktifkan', () {
      final task = Task(
        id: 'reminder-task',
        title: 'Task dengan pengingat mati',
        createdAt: DateTime(2026, 9, 30),
        reminderEnabled: false,
      );

      expect(Task.fromMap(task.toMap()).reminderEnabled, isFalse);

      final legacyMap = task.toMap()..remove('reminderEnabled');
      expect(Task.fromMap(legacyMap).reminderEnabled, isTrue);
    });

    test('Tanggal recurrence bulanan tetap tersimpan saat melewati Februari',
        () {
      final task = Task(
        id: 'monthly-task',
        title: 'Tagihan bulanan',
        recurrence: Recurrence.monthly,
        dueDate: DateTime(2026, 1, 31, 10),
        createdAt: DateTime(2026, 1, 1),
      );

      task.dueDate = task.nextDueAfter(task.dueDate!);
      expect(task.dueDate, DateTime(2026, 2, 28, 10));

      final restored = Task.fromMap(task.toMap());
      expect(restored.recurrenceDayOfMonth, 31);
      restored.dueDate = restored.nextDueAfter(restored.dueDate!);
      expect(restored.dueDate, DateTime(2026, 3, 31, 10));
    });

    test('Recurrence bulanan mendukung Februari di tahun kabisat', () {
      final task = Task(
        id: 'leap-monthly-task',
        title: 'Tugas bulanan',
        recurrence: Recurrence.monthly,
        dueDate: DateTime(2028, 1, 31, 10),
        createdAt: DateTime(2028, 1, 1),
      );

      expect(
        task.nextDueAfter(task.dueDate!),
        DateTime(2028, 2, 29, 10),
      );
    });

    test('Data recurrence lama tanpa anchor memakai tanggal deadline', () {
      final task = Task(
        id: 'legacy-monthly-task',
        title: 'Tugas bulanan lama',
        recurrence: Recurrence.monthly,
        dueDate: DateTime(2026, 5, 15, 10),
        createdAt: DateTime(2026, 5, 1),
      );
      final legacyMap = task.toMap()..remove('recurrenceDayOfMonth');

      final restored = Task.fromMap(legacyMap);

      expect(restored.recurrenceDayOfMonth, 15);
      expect(
        restored.nextDueAfter(restored.dueDate!),
        DateTime(2026, 6, 15, 10),
      );
    });
  });

  group('Model Category', () {
    test('Serialization Category toMap dan fromMap bekerja dengan tepat', () {
      final cat = Category(
        id: 'cat-1',
        name: 'Kerja',
        colorValue: 0xFF4F46E5,
        iconName: 'work',
      );

      final map = cat.toMap();
      final restored = Category.fromMap(map);

      expect(restored.id, cat.id);
      expect(restored.name, cat.name);
      expect(restored.colorValue, cat.colorValue);
      expect(restored.iconName, cat.iconName);
    });
  });

  group('Recurrence Next Due Date', () {
    test('Recurrence daily menambah 1 hari', () {
      final base = DateTime(2026, 9, 30, 10, 0);
      final next = Recurrence.daily.nextAfter(base);

      expect(next?.year, 2026);
      expect(next?.month, 10);
      expect(next?.day, 1);
      expect(next?.hour, 10);
    });
  });
}

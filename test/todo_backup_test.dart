import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/data/todo_backup.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/models/task.dart';

void main() {
  test('backup JSON preserves tasks, categories, and settings', () {
    final task = Task(
      id: 'backup-task',
      title: 'Review backup',
      recurrence: Recurrence.monthly,
      dueDate: DateTime(2026, 1, 31, 10),
      createdAt: DateTime(2026, 1, 1),
    );
    final category = Category(
      id: 'backup-category',
      name: 'Personal',
      colorValue: 0xFF10B981,
      iconName: 'person',
    );
    final encoded = TodoBackup.encode({
      'format': 'TodO backup',
      'schemaVersion': TodoBackup.currentVersion,
      'exportedAt': DateTime(2026, 1, 1).toIso8601String(),
      'tasks': [task.toMap()],
      'categories': [category.toMap()],
      'settings': {'isDarkMode': true},
    });

    final backup = TodoBackup.decode(encoded);

    expect(backup.tasks.single.toMap(), task.toMap());
    expect(backup.categories.single.toMap(), category.toMap());
    expect(backup.settings, {'isDarkMode': true});
  });

  test('backup rejects unsupported schema versions', () {
    expect(
      () => TodoBackup.decode(
        '{"format":"TodO backup","schemaVersion":99,"tasks":[],"categories":[],"settings":{}}',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('backup rejects duplicate task IDs', () {
    final taskMap = Task(
      id: 'duplicate',
      title: 'Task',
      createdAt: DateTime(2026),
    ).toMap();
    final encoded = TodoBackup.encode({
      'format': 'TodO backup',
      'schemaVersion': TodoBackup.currentVersion,
      'tasks': [taskMap, taskMap],
      'categories': [],
      'settings': {},
    });

    expect(() => TodoBackup.decode(encoded), throwsA(isA<FormatException>()));
  });

  test('backup rejects invalid notification preferences', () {
    final encoded = TodoBackup.encode({
      'format': 'TodO backup',
      'schemaVersion': TodoBackup.currentVersion,
      'tasks': [],
      'categories': [],
      'settings': {'reminderMinutesBefore': 999},
    });

    expect(() => TodoBackup.decode(encoded), throwsA(isA<FormatException>()));
  });

  test('backup accepts supported notification sound modes', () {
    final encoded = TodoBackup.encode({
      'format': 'TodO backup',
      'schemaVersion': TodoBackup.currentVersion,
      'tasks': [],
      'categories': [],
      'settings': {
        'taskRemindersEnabled': false,
        'notificationSoundMode': 'silent',
      },
    });

    expect(TodoBackup.decode(encoded).settings, {
      'taskRemindersEnabled': false,
      'notificationSoundMode': 'silent',
    });
  });

  test('backup rejects unsupported notification sound modes', () {
    final encoded = TodoBackup.encode({
      'format': 'TodO backup',
      'schemaVersion': TodoBackup.currentVersion,
      'tasks': [],
      'categories': [],
      'settings': {'notificationSoundMode': 'unknown'},
    });

    expect(() => TodoBackup.decode(encoded), throwsA(isA<FormatException>()));
  });
}

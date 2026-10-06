import 'dart:convert';

import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/task.dart';

class TodoBackup {
  static const currentVersion = 1;
  static const _booleanSettings = {
    'isDarkMode',
    'dailySummaryEnabled',
    'weeklySummaryEnabled',
    'taskRemindersEnabled',
    'notificationSoundEnabled',
    'seeded',
    'onboardingCompleted',
    'tutorialCompleted',
  };

  final List<Task> tasks;
  final List<Category> categories;
  final Map<String, dynamic> settings;

  const TodoBackup({
    required this.tasks,
    required this.categories,
    required this.settings,
  });

  static String encode(Map<String, dynamic> data) =>
      const JsonEncoder.withIndent('  ').convert(data);

  static TodoBackup decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Format file backup TodO tidak valid.');
    }
    if (decoded['format'] != 'TodO backup') {
      throw const FormatException('File ini bukan cadangan TodO.');
    }
    final version = decoded['schemaVersion'];
    if (version != currentVersion) {
      throw FormatException('Versi backup tidak didukung: $version.');
    }

    final tasksValue = decoded['tasks'];
    final categoriesValue = decoded['categories'];
    final settingsValue = decoded['settings'];
    if (tasksValue is! List ||
        categoriesValue is! List ||
        settingsValue is! Map) {
      throw const FormatException('Isi file backup TodO tidak lengkap.');
    }

    final tasks = tasksValue.map((value) {
      if (value is! Map) {
        throw const FormatException('Data tugas pada backup tidak valid.');
      }
      return Task.fromMap(Map<dynamic, dynamic>.from(value));
    }).toList();
    final categories = categoriesValue.map((value) {
      if (value is! Map) {
        throw const FormatException('Data kategori pada backup tidak valid.');
      }
      return Category.fromMap(Map<dynamic, dynamic>.from(value));
    }).toList();
    final settings = <String, dynamic>{};
    for (final entry in settingsValue.entries) {
      if (entry.key is! String) {
        throw const FormatException('Pengaturan backup tidak valid.');
      }
      final key = entry.key as String;
      final value = entry.value;
      if (_booleanSettings.contains(key) && value is! bool) {
        throw FormatException('Nilai pengaturan "$key" tidak valid.');
      }
      if (key == 'reminderMinutesBefore' &&
          (value is! int || !{5, 10, 15, 30, 60}.contains(value))) {
        throw const FormatException('Waktu pengingat pada backup tidak valid.');
      }
      if (key == 'notificationSoundMode' &&
          (value is! String ||
              !{'builtIn', 'device', 'silent'}.contains(value))) {
        throw const FormatException('Pilihan suara pada backup tidak valid.');
      }
      settings[key] = value;
    }

    _ensureUniqueIds(tasks.map((task) => task.id), 'tugas');
    _ensureUniqueIds(categories.map((category) => category.id), 'kategori');
    return TodoBackup(tasks: tasks, categories: categories, settings: settings);
  }

  static void _ensureUniqueIds(Iterable<String> ids, String label) {
    final values = ids.toList();
    if (values.toSet().length != values.length) {
      throw FormatException('Backup memiliki ID $label yang duplikat.');
    }
  }
}

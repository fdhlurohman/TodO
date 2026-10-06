import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/data/task_repository.dart';
import 'package:premium_todo/models/category_presets.dart';
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/services/notification_service.dart';
import 'package:premium_todo/services/task_notification_manager.dart';

void main() {
  test('task reminder IDs are deterministic and avoid reserved IDs', () {
    expect(
      notificationIdForTask('stable-task'),
      notificationIdForTask('stable-task'),
    );
    expect(notificationIdForTask('stable-task'), isNot(0));
    expect(notificationIdForTask('stable-task'), isNot(999));
    expect(notificationIdForTask('stable-task'), isNot(2001));
    expect(notificationIdForTask('stable-task'), isNot(2002));
    expect(
      notificationIdForTask('stable-task'),
      isNot(notificationIdForTask('another-task')),
    );
  });

  group('Task reminder timing', () {
    final now = DateTime(2026, 10, 1, 12);

    test('uses the configured lead time when there is enough time', () {
      final due = now.add(const Duration(minutes: 45));

      expect(
        taskReminderScheduleTime(due, now: now, minutesBefore: 15),
        now.add(const Duration(minutes: 30)),
      );
    });

    test('still schedules at the deadline if its lead time already passed', () {
      final due = now.add(const Duration(minutes: 5));

      expect(taskReminderScheduleTime(due, now: now, minutesBefore: 15), due);
    });

    test('does not schedule a reminder for a deadline that has passed', () {
      expect(
        taskReminderScheduleTime(
          now.subtract(const Duration(seconds: 1)),
          now: now,
          minutesBefore: 15,
        ),
        isNull,
      );
    });
  });

  late MemoryTaskRepository repository;
  late RecordingTaskNotifications notifications;
  late TaskProvider provider;

  setUp(() {
    repository = MemoryTaskRepository();
    notifications = RecordingTaskNotifications();
    provider = TaskProvider(repository, notifications: notifications);
  });

  group('TaskProvider notification lifecycle', () {
    test(
      'does not request permission when task reminders are globally off',
      () async {
        notifications.remindersEnabled = false;

        await provider.addTask(createTask(id: 'reminders-disabled'));

        expect(notifications.permissionRequests, 0);
        expect(notifications.syncedTasks, hasLength(1));
      },
    );

    test('add, update, delete maintain reminder and summary state', () async {
      final task = createTask(id: 'task-1');
      await provider.addTask(task);

      expect(provider.totalCount, 1);
      expect(notifications.permissionRequests, 1);
      expect(notifications.syncedTasks.single.title, 'Task task-1');
      expect(notifications.summaryCounts, [1]);

      task
        ..title = 'Updated'
        ..dueDate = DateTime.now().add(const Duration(days: 3));
      task.reminderEnabled = false;
      await provider.updateTask(task);

      expect(notifications.syncedTasks.last.title, 'Updated');
      expect(notifications.syncedTasks.last.reminderEnabled, isFalse);
      expect(notifications.summaryCounts.last, 1);

      await provider.deleteTask(task.id);
      expect(provider.totalCount, 0);
      expect(notifications.cancelledTaskIds, ['task-1']);
      expect(notifications.summaryCounts.last, 0);
    });

    test('completion cancels reminder and undo restores it', () async {
      final task = createTask(id: 'task-2');
      await provider.addTask(task);

      await provider.toggleComplete(task.id);
      expect(provider.allTasks.single.isCompleted, isTrue);
      expect(notifications.syncedTasks.last.isCompleted, isTrue);
      expect(notifications.summaryCounts.last, 0);

      await provider.toggleComplete(task.id);
      expect(provider.allTasks.single.isCompleted, isFalse);
      expect(notifications.syncedTasks.last.isCompleted, isFalse);
      expect(notifications.summaryCounts.last, 1);
    });

    test(
      'completing recurring task moves deadline and reschedules reminder',
      () async {
        final task = createTask(
          id: 'daily-task',
          recurrence: Recurrence.daily,
          dueDate: DateTime(2026, 9, 30, 10),
        );
        await provider.addTask(task);

        await provider.toggleComplete(task.id);

        final updated = provider.allTasks.single;
        expect(updated.isCompleted, isFalse);
        expect(updated.dueDate, DateTime(2026, 10, 1, 10));
        expect(notifications.syncedTasks.last.dueDate, updated.dueDate);
      },
    );

    test(
      'load restores saved tasks and synchronizes their reminders',
      () async {
        await provider.addTask(createTask(id: 'persisted-task'));
        final restartNotifications = RecordingTaskNotifications();
        final restartedProvider = TaskProvider(
          repository,
          notifications: restartNotifications,
        );

        await restartedProvider.load();
        await restartedProvider.syncNotificationSchedules();

        expect(restartedProvider.allTasks.map((task) => task.id), [
          'persisted-task',
        ]);
        expect(restartNotifications.syncedTasks.single.id, 'persisted-task');
        expect(restartNotifications.summaryCounts, [1]);
        expect(restartNotifications.permissionRequests, 0);
      },
    );

    test(
      'does not request notification permission when a task has no reminder',
      () async {
        final task = createTask(id: 'without-reminder');
        task.reminderEnabled = false;

        await provider.addTask(task);

        expect(notifications.permissionRequests, 0);
      },
    );

    test(
      'requests notification permission for a deadline within reminder window',
      () async {
        final task = createTask(
          id: 'near-deadline',
          dueDate: DateTime.now().add(const Duration(minutes: 5)),
        );

        await provider.addTask(task);

        expect(notifications.permissionRequests, 1);
        expect(notifications.syncedTasks.single.id, 'near-deadline');
      },
    );

    test(
      'notification failure does not undo a successfully saved task',
      () async {
        final failingProvider = TaskProvider(
          repository,
          notifications: FailingTaskNotifications(),
        );
        final saved = await failingProvider.addTask(
          createTask(id: 'saved-task'),
        );

        expect(saved, isFalse);
        expect(failingProvider.allTasks.single.id, 'saved-task');
        expect(repository.getAllTasks().single.id, 'saved-task');
      },
    );
  });

  group('First-run choice', () {
    test('tutorial completion persists and is restored after reload', () async {
      await provider.load();
      expect(provider.needsTutorial, isTrue);

      await provider.completeTutorial();

      expect(provider.needsTutorial, isFalse);
      expect(repository.getSetting<bool>('tutorialCompleted'), isTrue);

      final restartedProvider = TaskProvider(
        repository,
        notifications: RecordingTaskNotifications(),
      );
      await restartedProvider.load();
      expect(restartedProvider.needsTutorial, isFalse);
      expect(restartedProvider.needsOnboarding, isTrue);
    });

    test(
      'empty start persists the choice without creating sample tasks',
      () async {
        await provider.load();
        expect(provider.needsOnboarding, isTrue);

        await provider.completeOnboarding(
          categories: defaultCategories(),
          includeSampleTasks: false,
        );

        expect(provider.needsOnboarding, isFalse);
        expect(provider.allTasks, isEmpty);
        expect(repository.getSetting<bool>('onboardingCompleted'), isTrue);
        expect(repository.getSetting<bool>('seeded'), isFalse);
      },
    );

    test('sample choice creates examples only once', () async {
      await provider.load();
      await provider.completeOnboarding(
        categories: defaultCategories(),
        includeSampleTasks: true,
      );
      final seededCount = provider.totalCount;
      expect(seededCount, greaterThan(0));

      await provider.completeOnboarding(
        categories: defaultCategories(),
        includeSampleTasks: true,
      );

      expect(provider.totalCount, seededCount);
      expect(repository.getSetting<bool>('seeded'), isTrue);
    });

    test(
      'sample choice works when preset categories are unavailable',
      () async {
        await provider.load();

        await provider.completeOnboarding(
          categories: [],
          includeSampleTasks: true,
        );

        expect(provider.needsOnboarding, isFalse);
        expect(provider.totalCount, greaterThan(0));
        expect(
          provider.allTasks.every((task) => task.categoryIdRef == null),
          isTrue,
        );
        expect(repository.getSetting<bool>('onboardingCompleted'), isTrue);
      },
    );

    test('legacy seeded installation does not show onboarding again', () async {
      await repository.setSetting('seeded', true);
      await provider.load();
      expect(provider.needsOnboarding, isFalse);
    });
  });
}

Task createTask({
  required String id,
  Recurrence recurrence = Recurrence.none,
  DateTime? dueDate,
}) => Task(
  id: id,
  title: 'Task $id',
  createdAt: DateTime(2026, 9, 30),
  dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
  recurrence: recurrence,
);

class MemoryTaskRepository implements TaskRepository {
  final Map<String, Map<String, dynamic>> _tasks = {};
  final Map<String, dynamic> _settings = {};

  @override
  List<Task> getAllTasks() =>
      _tasks.values.map((map) => Task.fromMap(map)).toList();

  @override
  Future<void> saveTask(Task task) async {
    _tasks[task.id] = task.toMap();
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.remove(id);
  }

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

class RecordingTaskNotifications implements TaskNotificationManager {
  final List<Task> syncedTasks = [];
  final List<String> cancelledTaskIds = [];
  final List<int> summaryCounts = [];
  int permissionRequests = 0;
  bool remindersEnabled = true;

  @override
  int get reminderMinutesBefore => 15;

  @override
  bool get taskRemindersEnabled => remindersEnabled;

  @override
  Future<void> requestNotificationPermission() async {
    permissionRequests++;
  }

  @override
  Future<void> syncTaskReminder(Task task) async {
    syncedTasks.add(Task.fromMap(task.toMap()));
  }

  @override
  Future<void> syncTaskReminders(List<Task> tasks) async {
    syncedTasks.addAll(tasks.map((task) => Task.fromMap(task.toMap())));
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    cancelledTaskIds.add(taskId);
  }

  @override
  Future<void> refreshDailySummary(int activeCount) async {
    summaryCounts.add(activeCount);
  }
}

class FailingTaskNotifications extends RecordingTaskNotifications {
  @override
  Future<void> syncTaskReminder(Task task) async {
    throw StateError('Notification scheduling failed');
  }
}

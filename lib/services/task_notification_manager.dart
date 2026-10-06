import 'package:premium_todo/models/task.dart';

abstract interface class TaskNotificationManager {
  int get reminderMinutesBefore;
  bool get taskRemindersEnabled;
  Future<void> requestNotificationPermission();
  Future<void> syncTaskReminder(Task task);
  Future<void> syncTaskReminders(List<Task> tasks);
  Future<void> cancelTaskReminder(String taskId);
  Future<void> refreshDailySummary(int activeCount);
}

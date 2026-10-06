import 'package:premium_todo/models/task.dart';

abstract interface class TaskRepository {
  List<Task> getAllTasks();
  Future<void> saveTask(Task task);
  Future<void> deleteTask(String id);
  T? getSetting<T>(String key, {T? defaultValue});
  Future<void> setSetting(String key, dynamic value);
}

// ============================================================
// MODEL: SUB-TUGAS (CHECKLIST)
// Merupakan bagian dari Task (tersimpan di dalam objek Task),
// bukan box Hive terpisah - agar atomic dan sederhana.
// ============================================================
import 'package:premium_todo/core/utils/id_generator.dart';

class SubTask {
  String id;
  String title;
  bool isDone;

  SubTask({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  /// Map -> SubTask (dibaca dari Hive).
  factory SubTask.fromMap(Map<dynamic, dynamic> map) => SubTask(
        id: map['id'] as String,
        title: map['title'] as String,
        isDone: map['done'] as bool? ?? false,
      );

  /// SubTask -> Map (disimpan ke Hive sebagai List<Map>).
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': isDone,
      };

  /// Buat sub-tugas baru dengan id unik.
  factory SubTask.create(String title) => SubTask(id: genId(), title: title);
}

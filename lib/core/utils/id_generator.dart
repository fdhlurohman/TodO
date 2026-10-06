// ============================================================
// UTILITAS: PEMBANGKIT ID UNIK
// ID dipakai untuk key Hive (task, kategori, sub-tugas).
// Format: timestamp base36 + 6 karakter acak -> "m1abc2-3fk9xz"
// ============================================================
import 'dart:math';

String genId() {
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rnd = Random();
  final suffix = StringBuffer();
  for (var i = 0; i < 6; i++) {
    suffix.write(rnd.nextInt(36).toRadixString(36));
  }
  return '$ts-$suffix';
}

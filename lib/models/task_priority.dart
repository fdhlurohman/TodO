// ============================================================
// MODEL: PRIORITAS TUGAS
// Disimpan sebagai int di Hive (0=rendah, 1=sedang, 2=tinggi)
// agar mudah diurutkan (semakin besar = semakin prioritas).
// ============================================================
enum TaskPriority {
  low,    // Rendah  - abu-abu
  medium, // Sedang  - oranye
  high;   // Tinggi  - merah

  /// Konversi dari nilai int Hive (dengan fallback aman).
  static TaskPriority fromInt(int value) =>
      (value >= 0 && value < TaskPriority.values.length)
          ? TaskPriority.values[value]
          : TaskPriority.medium;

  /// Nilai int untuk penyimpanan Hive.
  int get toInt => index;

  /// Warna indikator prioritas (chip, garis kartu, dsb).
  int get colorValue {
    switch (this) {
      case TaskPriority.low:
        return 0xFF64748B; // slate-500
      case TaskPriority.medium:
        return 0xFFF59E0B; // amber-500
      case TaskPriority.high:
        return 0xFFEF4444; // red-500
    }
  }

  /// Label bahasa Indonesia untuk UI.
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Rendah';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.high:
        return 'Tinggi';
    }
  }

  /// Ikon Material untuk prioritas ini.
  String get iconName {
    switch (this) {
      case TaskPriority.low:
        return 'low_priority';
      case TaskPriority.medium:
        return 'priority_high';
      case TaskPriority.high:
        return 'keyboard_double_arrow_up';
    }
  }
}

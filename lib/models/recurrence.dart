// ============================================================
// MODEL: PENGULANGAN TUGAS (RECURRING)
// none    : tidak berulang
// daily   : berulang setiap hari
// weekly  : berulang setiap minggu (hari yang sama)
// monthly : berulang setiap bulan (tanggal yang sama)
// ============================================================
enum Recurrence {
  none,
  daily,
  weekly,
  monthly;

  /// Konversi dari string Hive (dengan fallback aman).
  static Recurrence fromString(String value) => Recurrence.values
      .firstWhere((e) => e.name == value, orElse: () => Recurrence.none);

  /// Nilai string untuk penyimpanan Hive.
  String get toStore => name;

  /// Label bahasa Indonesia untuk UI.
  String get label {
    switch (this) {
      case Recurrence.none:
        return 'Tidak berulang';
      case Recurrence.daily:
        return 'Setiap hari';
      case Recurrence.weekly:
        return 'Setiap minggu';
      case Recurrence.monthly:
        return 'Setiap bulan';
    }
  }

  /// Ikon Material untuk mode pengulangan ini.
  String get iconName {
    switch (this) {
      case Recurrence.none:
        return 'event_busy';
      case Recurrence.daily:
        return 'today';
      case Recurrence.weekly:
        return 'date_range';
      case Recurrence.monthly:
        return 'calendar_month';
    }
  }

  /// Hitung deadline berikutnya setelah [from] untuk tugas berulang.
  /// Dipakai saat tugas selesai: jadwal bergeser ke siklus berikutnya.
  DateTime? nextAfter(DateTime from, {int? dayOfMonth}) {
    switch (this) {
      case Recurrence.none:
        return null;
      case Recurrence.daily:
        return from.add(const Duration(days: 1));
      case Recurrence.weekly:
        return from.add(const Duration(days: 7));
      case Recurrence.monthly:
        // Tambah 1 bulan dengan penanganan akhir bulan
        // (mis. 31 Jan -> 28/29 Feb).
        var month = from.month + 1;
        var year = from.year;
        if (month > 12) {
          month = 1;
          year++;
        }
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = (dayOfMonth ?? from.day).clamp(1, lastDay);
        return DateTime(
          year,
          month,
          day,
          from.hour,
          from.minute,
          from.second,
          from.millisecond,
          from.microsecond,
        );
    }
  }
}

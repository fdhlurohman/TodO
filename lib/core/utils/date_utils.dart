// ============================================================
// UTILITAS TANGGAL (Bahasa Indonesia, tanpa dependency eksternal)
// Semua format tanggal/pJam aplikasi lewat sini agar konsisten.
// ============================================================
class AppDateUtils {
  AppDateUtils._(); // cegah instansiasi (hanya berisi fungsi statis)

  /// Nama bulan singkat bahasa Indonesia (index 0 = Januari).
  static const List<String> _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Nama hari singkat bahasa Indonesia (index 0 = Senin).
  static const List<String> _dayShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  /// Hilangkan komponen jam -> DateTime pukul 00:00.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Cek apakah dua tanggal berada pada hari kalender yang sama.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Format jam "09:05" (24 jam).
  static String formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Format tanggal "29 Sep 2026".
  static String formatDate(DateTime d) =>
      '${d.day} ${_monthShort[d.month - 1]} ${d.year}';

  /// Format lengkap "29 Sep 2026 • 09:05".
  static String formatFull(DateTime d) =>
      '${formatDate(d)} • ${formatTime(d)}';

  /// Nama hari singkat dari nilai weekday Flutter (1 = Senin ... 7 = Minggu).
  static String dayShort(int weekday) => _dayShort[(weekday - 1) % 7];

  /// Label relatif untuk deadline: "Hari ini", "Besok", "Terlambat 3 hrl".
  static String relativeDayLabel(DateTime due) {
    final diff = dateOnly(due).difference(dateOnly(DateTime.now())).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    if (diff == -1) return 'Kemarin';
    if (diff < 0) return 'Terlambat ${-diff} hrl';
    if (diff < 7) return '$diff hari lagi';
    return formatDate(due);
  }
}

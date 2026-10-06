// ============================================================
// LAYAR: KALENDER
//  - Kalender bulanan (table_calendar) dengan marker deadline
//  - Ketuk tanggal -> tampil daftar tugas tanggal itu
//  - Tugas terlambat ditandai merah
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:premium_todo/core/utils/date_utils.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final cs = Theme.of(context).colorScheme;

    // Semua tugas ber-deadline (untuk marker kalender).
    final scheduled = taskProvider
        .getAllTasksForCalendar(); // lihat method di TaskProvider

    // Tugas pada hari terpilih (atau hari ini jika belum memilih).
    final dayTasks = taskProvider
        .tasksForDay(_selectedDay ?? DateTime.now())
        .where((t) => !t.isCompleted || _isSameDay(_selectedDay, t.completedAt))
        .toList()
      ..sort((a, b) => (a.dueDate ?? a.createdAt)
          .compareTo(b.dueDate ?? b.createdAt));

    return Column(
      children: [
        // ================= KALENDER =================
        Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<Task>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && _isSameDay(day, _selectedDay!),
              onDaySelected: (selected, focused) =>
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  }),
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              // ---------- LOKALISASI + FORMAT ----------
              daysOfWeekHeight: 32,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) =>
                    '${_monthLabels[date.month - 1]} ${date.year}',
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              // ---------- MARKER DEADLINE + LABEL HARI ----------
              eventLoader: (day) =>
                  scheduled.where((t) => _isSameDay(t.dueDate, day)).toList(),
              calendarBuilders: CalendarBuilders(
                // Header hari (Sen, Sel, ...) bahasa Indonesia.
                dowBuilder: (ctx, day) => Center(
                  child: Text(
                    _dayLabels[(day.weekday - 1) % 7],
                    style: Theme.of(ctx)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
                markerBuilder: (ctx, day, events) {
                  if (events.isEmpty) return null;
                  final hasOverdue = events.any((t) => t.isOverdue);
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titik merah jika ada tugas terlambat,
                        // titik warna brand jika normal.
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasOverdue
                                ? cs.error
                                : cs.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ================= JUDUL DAFTAR =================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                _selectedDay == null
                    ? 'Tugas hari ini'
                    : 'Tugas ${AppDateUtils.formatDate(_selectedDay!)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '${dayTasks.length} tugas',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // ================= DAFTAR TUGAS HARI ITU =================
        Expanded(
          child: dayTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 56, color: cs.outlineVariant),
                      const SizedBox(height: 8),
                      Text('Tidak ada tugas pada tanggal ini',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: dayTasks.map((t) => TaskCard(task: t)).toList(),
                ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return AppDateUtils.isSameDay(a, b);
  }
}

/// Label hari bahasa Indonesia (Senin..Minggu).
const List<String> _dayLabels = [
  'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
];

/// Nama bulan bahasa Indonesia (Januari..Desember).
const List<String> _monthLabels = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

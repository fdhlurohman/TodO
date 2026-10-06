// ============================================================
// LAYAR: ANALITIK (DASHBOARD PRODUKTIVITAS)
//  1. Donut chart: rasio selesai vs aktif (fl_chart PieChart)
//  2. Bar chart: tugas selesai 7 hari terakhir (fl_chart BarChart)
//  3. Distribusi per kategori (progress bar berwarna)
//  4. Distribusi per prioritas (baris badge)
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:premium_todo/core/utils/date_utils.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/models/task_priority.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final cs = Theme.of(context).colorScheme;

    final total = taskProvider.totalCount;
    final completed = taskProvider.completedCount;
    final active = taskProvider.activeCount;
    final rate = total == 0 ? 0.0 : completed / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // ================= JUDUL =================
        Text(
          'Produktivitas',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // ================= DONUT CHART =================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tingkat Penyelesaian',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Donut chart
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 55,
                          startDegreeOffset: -90,
                          sections: [
                            // Segmen SELESAI (hijau)
                            PieChartSectionData(
                              value: completed.toDouble(),
                              color: Colors.green.shade500,
                              radius: 22,
                              showTitle: false,
                            ),
                            // Segmen AKTIF (brand)
                            PieChartSectionData(
                              value: active.toDouble(),
                              color: cs.primary,
                              radius: 22,
                              showTitle: false,
                            ),
                            // Segmen KOSONG (abu) agar donut tetap tergambar
                            if (completed + active == 0)
                              PieChartSectionData(
                                value: 1,
                                color: cs.outlineVariant,
                                radius: 22,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      // Persentase di tengah donut
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(rate * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'selesai',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ---------- LEGENDA ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(Colors.green.shade500, 'Selesai ($completed)'),
                    const SizedBox(width: 16),
                    _legendDot(cs.primary, 'Aktif ($active)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ================= BAR CHART 7 HARI =================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selesai 7 Hari Terakhir',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: _WeeklyBarChart(
                    tasks: taskProvider.allTasks,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ================= DISTRIBUSI KATEGORI =================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribusi Kategori',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...categoryProvider.categories.map((c) {
                  final all = taskProvider.allTasks;
                  final count =
                      all.where((t) => t.categoryIdRef == c.id).length;
                  final fraction =
                      all.isEmpty ? 0.0 : count / all.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(c.icon, size: 14, color: c.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(c.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ),
                            Text('$count',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: cs.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor:
                                cs.outlineVariant.withValues(alpha: 0.4),
                            valueColor:
                                AlwaysStoppedAnimation(c.color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ================= DISTRIBUSI PRIORITAS =================
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribusi Prioritas',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: TaskPriority.values.map((p) {
                    final count = taskProvider.allTasks
                        .where((t) => t.priority == p)
                        .length;
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Color(p.colorValue),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Titik legenda kecil + label.
  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

// ============================================================
// BAR CHART MINGGUAN (7 HARI TERAKHIR)
// Menghitung jumlah tugas yang completedAt-nya jatuh pada
// masing-masing hari.
// ============================================================
class _WeeklyBarChart extends StatelessWidget {
  final List<Task> tasks;
  const _WeeklyBarChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    // Siapkan data 7 hari: index 0 = 6 hari lalu, index 6 = hari ini.
    final days = List.generate(7, (i) {
      final d = AppDateUtils.dateOnly(
          today.subtract(Duration(days: 6 - i)));
      final count = tasks
          .where((t) =>
              t.completedAt != null &&
              AppDateUtils.isSameDay(t.completedAt!, d))
          .length;
      return MapEntry(d, count);
    });

    final maxCount = days
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxCount + 2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${rod.toY.toInt()} tugas',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // value = index hari (0..6)
                final i = value.toInt();
                if (i < 0 || i >= days.length) {
                  return const SizedBox.shrink();
                }
                final label = AppDateUtils.dayShort(days[i].key.weekday);
                final isToday = AppDateUtils.isSameDay(
                    days[i].key, today);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isToday
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: days.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value.key;
          final count = entry.value.value;
          final isToday = AppDateUtils.isSameDay(day, today);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(6),
                color: isToday
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.35),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

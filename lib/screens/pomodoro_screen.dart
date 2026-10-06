// ============================================================
// LAYAR: POMODORO FOCUS TIMER
//  - Ring progress besar dengan waktu tersisa di tengah
//  - Kontrol: mulai/jeda, reset, lewati fase
//  - Pemilih tugas: hubungkan sesi fokus dengan tugas tertentu
//  - Indikator siklus (4 titik = 4 sesi fokus)
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/providers/pomodoro_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Fokus'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ================= LABEL FASE =================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _phaseColor(context).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pomodoro.phase.label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        color: _phaseColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 24),

              // ================= RING PROGRESS =================
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring latar
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: pomodoro.progress,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        color: _phaseColor(context),
                        backgroundColor:
                            cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    // Waktu tersisa
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pomodoro.timeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pomodoro.isRunning
                              ? 'berjalan...'
                              : '${pomodoro.remainingSeconds} detik tersisa',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ================= INDIKATOR SIKLUS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pomodoro.sessionsBeforeLongBreak,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < pomodoro.completedFocusSessions
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ================= KONTROL =================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  IconButton.filledTonal(
                    onPressed: pomodoro.reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                  const SizedBox(width: 16),
                  // Mulai / jeda (tombol utama)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 52),
                    ),
                    onPressed: pomodoro.isRunning
                        ? pomodoro.pause
                        : pomodoro.start,
                    icon: Icon(pomodoro.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(pomodoro.isRunning ? 'Jeda' : 'Mulai'),
                  ),
                  const SizedBox(width: 16),
                  // Lewati fase
                  IconButton.filledTonal(
                    onPressed: pomodoro.skipPhase,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ================= PENGATURAN CEPAT DURASI FOKUS =================
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text('15 mnt')),
                  ButtonSegment(value: 25, label: Text('25 mnt')),
                  ButtonSegment(value: 50, label: Text('50 mnt')),
                ],
                selected: {pomodoro.focusMinutes},
                onSelectionChanged: (set) =>
                    pomodoro.setFocusMinutes(set.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 24),

              // ================= PILIH TUGAS TERHUBUNG =================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Tugas terhubung',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hubungkan sesi fokus ini dengan tugas tertentu.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      // Dropdown semua tugas aktif.
                      // Penting: item yang sedang ter-link WAJIB ikut
                      // dalam daftar items, meski sudah selesai/terfilter,
                      // jika tidak widget akan error (assertion).
                      DropdownButtonFormField<Task?>(
                        initialValue: taskProvider.pomodoroLinkedTask,
                        decoration: const InputDecoration(
                          prefixIcon:
                              Icon(Icons.task_alt_rounded),
                        ),
                        hint: const Text('Pilih tugas (opsional)'),
                        isExpanded: true,
                        items: <Task>[
                          if (taskProvider.pomodoroLinkedTask != null &&
                              !taskProvider.filteredTasks
                                  .where((t) => !t.isCompleted)
                                  .any((t) =>
                                      t.id == taskProvider
                                          .pomodoroLinkedTask!.id))
                            taskProvider.pomodoroLinkedTask!,
                          ...taskProvider.filteredTasks
                              .where((t) => !t.isCompleted),
                        ]
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (task) =>
                            taskProvider.linkPomodoroTask(task),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Warna fase: fokus = brand, istirahat = hijau, panjang = teal.
  Color _phaseColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (context.read<PomodoroProvider>().phase) {
      case PomodoroPhase.focus:
        return cs.primary;
      case PomodoroPhase.shortBreak:
        return Colors.green.shade500;
      case PomodoroPhase.longBreak:
        return Colors.teal.shade500;
    }
  }
}

// ============================================================
// WIDGET: KARTU TUGAS
// Menampilkan satu tugas di daftar beranda:
//  - checkbox bulat besar (toggle selesai)
//  - garis warna prioritas di sisi kiri
//  - judul, catatan, deadline, chip kategori, badge prioritas
//  - indikator progres sub-tugas
//  - menu aksi: edit, pin, hapus
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_todo/core/utils/date_utils.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/models/recurrence.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/screens/task_form_screen.dart';
import 'package:premium_todo/widgets/priority_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final category =
        context.watch<CategoryProvider>().byId(task.categoryIdRef);
    final priorityColor = Color(task.priority.colorValue);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        // Konfirmasi sebelum hapus - cegah hapus tak sengaja.
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hapus tugas?'),
                content: Text('"${task.title}" akan dihapus permanen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        context.read<TaskProvider>().deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tugas "${task.title}" dihapus')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskFormScreen(existing: task)),
          ),
          child: Container(
            // Garis warna prioritas di sisi kiri kartu.
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: priorityColor, width: 4),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- CHECKBOX SELESAI ----------
                GestureDetector(
                  onTap: () async {
                    // Tugas berulang tidak pernah "selesai": deadline-nya
                    // bergeser ke siklus berikutnya. Beri tahu pengguna.
                    if (!task.isCompleted &&
                        task.recurrence != Recurrence.none) {
                      final nextDue =
                          task.nextDueAfter(task.dueDate ?? DateTime.now());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            nextDue == null
                                ? 'Jadwal berikutnya dibuat'
                                : 'Dijadwalkan ulang ke '
                                    '${AppDateUtils.formatDate(nextDue)}',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    await context
                        .read<TaskProvider>()
                        .toggleComplete(task.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? priorityColor : null,
                      border: Border.all(
                        color: task.isCompleted
                            ? priorityColor
                            : cs.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // ---------- KONTEN ----------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ikon pin
                          if (task.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.push_pin_rounded,
                                  size: 14,
                                  color: cs.primary.withValues(alpha: 0.7)),
                            ),
                          // Judul (coret jika selesai)
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? cs.onSurfaceVariant
                                        : null,
                                  ),
                            ),
                          ),
                          // Menu aksi: pin + hapus
                          PopupMenuButton<String>(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'pin') {
                                context
                                    .read<TaskProvider>()
                                    .togglePin(task.id);
                              } else if (value == 'delete') {
                                context
                                    .read<TaskProvider>()
                                    .deleteTask(task.id);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(task.isPinned
                                    ? 'Lepas pin'
                                    : 'Pin tugas'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // ---------- CATATAN ----------
                      if (task.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // ---------- META: deadline, kategori, prioritas ----------
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Deadline + status terlambat
                          if (task.dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: task.isOverdue
                                      ? cs.error
                                      : cs.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  AppDateUtils.relativeDayLabel(
                                      task.dueDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: task.isOverdue
                                            ? cs.error
                                            : cs.onSurfaceVariant,
                                        fontWeight: task.isOverdue
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          // Chip kategori (warna kategori)
                          if (category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(category.icon,
                                      size: 12, color: category.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    category.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: category.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          // Badge prioritas
                          PriorityBadge(priority: task.priority, compact: true),
                          // Pengulangan
                          if (task.recurrence != Recurrence.none)
                            Icon(Icons.repeat_rounded,
                                size: 13, color: cs.onSurfaceVariant),
                        ],
                      ),
                      // ---------- PROGRES SUB-TUGAS ----------
                      if (task.subtasks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              // Progress bar mini
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: task.subtaskProgress,
                                    minHeight: 4,
                                    backgroundColor:
                                        cs.outlineVariant.withValues(alpha: 0.4),
                                    valueColor: AlwaysStoppedAnimation(
                                        cs.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

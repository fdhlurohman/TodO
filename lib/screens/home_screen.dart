// ============================================================
// LAYAR: BERANDA
// Komposisi dari atas ke bawah:
//  1. Sapaan + tanggal hari ini
//  2. 4 kartu statistik (total, aktif, selesai, terlambat)
//  3. Search bar (terhubung TaskProvider.setSearch)
//  4. Baris filter: status, prioritas, urutkan
//  5. Chip filter kategori (horizontal scroll)
//  6. Daftar tugas (hasil filter & sort)
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_todo/core/utils/date_utils.dart';
import 'package:premium_todo/models/task_priority.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/widgets/stat_card.dart';
import 'package:premium_todo/widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Sinkronkan isi search field bila query diubah dari luar
  /// (mis. lewat menu "Reset semua filter").
  void _syncSearchField(TaskProvider provider) {
    if (provider.searchQuery == _searchCtrl.text) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchCtrl
        ..text = provider.searchQuery
        ..selection =
            TextSelection.collapsed(offset: _searchCtrl.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final cs = Theme.of(context).colorScheme;

    // Semua tugas setelah filter+sort.
    final tasks = taskProvider.filteredTasks;
    _syncSearchField(taskProvider);

    return RefreshIndicator(
      onRefresh: () => taskProvider.load(),
      child: ListView(
        // physics AlwaysScrollable agar pull-to-refresh tetap berfungsi
        // meski konten lebih pendek dari layar.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // ================= SAPAAN =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppDateUtils.formatDate(DateTime.now())} • '
                  '${taskProvider.activeCount} tugas aktif',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ================= KARTU STATISTIK =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.checklist_rounded,
                    value: taskProvider.totalCount,
                    label: 'Total',
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.timelapse_rounded,
                    value: taskProvider.activeCount,
                    label: 'Aktif',
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_rounded,
                    value: taskProvider.completedCount,
                    label: 'Selesai',
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.warning_rounded,
                    value: taskProvider.overdueCount,
                    label: 'Terlambat',
                    color: cs.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ================= SEARCH BAR =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: taskProvider.setSearch,
              decoration: InputDecoration(
                hintText: 'Cari tugas, catatan, sub-tugas...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: taskProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => taskProvider.setSearch(''),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ================= BARIS FILTER & URUTKAN =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filter status (Semua / Aktif / Selesai)
                Expanded(
                  child: SegmentedButton<StatusFilter>(
                    segments: const [
                      ButtonSegment(
                          value: StatusFilter.all, label: Text('Semua')),
                      ButtonSegment(
                          value: StatusFilter.active, label: Text('Aktif')),
                      ButtonSegment(
                          value: StatusFilter.completed,
                          label: Text('Selesai')),
                    ],
                    selected: {taskProvider.statusFilter},
                    onSelectionChanged: (set) =>
                        taskProvider.setStatusFilter(set.first),
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Menu urutkan + filter prioritas
                _FilterMenuButton(provider: taskProvider),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ================= CHIP KATEGORI =================
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Chip "Semua kategori"
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Semua'),
                    selected: taskProvider.filterCategoryId == null,
                    onSelected: (_) =>
                        taskProvider.setCategoryFilter(null),
                  ),
                ),
                // Chip per kategori (warna mengikuti kategori)
                ...categoryProvider.categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected:
                          taskProvider.filterCategoryId == c.id,
                      onSelected: (_) =>
                          taskProvider.setCategoryFilter(c.id),
                      avatar: Icon(c.icon,
                          size: 16, color: c.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ================= DAFTAR TUGAS =================
          if (tasks.isEmpty)
            _EmptyState(
              hasFilters: _searchCtrl.text.isNotEmpty ||
                  taskProvider.filterCategoryId != null ||
                  taskProvider.filterPriority != null,
            )
          else
            ...tasks.map((t) => TaskCard(task: t)),

          // ================= LINK POMODORO =================
          if (taskProvider.pomodoroLinkedTask != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _PomodoroLinkBanner(),
            ),
        ],
      ),
    );
  }

  /// Sapaan sesuai jam: Pagi/Siang/Sore/Malam.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) return 'Selamat pagi 👋';
    if (h >= 11 && h < 15) return 'Selamat siang ☀️';
    if (h >= 15 && h < 19) return 'Selamat sore 🌤️';
    return 'Selamat malam 🌙';
  }
}

// ============================================================
// TOMBOL MENU FILTER PRIORITAS + URUTKAN
// ============================================================
class _FilterMenuButton extends StatelessWidget {
  final TaskProvider provider;
  const _FilterMenuButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filter & urutkan',
      icon: const Icon(Icons.tune_rounded),
      onSelected: (value) {
        switch (value) {
          case 'prio_high':
          case 'prio_medium':
          case 'prio_low':
            // Toggle filter prioritas (klik lagi = hapus filter)
            final map = {
              'prio_high': TaskPriority.high,
              'prio_medium': TaskPriority.medium,
              'prio_low': TaskPriority.low,
            };
            final p = map[value]!;
            provider.setPriorityFilter(
                provider.filterPriority == p ? null : p);
            break;
          case 'sort_due':
            provider.setSortMode(TaskSort.dueDate);
            break;
          case 'sort_priority':
            provider.setSortMode(TaskSort.priority);
            break;
          case 'sort_newest':
            provider.setSortMode(TaskSort.createdNewest);
            break;
          case 'sort_title':
            provider.setSortMode(TaskSort.title);
            break;
          case 'reset':
            provider.resetFilters();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
            enabled: false, height: 32, child: Text('PRIORITAS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        CheckedPopupMenuItem(
          checked: provider.filterPriority == TaskPriority.high,
          value: 'prio_high',
          child: const Text('Tinggi'),
        ),
        CheckedPopupMenuItem(
          checked: provider.filterPriority == TaskPriority.medium,
          value: 'prio_medium',
          child: const Text('Sedang'),
        ),
        CheckedPopupMenuItem(
          checked: provider.filterPriority == TaskPriority.low,
          value: 'prio_low',
          child: const Text('Rendah'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
            enabled: false, height: 32, child: Text('URUTKAN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        CheckedPopupMenuItem(
          checked: provider.sortMode == TaskSort.dueDate,
          value: 'sort_due',
          child: const Text('Deadline'),
        ),
        CheckedPopupMenuItem(
          checked: provider.sortMode == TaskSort.priority,
          value: 'sort_priority',
          child: const Text('Prioritas'),
        ),
        CheckedPopupMenuItem(
          checked: provider.sortMode == TaskSort.createdNewest,
          value: 'sort_newest',
          child: const Text('Terbaru'),
        ),
        CheckedPopupMenuItem(
          checked: provider.sortMode == TaskSort.title,
          value: 'sort_title',
          child: const Text('Judul A-Z'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'reset',
          child: Text('Reset semua filter'),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY STATE (TIDAK ADA TUGAS)
// ============================================================
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'Tidak ada tugas yang cocok dengan filter'
                : 'Belum ada tugas.\nTekan tombol + untuk menambah!',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BANNER LINK POMODORO
// ============================================================
class _PomodoroLinkBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.pomodoroLinkedTask!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pomodoro terhubung: ${task.title}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => provider.linkPomodoroTask(null),
          ),
        ],
      ),
    );
  }
}

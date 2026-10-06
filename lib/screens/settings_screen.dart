// ============================================================
// LAYAR: PENGATURAN
//  - Pilihan tema: Terang / Gelap / Sistem (SegmentedButton)
//  - Kelola kategori: tambah, edit, hapus (dialog)
//  - Notifikasi: pengingat tugas, pilihan suara, ringkasan harian/mingguan
//  - Timer fokus: tombol menuju layar Pomodoro
// ============================================================
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:premium_todo/data/hive_repository.dart';
import 'package:premium_todo/data/todo_backup.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/category_presets.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/providers/theme_provider.dart';
import 'package:premium_todo/screens/first_run_screen.dart';
import 'package:premium_todo/screens/pomodoro_screen.dart';
import 'package:premium_todo/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailySummaryEnabled = NotificationService.instance.dailySummaryEnabled;
  bool _weeklySummaryEnabled =
      NotificationService.instance.weeklySummaryEnabled;
  bool _taskRemindersEnabled =
      NotificationService.instance.taskRemindersEnabled;
  bool _updatingDailySummary = false;
  bool _updatingWeeklySummary = false;
  bool _updatingTaskReminders = false;
  String _soundMode = NotificationService.instance.notificationSoundMode;
  String? _soundName = NotificationService.instance.notificationSoundName;
  int _reminderMinutesBefore =
      NotificationService.instance.reminderMinutesBefore;
  bool _updatingReminderTime = false;
  static const _soundPickerChannel = MethodChannel(
    'my.id.fads.todo/notification_sound_picker',
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadNotificationPreferences());
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final notifications = NotificationService.instance;
      await notifications.loadSettings();
      if (mounted) {
        setState(() {
          _dailySummaryEnabled = notifications.dailySummaryEnabled;
          _weeklySummaryEnabled = notifications.weeklySummaryEnabled;
          _taskRemindersEnabled = notifications.taskRemindersEnabled;
          _soundMode = notifications.notificationSoundMode;
          _soundName = notifications.notificationSoundName;
          _reminderMinutesBefore = notifications.reminderMinutesBefore;
        });
        if (notifications.soundSelectionRecovered) {
          _showMessage(
            'Suara perangkat sebelumnya tidak tersedia. TodO memakai suara default.',
          );
        }
      }
    } catch (error) {
      _showMessage(_friendlyNotificationError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<TaskProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // ================= JUDUL =================
        Text(
          'Pengaturan',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // ================= TEMA =================
        _SectionCard(
          title: 'Tampilan',
          children: [
            Row(
              children: [
                const Icon(Icons.dark_mode_rounded, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Mode gelap')),
                Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ],
            ),
            const Divider(height: 24),
            // Tombol tema cepat (terang / gelap)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Terang'),
                  icon: Icon(Icons.light_mode_rounded, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Gelap'),
                  icon: Icon(Icons.dark_mode_rounded, size: 16),
                ),
              ],
              selected: {themeProvider.isDark},
              onSelectionChanged: (set) => themeProvider.setDark(set.first),
              showSelectedIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= KATEGORI =================
        _SectionCard(
          title: 'Kategori & Tag',
          trailing: IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah kategori',
            onPressed: () => _showCategoryDialog(context),
          ),
          children: [
            // Daftar kategori + menu edit/hapus
            ...categoryProvider.categories.map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(c.icon, size: 18, color: c.color),
                ),
                title: Text(c.name),
                subtitle: Text(
                  'Dipakai ${_usageCount(taskProvider, c.id)} tugas',
                ),
                trailing: PopupMenuButton<String>(
                  iconSize: 20,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showCategoryDialog(context, existing: c);
                    } else if (value == 'delete') {
                      final result = await categoryProvider.delete(c.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(switch (result) {
                              CategoryDeleteResult.notUsed =>
                                'Kategori "${c.name}" dihapus',
                              CategoryDeleteResult.inUse =>
                                'Kategori masih dipakai tugas, tidak bisa dihapus',
                              CategoryDeleteResult.lastOne =>
                                'Minimal harus ada satu kategori',
                            }),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= NOTIFIKASI =================
        _SectionCard(
          title: 'Notifikasi',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_rounded),
              title: const Text('Pengingat tugas'),
              subtitle: const Text(
                'Aktifkan atau matikan semua pengingat tugas',
              ),
              value: _taskRemindersEnabled,
              onChanged: _updatingTaskReminders
                  ? null
                  : _setTaskRemindersEnabled,
            ),
            const Divider(height: 1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.music_note_rounded),
                  title: const Text('Suara notifikasi'),
                  subtitle: Text(_soundDescription),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _soundMode,
                    onChanged: (mode) {
                      if (mode == null) return;
                      if (mode == 'chooseDevice') {
                        _chooseNotificationSound();
                      } else {
                        _setNotificationSound(mode);
                      }
                    },
                    items: [
                      const DropdownMenuItem(
                        value: 'builtIn',
                        child: Text('Suara TodO'),
                      ),
                      DropdownMenuItem(
                        value: 'chooseDevice',
                        child: Text(
                          _soundMode == 'device'
                              ? 'Pilih suara lain'
                              : 'Pilih dari perangkat',
                        ),
                      ),
                      if (_soundMode == 'device')
                        DropdownMenuItem(
                          value: 'device',
                          child: Text(
                            _soundName ?? 'Suara perangkat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const DropdownMenuItem(
                        value: 'silent',
                        child: Text('Mati'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm_rounded),
              title: const Text('Waktu pengingat tugas'),
              subtitle: const Text('Sebelum deadline'),
              trailing: DropdownButton<int>(
                value: _reminderMinutesBefore,
                onChanged: _updatingReminderTime
                    ? null
                    : (minutes) {
                        if (minutes != null) {
                          _setReminderMinutesBefore(minutes);
                        }
                      },
                items: const [5, 10, 15, 30, 60]
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes menit'),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.today_rounded),
              title: const Text('Ringkasan harian'),
              subtitle: const Text('Setiap hari pukul 08:00'),
              value: _dailySummaryEnabled,
              onChanged: _updatingDailySummary
                  ? null
                  : (enabled) => _setDailySummary(
                      enabled,
                      activeCount: taskProvider.activeCount,
                    ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.date_range_rounded),
              title: const Text('Tinjauan mingguan'),
              subtitle: const Text('Setiap Senin pukul 09:00'),
              value: _weeklySummaryEnabled,
              onChanged: _updatingWeeklySummary ? null : _setWeeklySummary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= DATA & BACKUP =================
        _SectionCard(
          title: 'Data & cadangan',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Ekspor cadangan'),
              subtitle: const Text('Simpan tugas, kategori, dan pengaturan'),
              onTap: _exportBackup,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_open_rounded),
              title: const Text('Pulihkan cadangan'),
              subtitle: const Text('Gabungkan atau ganti data dari file JSON'),
              onTap: _importBackup,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= PRODUKTIVITAS =================
        _SectionCard(
          title: 'Produktivitas',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_rounded),
              title: const Text('Timer fokus (Pomodoro)'),
              subtitle: const Text('Fokus 25 menit, istirahat 5 menit'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PomodoroScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= TENTANG =================
        _SectionCard(
          title: 'Tentang',
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline_rounded),
              title: Text('TodO'),
              subtitle: Text('Versi 1.0.3 • Data tersimpan lokal (Hive)'),
              isThreeLine: false,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined),
              title: const Text('Lihat panduan penggunaan'),
              subtitle: const Text('Buka kembali tutorial TodO'),
              onTap: _replayTutorial,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportBackup() async {
    try {
      final json = TodoBackup.encode(
        HiveRepository.instance.createBackupData(),
      );
      final bytes = Uint8List.fromList(utf8.encode(json));
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/json',
              name: 'todo-backup.json',
            ),
          ],
          fileNameOverrides: ['todo-backup.json'],
          subject: 'Cadangan TodO',
        ),
      );
    } catch (error) {
      _showMessage('Cadangan gagal diekspor: $error');
    }
  }

  Future<void> _importBackup() async {
    final categoryProvider = context.read<CategoryProvider>();
    final taskProvider = context.read<TaskProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final notifications = NotificationService.instance;
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Pilih file cadangan TodO',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return;

      final bytes = await files.single.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw const FormatException('Ukuran file backup melebihi batas 10 MB.');
      }
      final contents = utf8.decode(bytes);
      final backup = TodoBackup.decode(contents);
      if (!mounted) return;

      final replaceExisting = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pulihkan cadangan'),
          content: Text(
            'Cadangan berisi ${backup.tasks.length} tugas dan '
            '${backup.categories.length} kategori.\n\n'
            'Gabungkan akan mempertahankan data saat ini dan memperbarui '
            'item dengan ID yang sama. Ganti akan menghapus data saat ini '
            'terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Gabungkan'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ganti data'),
            ),
          ],
        ),
      );
      if (replaceExisting == null || !mounted) return;

      if (replaceExisting) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ganti semua data?'),
            content: const Text(
              'Tugas, kategori, dan pengaturan saat ini akan diganti dengan '
              'isi cadangan. Pastikan kamu sudah membuat cadangan terbaru.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ganti data'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      await HiveRepository.instance.restoreBackup(
        tasks: backup.tasks,
        categories: backup.categories,
        settings: backup.settings,
        replaceExisting: replaceExisting,
      );
      await categoryProvider.reload();
      await taskProvider.load();
      await themeProvider.reloadFromStorage();
      try {
        await notifications.reloadSettings();
        await taskProvider.syncNotificationSchedules();
      } catch (error) {
        _showMessage(
          'Cadangan dipulihkan, tetapi pengingat gagal disinkronkan: $error',
        );
        return;
      }
      _showMessage(
        replaceExisting
            ? 'Cadangan berhasil dipulihkan.'
            : 'Data cadangan berhasil digabungkan.',
      );
    } catch (error) {
      _showMessage('Cadangan gagal dipulihkan: $error');
    }
  }

  Future<void> _replayTutorial() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FirstRunScreen(forceTutorial: true),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyNotificationError(Object error) {
    if (error is NotificationPermissionDeniedException) {
      return 'Izin notifikasi belum diberikan. Izinkan TodO di Pengaturan Android.';
    }
    if (error is PlatformException) {
      return switch (error.code) {
        'permission_request_in_progress' =>
          'Permintaan izin sedang diproses. Coba lagi sebentar.',
        'sound_access_denied' || 'sound_unreadable' =>
          error.message ??
              'File suara tidak bisa dibaca. Pilih file audio lain.',
        _ => error.message ?? 'Terjadi masalah pada notifikasi. Coba lagi.',
      };
    }
    if (error is FormatException || error is ArgumentError) {
      return error.toString().replaceFirst('FormatException: ', '');
    }
    return 'Pengaturan notifikasi gagal disimpan. Periksa izin aplikasi dan coba lagi.';
  }

  String get _soundDescription {
    return switch (_soundMode) {
      'device' =>
        _soundName == null
            ? 'Suara pilihan dari perangkat'
            : 'Suara pilihan: $_soundName',
      'silent' => 'Tidak ada suara',
      _ => 'Suara TodO (Tooo Dooo)',
    };
  }

  Future<void> _setTaskRemindersEnabled(bool enabled) async {
    setState(() => _updatingTaskReminders = true);
    try {
      await NotificationService.instance.setTaskRemindersEnabled(enabled);
      if (mounted) setState(() => _taskRemindersEnabled = enabled);
    } catch (error) {
      _showMessage(_friendlyNotificationError(error));
      if (mounted) {
        setState(
          () => _taskRemindersEnabled =
              NotificationService.instance.taskRemindersEnabled,
        );
      }
    } finally {
      if (mounted) setState(() => _updatingTaskReminders = false);
    }
  }

  Future<void> _setNotificationSound(
    String mode, {
    String? uri,
    String? name,
  }) async {
    try {
      await NotificationService.instance.setNotificationSound(
        mode: mode,
        uri: uri,
        name: name,
      );
      if (mounted) {
        setState(() {
          _soundMode = mode;
          _soundName = name;
        });
      }
    } catch (error) {
      _showMessage(_friendlyNotificationError(error));
    }
  }

  Future<void> _chooseNotificationSound() async {
    try {
      final selected = await _soundPickerChannel
          .invokeMapMethod<String, dynamic>('pickAudio');
      if (selected == null) return;
      final uri = selected['uri'];
      final name = selected['name'];
      if (uri is! String || uri.isEmpty) {
        throw const FormatException('File suara yang dipilih tidak valid.');
      }
      await _setNotificationSound(
        'device',
        uri: uri,
        name: name is String ? name : 'Suara perangkat',
      );
    } on PlatformException catch (error) {
      _showMessage(
        'Pemilih suara gagal dibuka: ${error.message ?? error.code}',
      );
    } catch (error) {
      _showMessage('Pemilihan suara gagal: $error');
    }
  }

  Future<void> _setDailySummary(
    bool enabled, {
    required int activeCount,
  }) async {
    setState(() => _updatingDailySummary = true);
    try {
      await NotificationService.instance.setDailySummaryEnabled(
        enabled,
        activeCount: activeCount,
      );
      if (mounted) {
        setState(() {
          _dailySummaryEnabled = enabled;
          _updatingDailySummary = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _updatingDailySummary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyNotificationError(error))),
        );
      }
    }
  }

  Future<void> _setReminderMinutesBefore(int minutes) async {
    setState(() => _updatingReminderTime = true);
    try {
      await NotificationService.instance.setReminderMinutesBefore(minutes);
      if (mounted) setState(() => _reminderMinutesBefore = minutes);
    } catch (error) {
      _showMessage('Waktu pengingat gagal diubah: $error');
      if (mounted) {
        setState(
          () => _reminderMinutesBefore =
              NotificationService.instance.reminderMinutesBefore,
        );
      }
    } finally {
      if (mounted) setState(() => _updatingReminderTime = false);
    }
  }

  Future<void> _setWeeklySummary(bool enabled) async {
    setState(() => _updatingWeeklySummary = true);
    try {
      await NotificationService.instance.setWeeklySummaryEnabled(enabled);
      if (mounted) {
        setState(() {
          _weeklySummaryEnabled = enabled;
          _updatingWeeklySummary = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _updatingWeeklySummary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyNotificationError(error))),
        );
      }
    }
  }

  /// Hitung jumlah tugas yang memakai kategori [id].
  int _usageCount(TaskProvider p, String id) =>
      p.allTasks.where((t) => t.categoryIdRef == id).length;

  // ============================================================
  // DIALOG TAMBAH/EDIT KATEGORI
  // ============================================================
  Future<void> _showCategoryDialog(
    BuildContext context, {
    Category? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int selectedColor = existing?.colorValue ?? kCategoryColors.first;
    String selectedIcon = existing?.iconName ?? kCategoryIcons.first.$1;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Kategori' : 'Edit Kategori'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- NAMA ----------
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                ),
                const SizedBox(height: 16),
                // ---------- PILIH WARNA ----------
                Text('Warna', style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCategoryColors
                      .map(
                        (color) => GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(width: 3, color: Colors.white)
                                  : null,
                              boxShadow: selectedColor == color
                                  ? [
                                      BoxShadow(
                                        color: Color(
                                          color,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selectedColor == color
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                // ---------- PILIH IKON ----------
                Text('Ikon', style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: kCategoryIcons.length,
                    itemBuilder: (ctx, i) {
                      final (iconName, iconData) = kCategoryIcons[i];
                      final selected = selectedIcon == iconName;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = iconName),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? Color(selectedColor).withValues(alpha: 0.2)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: selected
                                ? Border.all(color: Color(selectedColor))
                                : null,
                          ),
                          child: Icon(
                            iconData,
                            size: 20,
                            color: selected
                                ? Color(selectedColor)
                                : Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final provider = ctx.read<CategoryProvider>();
                if (existing == null) {
                  await provider.save(
                    Category.create(
                      name: name,
                      colorValue: selectedColor,
                      iconName: selectedIcon,
                    ),
                  );
                } else {
                  await provider.save(
                    existing.copyWith(
                      name: name,
                      colorValue: selectedColor,
                      iconName: selectedIcon,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// KARTU SEKSI PENGATURAN (pembungkus rapi)
// ============================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

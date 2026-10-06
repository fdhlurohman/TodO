// ============================================================
// PREMIUM TODO - ENTRY POINT
// Alur startup:
//  1. WidgetsFlutterBinding  -> wajib sebelum memakai plugin native
//  2. HiveRepository.init()  -> buka box Hive (tasks, categories, settings)
//  3. NotificationService.init() -> siapkan notifikasi lokal
//  4. Buat 4 provider: tema, kategori, tugas, pomodoro
//  5. Muat kategori dan tugas dari penyimpanan
//  6. runApp -> pilihan onboarding, lalu MaterialApp bertema
// ============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:premium_todo/core/theme/app_theme.dart';
import 'package:premium_todo/data/hive_repository.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/pomodoro_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/providers/theme_provider.dart';
import 'package:premium_todo/screens/first_run_screen.dart';
import 'package:premium_todo/screens/task_form_screen.dart';
import 'package:premium_todo/services/notification_service.dart';

Future<void> main() async {
  // Pastikan binding siap sebelum memakai plugin (Hive, notifikasi).
  WidgetsFlutterBinding.ensureInitialized();

  // ---------- 1. DATABASE LOKAL (HIVE) ----------
  final repo = HiveRepository.instance;
  await repo.init();

  // ---------- 2. PROVIDERS (STATE MANAGEMENT) ----------
  final themeProvider = ThemeProvider(repo);
  final categoryProvider = CategoryProvider(repo);
  final taskProvider = TaskProvider(repo);
  final pomodoroProvider = PomodoroProvider(NotificationService.instance);

  // Muat data dari Hive (paralel agar startup cepat).
  await Future.wait([
    categoryProvider.load(),
    taskProvider.load(),
  ]);
  runApp(PremiumTodoApp(
    themeProvider: themeProvider,
    categoryProvider: categoryProvider,
    taskProvider: taskProvider,
    pomodoroProvider: pomodoroProvider,
  ));

  unawaited(_initializeNotifications(repo, taskProvider));
}

Future<void> _initializeNotifications(
  HiveRepository repository,
  TaskProvider taskProvider,
) async {
  try {
    final notifications = NotificationService.instance;
    await notifications.init(repository: repository);
    await notifications.restoreNotificationSchedules();
    await taskProvider.syncNotificationSchedules();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        context: ErrorDescription('Menginisialisasi notifikasi aplikasi'),
      ),
    );
  }
}

// ============================================================
// ROOT WIDGET APLIKASI
// Mendaftarkan semua provider agar bisa diakses dari layar mana pun
// via context.watch<T>() / context.read<T>().
// ============================================================
class PremiumTodoApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final CategoryProvider categoryProvider;
  final TaskProvider taskProvider;
  final PomodoroProvider pomodoroProvider;

  const PremiumTodoApp({
    super.key,
    required this.themeProvider,
    required this.categoryProvider,
    required this.taskProvider,
    required this.pomodoroProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: taskProvider),
        ChangeNotifierProvider.value(value: pomodoroProvider),
      ],
      child: const _AppView(),
    );
  }
}

/// Widget terpisah agar MaterialApp hanya rebuild saat TEMA berubah
/// (bukan saat state tugas/pomodoro berubah) - performa lebih baik.
class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'TodO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Mode mengikuti preferensi pengguna yang tersimpan di Hive.
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const FirstRunScreen(),
      // Rute form tugas (dipakai dari beranda/kalender).
      routes: {
        '/task-form': (_) => const TaskFormScreen(),
      },
    );
  }
}

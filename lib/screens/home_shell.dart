// ============================================================
// LAYAR: HOME SHELL (NAVIGASI UTAMA)
// Kerangka aplikasi dengan NavigationBar 4 tab:
//   Beranda | Kalender | Analitik | Pengaturan
// Fab "+". Dipakai dari layar mana pun lewat rootNavigator.
// ============================================================
import 'package:flutter/material.dart';
import 'package:premium_todo/screens/home_screen.dart';
import 'package:premium_todo/screens/calendar_screen.dart';
import 'package:premium_todo/screens/analytics_screen.dart';
import 'package:premium_todo/screens/settings_screen.dart';
import 'package:premium_todo/screens/task_form_screen.dart';
import 'package:premium_todo/widgets/app_logo.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Daftar layar untuk tiap tab (IndexedStack menjaga state).
  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32), // logo kustom dari assets/logo/
            const SizedBox(width: 10),
            Text(
              'TodO',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analitik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

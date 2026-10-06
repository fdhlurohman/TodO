// ============================================================
// WIDGET TEST: SMOKE & COMPONENT TEST
// Memastikan komponen UI utama dan branding aplikasi TodO
// berjalan dengan baik tanpa error.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_todo/core/theme/app_theme.dart';
import 'package:premium_todo/models/task_priority.dart';
import 'package:premium_todo/widgets/app_logo.dart';
import 'package:premium_todo/widgets/priority_badge.dart';
import 'package:premium_todo/widgets/stat_card.dart';

void main() {
  testWidgets('AppLogo menampilkan ikon fallback dengan rapi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo(size: 40),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('PriorityBadge menampilkan teks dan ikon prioritas yang sesuai',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              PriorityBadge(priority: TaskPriority.high),
              PriorityBadge(priority: TaskPriority.medium),
              PriorityBadge(priority: TaskPriority.low),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tinggi'), findsOneWidget);
    expect(find.text('Sedang'), findsOneWidget);
    expect(find.text('Rendah'), findsOneWidget);
  });

  testWidgets('StatCard menampilkan angka statistik dan label dengan benar',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: StatCard(
            icon: Icons.checklist_rounded,
            value: 12,
            label: 'Aktif',
            color: Color(0xFF4F46E5),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
  });
}

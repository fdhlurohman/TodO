import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_todo/providers/category_provider.dart';
import 'package:premium_todo/providers/task_provider.dart';
import 'package:premium_todo/screens/home_shell.dart';
import 'package:premium_todo/widgets/app_logo.dart';

class FirstRunScreen extends StatefulWidget {
  final bool forceTutorial;

  const FirstRunScreen({super.key, this.forceTutorial = false});

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  static const _tutorialSteps = [
    _TutorialStep(
      icon: Icons.checklist_rounded,
      title: 'Semua tugas, lebih teratur',
      description:
          'Beranda menampilkan tugas yang perlu kamu kerjakan. Ketuk lingkaran '
          'di samping tugas untuk menandainya selesai.',
    ),
    _TutorialStep(
      icon: Icons.add_task_rounded,
      title: 'Buat tugas dengan mudah',
      description:
          'Tekan tombol +. Isi detail tugas tahap demi tahap, lalu pilih '
          'kategori, prioritas, deadline, pengingat, dan sub-tugas bila perlu.',
    ),
    _TutorialStep(
      icon: Icons.calendar_month_rounded,
      title: 'Pantau jadwal dan progres',
      description:
          'Gunakan tab Kalender untuk melihat deadline. Tab Analitik membantu '
          'kamu melihat perkembangan tugas.',
    ),
    _TutorialStep(
      icon: Icons.tune_rounded,
      title: 'Sesuaikan dengan kebiasaanmu',
      description:
          'Atur kategori dan tema di Pengaturan. Kamu juga bisa memakai '
          'Pomodoro untuk sesi fokus dan mengaktifkan pengingat tugas.',
    ),
  ];

  final PageController _pageController = PageController();
  int _tutorialPage = 0;
  bool _isSavingChoice = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    if (widget.forceTutorial || taskProvider.needsTutorial) {
      return _buildTutorial();
    }
    if (taskProvider.needsOnboarding) return _buildStartChoice();
    return const HomeShell();
  }

  Widget _buildTutorial() {
    final theme = Theme.of(context);
    final isLastPage = _tutorialPage == _tutorialSteps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 36),
                      const SizedBox(width: 10),
                      Text(
                        'Panduan TodO',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isSavingChoice ? null : _finishTutorial,
                        child: const Text('Lewati'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_tutorialPage + 1) / _tutorialSteps.length,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _tutorialSteps.length,
                      onPageChanged: (page) =>
                          setState(() => _tutorialPage = page),
                      itemBuilder: (context, index) =>
                          _buildTutorialPage(_tutorialSteps[index]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _tutorialSteps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _tutorialPage ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _tutorialPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_tutorialPage > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSavingChoice
                                ? null
                                : () => _goToTutorialPage(_tutorialPage - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Kembali'),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSavingChoice
                              ? null
                              : isLastPage
                                  ? _finishTutorial
                                  : () => _goToTutorialPage(_tutorialPage + 1),
                          icon: Icon(
                            isLastPage
                                ? Icons.arrow_forward_rounded
                                : Icons.navigate_next_rounded,
                          ),
                          label: Text(
                            isLastPage ? 'Lanjutkan' : 'Berikutnya',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialPage(_TutorialStep step) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 62,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStartChoice() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 72),
                  const SizedBox(height: 20),
                  Text(
                    'Selamat datang di TodO',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih cara memulai. Kamu bisa mencoba contoh tugas '
                    'atau langsung membuat daftarmu sendiri.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSavingChoice
                          ? null
                          : () => _completeOnboarding(
                                context,
                                includeSampleTasks: true,
                              ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Coba dengan tugas contoh'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSavingChoice
                          ? null
                          : () => _completeOnboarding(
                                context,
                                includeSampleTasks: false,
                              ),
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Mulai dengan daftar kosong'),
                    ),
                  ),
                  if (_isSavingChoice) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _goToTutorialPage(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finishTutorial() async {
    setState(() => _isSavingChoice = true);
    try {
      await context.read<TaskProvider>().completeTutorial();
      if (mounted) {
        if (widget.forceTutorial) {
          Navigator.of(context).pop();
        } else {
          setState(() => _isSavingChoice = false);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSavingChoice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Panduan gagal disimpan: $error')),
        );
      }
    }
  }

  Future<void> _completeOnboarding(
    BuildContext context, {
    required bool includeSampleTasks,
  }) async {
    setState(() => _isSavingChoice = true);
    try {
      await context.read<TaskProvider>().completeOnboarding(
            categories: context.read<CategoryProvider>().categories,
            includeSampleTasks: includeSampleTasks,
          );
    } catch (error) {
      if (context.mounted) {
        setState(() => _isSavingChoice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat menyimpan pilihan: $error')),
        );
      }
    }
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

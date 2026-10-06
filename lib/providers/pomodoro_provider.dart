// ============================================================
// PROVIDER: POMODORO FOCUS TIMER
// Siklus standar: 4 sesi fokus, tiap sesi diikuti istirahat:
//   Fokus 25 mnt -> Istirahat 5 mnt (x4)
// Setelah 4 sesi -> istirahat panjang 15 mnt.
// Timer berjalan dengan Timer.periodic (tetap jalan meski UI
// rebuild). Notifikasi muncul saat fase berganti.
// ============================================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:premium_todo/services/notification_service.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

extension PomodoroPhaseX on PomodoroPhase {
  String get label {
    switch (this) {
      case PomodoroPhase.focus:
        return 'Fokus';
      case PomodoroPhase.shortBreak:
        return 'Istirahat';
      case PomodoroPhase.longBreak:
        return 'Istirahat Panjang';
    }
  }
}

class PomodoroProvider extends ChangeNotifier {
  final NotificationService _notif;

  PomodoroProvider(this._notif);

  // ---------------- KONFIGURASI (bisa diubah dari UI) ----------------
  int focusMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;

  // ---------------- STATE ----------------
  PomodoroPhase _phase = PomodoroPhase.focus;
  int _remainingSeconds = 25 * 60; // sisa detik fase aktif
  int _completedFocusSessions = 0;
  Timer? _timer;
  bool _isRunning = false;

  // ---------------- GETTER ----------------
  PomodoroPhase get phase => _phase;
  bool get isRunning => _isRunning;
  int get completedFocusSessions => _completedFocusSessions;
  int get remainingSeconds => _remainingSeconds;

  /// Total detik durasi fase aktif (untuk progress ring).
  int get phaseDuration {
    switch (_phase) {
      case PomodoroPhase.focus:
        return focusMinutes * 60;
      case PomodoroPhase.shortBreak:
        return shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return longBreakMinutes * 60;
    }
  }

  /// Progres fase 0.0 - 1.0 (untuk ring progress).
  double get progress => 1 - (_remainingSeconds / phaseDuration);

  /// Format waktu "MM:SS".
  String get timeLabel {
    final m = (_remainingSeconds / 60).floor();
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---------------- KONTROL TIMER ----------------
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Reset fase aktif ke durasi penuh, timer berhenti.
  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = phaseDuration;
    notifyListeners();
  }

  /// Lewati ke fase berikutnya sekarang.
  void skipPhase() {
    _timer?.cancel();
    _advancePhase(completedNaturally: false);
  }

  /// Satu detik berlalu.
  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _advancePhase(completedNaturally: true);
    }
  }

  /// Tampilkan notifikasi tanpa menghentikan timer bila gagal
  /// (mis. izin notifikasi belum diberikan).
  void _notify({
    required int id,
    required String title,
    required String body,
  }) {
    _notif
        .showInstantNotification(id: id, title: title, body: body)
        .catchError((Object error) {
      debugPrint('Notifikasi pomodoro gagal: $error');
    });
  }

  /// Ganti fase: fokus selesai -> istirahat; istirahat selesai -> fokus.
  void _advancePhase({required bool completedNaturally}) {
    _timer?.cancel();
    _isRunning = false;

    switch (_phase) {
      case PomodoroPhase.focus:
        if (completedNaturally) _completedFocusSessions++;
        final isLongBreak = _completedFocusSessions > 0 &&
            _completedFocusSessions % sessionsBeforeLongBreak == 0;
        _phase =
            isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
        // Notifikasi: sesi fokus selesai
        _notify(
          id: 1001,
          title: '🍅 Sesi fokus selesai!',
          body: isLongBreak
              ? 'Saatnya istirahat panjang $longBreakMinutes menit.'
              : 'Saatnya istirahat $shortBreakMinutes menit.',
        );
        break;
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        _phase = PomodoroPhase.focus;
        _notify(
          id: 1002,
          title: '⏰ Istirahat selesai',
          body: 'Ayo kembali fokus selama $focusMinutes menit!',
        );
        break;
    }

    _remainingSeconds = phaseDuration;
    notifyListeners();
  }

  /// Ubah durasi fokus (dari layar Pomodoro) dan reset timer bila idle.
  void setFocusMinutes(int minutes) {
    focusMinutes = minutes.clamp(1, 120);
    if (_phase == PomodoroPhase.focus && !_isRunning) {
      _remainingSeconds = phaseDuration;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

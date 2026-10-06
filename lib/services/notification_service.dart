// ============================================================
// LAYANAN NOTIFIKASI LOKAL (flutter_local_notifications)
// Fitur:
//  - Inisialisasi plugin + channel Android "reminders"
//  - Minta izin POST_NOTIFICATIONS (Android 13+)
//  - showInstantNotification  : notifikasi langsung
//  - scheduleTaskReminder     : pengingat deadline tugas
//  - cancelTaskReminder       : batalkan pengingat tugas
//  - scheduleDailySummary     : ringkasan harian (daily repeat)
//  - scheduleWeeklySummary    : ringkasan mingguan (weekly repeat)
// ============================================================
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:premium_todo/data/task_repository.dart';
import 'package:premium_todo/models/task.dart';
import 'package:premium_todo/services/task_notification_manager.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService implements TaskNotificationManager {
  static const _supportedReminderIntervals = {5, 10, 15, 30, 60};
  static const _soundPickerChannel = MethodChannel(
    'my.id.fads.todo/notification_sound_picker',
  );

  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initialization;
  TaskRepository? _repository;

  bool dailySummaryEnabled = false;
  bool weeklySummaryEnabled = false;
  @override
  bool taskRemindersEnabled = true;
  String notificationSoundMode = 'builtIn';
  String? notificationSoundUri;
  String? notificationSoundName;
  bool soundSelectionRecovered = false;
  bool get notificationSoundEnabled => notificationSoundMode != 'silent';
  bool _changingNotificationSound = false;
  @override
  int reminderMinutesBefore = 15;

  /// Inisialisasi plugin + channel Android "reminders".
  /// Dipanggil sekali setelah UI utama ditampilkan.
  Future<void> init({required TaskRepository repository}) {
    _repository = repository;
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _loadSettingValues();

    // ---- Siapkan zona waktu perangkat ----
    tzdata.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));

    // ---- Pengaturan inisialisasi per platform ----
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    await _recoverUnavailableDeviceSound();
  }

  Future<void> _recoverUnavailableDeviceSound() async {
    if (notificationSoundMode != 'device' || notificationSoundUri == null) {
      return;
    }
    try {
      final canRead = await _soundPickerChannel.invokeMethod<bool>(
        'canReadAudioUri',
        {'uri': notificationSoundUri},
      );
      if (canRead == true) {
        await _createCurrentNotificationChannel();
        return;
      }
    } on PlatformException {
      // A revoked document-provider grant should not break all notifications.
    }

    notificationSoundMode = 'builtIn';
    notificationSoundUri = null;
    notificationSoundName = null;
    soundSelectionRecovered = true;
    await _repository!.setSetting('notificationSoundMode', 'builtIn');
    await _repository!.setSetting('notificationSoundUri', null);
    await _repository!.setSetting('notificationSoundName', null);
    await _repository!.setSetting('notificationSoundEnabled', true);
    await _createCurrentNotificationChannel();
  }

  void _loadSettingValues() {
    dailySummaryEnabled =
        _repository!.getSetting<bool>('dailySummaryEnabled') ?? false;
    weeklySummaryEnabled =
        _repository!.getSetting<bool>('weeklySummaryEnabled') ?? false;
    taskRemindersEnabled =
        _repository!.getSetting<bool>('taskRemindersEnabled') ?? true;
    final storedSoundMode = _repository!.getSetting<String>(
      'notificationSoundMode',
    );
    notificationSoundMode =
        storedSoundMode ??
        (_repository!.getSetting<bool>('notificationSoundEnabled') == false
            ? 'silent'
            : 'builtIn');
    if (!{'builtIn', 'device', 'silent'}.contains(notificationSoundMode)) {
      notificationSoundMode = 'builtIn';
    }
    notificationSoundUri = _repository!.getSetting<String>(
      'notificationSoundUri',
    );
    notificationSoundName = _repository!.getSetting<String>(
      'notificationSoundName',
    );
    if (notificationSoundMode == 'device' &&
        (notificationSoundUri == null || notificationSoundUri!.isEmpty)) {
      notificationSoundMode = 'builtIn';
    }
    final savedReminderMinutes =
        _repository!.getSetting<int>('reminderMinutesBefore') ?? 15;
    reminderMinutesBefore =
        _supportedReminderIntervals.contains(savedReminderMinutes)
        ? savedReminderMinutes
        : 15;
  }

  Future<void> restoreNotificationSchedules() async {
    await _ensureInitialized();
    if (dailySummaryEnabled) {
      final activeCount =
          _repository?.getAllTasks().where((task) {
            return !task.isCompleted;
          }).length ??
          0;
      await scheduleDailySummary(activeCount);
    }
    if (weeklySummaryEnabled) {
      await scheduleWeeklySummary();
    }
  }

  Future<void> reloadSettings() async {
    await loadSettings();
    final repository = _repository!;
    if (dailySummaryEnabled) {
      final activeCount = repository
          .getAllTasks()
          .where((task) => !task.isCompleted)
          .length;
      await scheduleDailySummary(activeCount);
    } else {
      await _plugin.cancel(2001);
    }
    if (weeklySummaryEnabled) {
      await scheduleWeeklySummary();
    } else {
      await _plugin.cancel(2002);
    }
  }

  Future<void> loadSettings() async {
    await _ensureInitialized();
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    _loadSettingValues();
  }

  Future<void> _ensureInitialized() async {
    final initialization = _initialization;
    if (initialization == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    await initialization;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final canScheduleExact = await androidPlugin
        .canScheduleExactNotifications();
    return canScheduleExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Minta izin POST_NOTIFICATIONS di Android 13+.
  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidPlugin?.requestNotificationsPermission();
    if (granted == false) {
      throw const NotificationPermissionDeniedException();
    }
  }

  @override
  Future<void> requestNotificationPermission() async {
    await _ensureInitialized();
    await _requestPermissions();
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    await _ensureInitialized();
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    if (enabled) {
      await requestNotificationPermission();
    }
    await repository.setSetting('taskRemindersEnabled', enabled);
    taskRemindersEnabled = enabled;
    await _rescheduleTaskReminders();
  }

  Future<void> setNotificationSound({
    required String mode,
    String? uri,
    String? name,
  }) async {
    if (!{'builtIn', 'device', 'silent'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', 'Pilihan suara tidak tersedia');
    }
    if (mode == 'device' && (uri == null || uri.isEmpty)) {
      throw ArgumentError('URI suara perangkat wajib diisi.');
    }
    await _ensureInitialized();
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }

    if (mode == 'device') {
      final uriIsReadable = await _soundPickerChannel.invokeMethod<bool>(
        'canReadAudioUri',
        {'uri': uri},
      );
      if (uriIsReadable != true) {
        throw const FormatException(
          'TodO tidak dapat membaca file suara yang dipilih. '
          'Pilih file audio yang tersimpan di perangkat.',
        );
      }
    }

    final previousMode = notificationSoundMode;
    final previousUri = notificationSoundUri;
    final previousName = notificationSoundName;
    final previousChannelId = _soundChannelId;
    notificationSoundMode = mode;
    notificationSoundUri = mode == 'device' ? uri : null;
    notificationSoundName = mode == 'device' ? name : null;
    _changingNotificationSound = true;

    try {
      await _createCurrentNotificationChannel();
      await _rescheduleTaskReminders();
      await restoreNotificationSchedules();
      await repository.setSetting('notificationSoundMode', mode);
      await repository.setSetting(
        'notificationSoundUri',
        mode == 'device' ? uri : null,
      );
      await repository.setSetting(
        'notificationSoundName',
        mode == 'device' ? name : null,
      );
      await repository.setSetting('notificationSoundEnabled', mode != 'silent');
      _changingNotificationSound = false;

      if (previousChannelId != _soundChannelId) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.deleteNotificationChannel(previousChannelId);
      }
    } catch (error, stackTrace) {
      _changingNotificationSound = false;
      notificationSoundMode = previousMode;
      notificationSoundUri = previousUri;
      notificationSoundName = previousName;
      await repository.setSetting('notificationSoundMode', previousMode);
      await repository.setSetting('notificationSoundUri', previousUri);
      await repository.setSetting('notificationSoundName', previousName);
      await repository.setSetting(
        'notificationSoundEnabled',
        previousMode != 'silent',
      );
      try {
        await _rescheduleTaskReminders();
        await restoreNotificationSchedules();
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'Suara tidak dapat diterapkan ($error) dan jadwal suara '
            'sebelumnya gagal dipulihkan ($rollbackError).',
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _createCurrentNotificationChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _soundChannelId,
        'Pengingat TodO',
        description: 'Notifikasi pengingat deadline dan ringkasan tugas',
        importance: Importance.high,
        playSound: notificationSoundEnabled,
        sound: _androidNotificationSound,
        enableVibration: true,
      ),
    );
  }

  Future<bool> _recoverSoundAfterScheduleError(Object error) async {
    if (_changingNotificationSound ||
        notificationSoundMode != 'device' ||
        error is! PlatformException ||
        error.code != 'invalid_sound') {
      return false;
    }
    notificationSoundMode = 'builtIn';
    notificationSoundUri = null;
    notificationSoundName = null;
    soundSelectionRecovered = true;
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    await repository.setSetting('notificationSoundMode', 'builtIn');
    await repository.setSetting('notificationSoundUri', null);
    await repository.setSetting('notificationSoundName', null);
    await repository.setSetting('notificationSoundEnabled', true);
    await _createCurrentNotificationChannel();
    return true;
  }

  Future<void> setReminderMinutesBefore(int minutes) async {
    if (!_supportedReminderIntervals.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes', 'Pilihan tidak tersedia');
    }
    await _ensureInitialized();
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    await repository.setSetting('reminderMinutesBefore', minutes);
    reminderMinutesBefore = minutes;
    await _rescheduleTaskReminders();
  }

  Future<void> _rescheduleTaskReminders() async {
    final tasks = _repository?.getAllTasks() ?? const <Task>[];
    // Paralel agar cepat; kegagalan satu tugas tidak menghentikan lainnya.
    await Future.wait([
      for (final task in tasks) syncTaskReminder(task),
    ]);
  }

  // ---------------- DETAIL NOTIFIKASI ----------------
  /// Detail channel Android "reminders" dengan importance tinggi
  /// agar muncul sebagai heads-up notification.
  String get _soundChannelId {
    if (notificationSoundMode == 'silent') return 'reminders_silent_v6';
    if (notificationSoundMode == 'builtIn') return 'reminders_sound_builtin_v6';
    var hash = 0x811c9dc5;
    for (final unit in notificationSoundUri!.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 'reminders_sound_device_${hash.toRadixString(16)}_v6';
  }

  AndroidNotificationSound? get _androidNotificationSound {
    return switch (notificationSoundMode) {
      'builtIn' => const RawResourceAndroidNotificationSound('tooo_dooo'),
      'device' => UriAndroidNotificationSound(notificationSoundUri!),
      _ => null,
    };
  }

  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      _soundChannelId,
      'Pengingat TodO',
      channelDescription: 'Notifikasi pengingat deadline dan ringkasan tugas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: notificationSoundEnabled,
      sound: _androidNotificationSound,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(presentSound: notificationSoundEnabled),
  );

  NotificationDetails get _taskReminderDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      _soundChannelId,
      'Pengingat TodO',
      channelDescription: 'Notifikasi pengingat deadline dan ringkasan tugas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: notificationSoundEnabled,
      sound: _androidNotificationSound,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
      actions: const [
        AndroidNotificationAction('snooze_10_minutes', 'Tunda 10 menit'),
      ],
    ),
    iOS: DarwinNotificationDetails(presentSound: notificationSoundEnabled),
  );

  // ---------------- NOTIFIKASI LANGSUNG ----------------
  /// Tampilkan notifikasi sekarang juga (dipakai Pomodoro).
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    await _plugin.show(id, title, body, _details);
  }

  // ---------------- PENGINGAT DEADLINE TUGAS ----------------
  /// Jadwalkan notifikasi 15 menit sebelum [dueDate].
  /// ID stabil diturunkan dari [taskId] agar jadwal bisa dibatalkan
  /// setelah aplikasi dimulai ulang.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    await _ensureInitialized();
    final scheduled = taskReminderScheduleTime(
      dueDate,
      now: DateTime.now(),
      minutesBefore: reminderMinutesBefore,
    );
    if (scheduled == null) return;

    try {
      await _plugin.zonedSchedule(
        notificationIdForTask(taskId),
        '⏰ Pengingat tugas',
        title,
        tz.TZDateTime.from(scheduled, tz.local),
        _taskReminderDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: await _scheduleMode(),
        payload: taskId,
      );
    } on PlatformException catch (error) {
      if (!await _recoverSoundAfterScheduleError(error)) rethrow;
      await _plugin.zonedSchedule(
        notificationIdForTask(taskId),
        '⏰ Pengingat tugas',
        title,
        tz.TZDateTime.from(scheduled, tz.local),
        _taskReminderDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: await _scheduleMode(),
        payload: taskId,
      );
    }
  }

  @override
  Future<void> syncTaskReminder(Task task) async {
    await cancelTaskReminder(task.id);
    await _scheduleTaskReminderIfEnabled(task);
  }

  @override
  Future<void> syncTaskReminders(List<Task> tasks) async {
    await _ensureInitialized();
    final taskIds = tasks.map((task) => task.id).toSet();
    final pendingRequests = await _plugin.pendingNotificationRequests();

    for (final request in pendingRequests) {
      final taskId = request.payload;
      if (taskId != null &&
          (!taskIds.contains(taskId) ||
              request.id != notificationIdForTask(taskId))) {
        await _plugin.cancel(request.id);
      }
    }

    for (final task in tasks) {
      final reminderId = notificationIdForTask(task.id);
      await _plugin.cancel(reminderId);
      await _scheduleTaskReminderIfEnabled(task);
    }
  }

  Future<void> _scheduleTaskReminderIfEnabled(Task task) async {
    if (!taskRemindersEnabled ||
        !task.reminderEnabled ||
        task.isCompleted ||
        task.dueDate == null) {
      return;
    }
    await scheduleTaskReminder(
      taskId: task.id,
      title: task.title,
      dueDate: task.dueDate!,
    );
  }

  /// Batalkan pengingat untuk satu tugas.
  @override
  Future<void> cancelTaskReminder(String taskId) async {
    await _ensureInitialized();
    final stableId = notificationIdForTask(taskId);
    await _plugin.cancel(stableId);
    final pendingRequests = await _plugin.pendingNotificationRequests();
    for (final request in pendingRequests) {
      if (request.payload == taskId) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (response.actionId != 'snooze_10_minutes' ||
        response.id == null ||
        response.payload == null) {
      return;
    }
    Task? task;
    for (final candidate in _repository?.getAllTasks() ?? const <Task>[]) {
      if (candidate.id == response.payload) {
        task = candidate;
        break;
      }
    }
    if (task == null) return;
    await _snooze(response.id!, task.id, task.title);
  }

  Future<void> _snooze(int id, String taskId, String taskTitle) async {
    if (!taskRemindersEnabled) return;
    final scheduled = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 10));
    await _plugin.zonedSchedule(
      id,
      '⏰ Pengingat tugas',
      taskTitle,
      scheduled,
      _taskReminderDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: await _scheduleMode(),
      payload: taskId,
    );
  }

  Future<void> setDailySummaryEnabled(
    bool enabled, {
    required int activeCount,
  }) async {
    await _ensureInitialized();
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    if (enabled) {
      await _requestPermissions();
      await scheduleDailySummary(activeCount);
    } else {
      await _plugin.cancel(2001);
    }
    await repository.setSetting('dailySummaryEnabled', enabled);
    dailySummaryEnabled = enabled;
  }

  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    await _ensureInitialized();
    final repository = _repository;
    if (repository == null) {
      throw StateError('NotificationService belum diinisialisasi');
    }
    if (enabled) {
      await _requestPermissions();
      await scheduleWeeklySummary();
    } else {
      await _plugin.cancel(2002);
    }
    await repository.setSetting('weeklySummaryEnabled', enabled);
    weeklySummaryEnabled = enabled;
  }

  @override
  Future<void> refreshDailySummary(int activeCount) async {
    await _ensureInitialized();
    if (dailySummaryEnabled) {
      await scheduleDailySummary(activeCount);
    }
  }

  // ---------------- RINGKASAN HARIAN ----------------
  /// Notifikasi berulang setiap hari pukul 08:00 berisi jumlah
  /// tugas aktif. Dipanggil ulang setiap kali daftar tugas berubah
  /// agar jumlahnya selalu akurat.
  Future<void> scheduleDailySummary(int activeCount) async {
    await _ensureInitialized();
    final scheduled = _nextInstanceOf(8, 0);
    try {
      await _plugin.zonedSchedule(
        2001,
        '📅 Ringkasan hari ini',
        'Kamu punya $activeCount tugas aktif. Ayo mulai!',
        scheduled,
        _details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: await _scheduleMode(),
      );
    } on PlatformException catch (error) {
      if (!await _recoverSoundAfterScheduleError(error)) rethrow;
      await _plugin.zonedSchedule(
        2001,
        '📅 Ringkasan hari ini',
        'Kamu punya $activeCount tugas aktif. Ayo mulai!',
        scheduled,
        _details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: await _scheduleMode(),
      );
    }
  }

  // ---------------- RINGKASAN MINGGUAN ----------------
  /// Notifikasi berulang setiap Senin pukul 09:00.
  Future<void> scheduleWeeklySummary() async {
    await _ensureInitialized();
    final scheduled = _nextInstanceOfWeekday(DateTime.monday, 9, 0);
    try {
      await _plugin.zonedSchedule(
        2002,
        '🗓️ Tinjauan mingguan',
        'Lihat rekap produktivitas minggu ini di aplikasi!',
        scheduled,
        _details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: await _scheduleMode(),
      );
    } on PlatformException catch (error) {
      if (!await _recoverSoundAfterScheduleError(error)) rethrow;
      await _plugin.zonedSchedule(
        2002,
        '🗓️ Tinjauan mingguan',
        'Lihat rekap produktivitas minggu ini di aplikasi!',
        scheduled,
        _details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: await _scheduleMode(),
      );
    }
  }

  // ---------------- UTIL: HITUNG WAKTU JADWAL ----------------
  /// Instance berikutnya pada jam [hour]:[minute] (hari ini atau besok).
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Instance berikutnya pada hari [weekday] (Senin=1..Minggu=7),
  /// jam [hour]:[minute].
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOf(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

DateTime? taskReminderScheduleTime(
  DateTime dueDate, {
  required DateTime now,
  required int minutesBefore,
}) {
  if (!dueDate.isAfter(now)) return null;
  final reminderTime = dueDate.subtract(Duration(minutes: minutesBefore));
  return reminderTime.isAfter(now) ? reminderTime : dueDate;
}

class NotificationPermissionDeniedException implements Exception {
  const NotificationPermissionDeniedException();

  @override
  String toString() => 'Izin notifikasi tidak diberikan.';
}

int notificationIdForTask(String taskId) {
  var hash = 0x811C9DC5;
  for (final codeUnit in taskId.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
  }
  if (hash == 0) hash = 1;
  // Cegah tabrakan dengan ID pomodoro (1001/1002) dan ringkasan
  // harian/mingguan (2001/2002) dengan offset ke atas bila bentrok.
  const reservedIds = {0, 999, 1001, 1002, 2001, 2002};
  if (reservedIds.contains(hash)) hash++;
  return hash;
}

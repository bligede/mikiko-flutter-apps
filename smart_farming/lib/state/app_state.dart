import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/soil_measurement.dart';
import '../services/demo_storage.dart';
import '../services/demo_codec.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';

/// Pusat state aplikasi (memakai `provider`).
///
/// Semua layar membaca data dari sini. Saat backend nyata siap, cukup ganti
/// isi method yang bertanda `// TODO(api)` dengan pemanggilan HTTP.
class AppState extends ChangeNotifier {
  AppState(
      {DemoStorage? storage, DateTime Function()? clock, this.backendNotice})
      : _storage = storage,
        _clock = clock ?? DateTime.now {
    _farms = MockData.farms();
    _selectedFarmId = _farms.first.id;
    _schedules = MockData.schedules();
    _tasks = MockData.tasks();
    _alerts = MockData.initialAlerts();
    _irrigationLogs = MockData.irrigationLogs();
    _seedChat();
    _measurements = _farms
        .map((f) => _sample(f, 'Zona A', 'Titik 1', 'Baseline demo'))
        .toList();
    _restore();
    if (storage is CloudDemoStorage) {
      _cloudChanges = storage.changes.listen((_) {
        if (!_disposed) super.notifyListeners();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  AppUser? _user;
  late List<Farm> _farms;
  late String _selectedFarmId;
  late List<IrrigationSchedule> _schedules;
  late List<PlantTask> _tasks;
  late List<AlertItem> _alerts;
  late List<IrrigationLog> _irrigationLogs;
  final List<ChatMessage> _chat = <ChatMessage>[];
  final DemoStorage? _storage;
  final String? backendNotice;
  StreamSubscription<void>? _cloudChanges;
  bool get cloudEnabled => _storage is CloudDemoStorage;
  String? get cloudProjectId => _storage is CloudDemoStorage
      ? _storage.projectId
      : null;
  String? get cloudUserId => _storage is CloudDemoStorage
      ? _storage.userId
      : null;
  int get pendingCloudWrites => _storage is CloudDemoStorage
      ? _storage.pendingWrites
      : 0;
  String? get cloudSyncError => _storage is CloudDemoStorage
      ? _storage.syncError
      : backendNotice;

  Future<void> synchronizeCloud() async {
    await flush();
    final storage = _storage;
    if (storage is CloudDemoStorage) await storage.synchronize();
    if (!_disposed) super.notifyListeners();
  }

  final DateTime Function() _clock;
  Future<void> _pendingSave = Future<void>.value();
  bool _disposed = false;
  bool storageError = false;
  late List<SoilMeasurement> _measurements;
  final Map<String, DateTime> _pumpDeadlines = {};
  final Map<String, DateTime> _cooldowns = {};
  final Map<String, List<bool>> _relays = {};
  final Map<String, DemoScenario> _scenarios = {};
  final Map<String, String> _scheduleRuns = {};
  Timer? _controlTimer;

  DemoScenario get scenario =>
      _scenarios[selectedFarm.id] ?? DemoScenario.normal;
  bool get nodeOnline => scenario != DemoScenario.offline;
  bool get notificationsEnabled => _notificationsEnabled;
  bool _notificationsEnabled = true;
  List<SoilMeasurement> get measurements =>
      _measurements.where((m) => m.farmId == selectedFarm.id).toList()
        ..sort((a, b) => b.time.compareTo(a.time));
  DateTime? get pumpDeadline => _pumpDeadlines[selectedFarm.id];
  List<bool> get relayStates => List<bool>.unmodifiable([
        selectedFarm.pumpOn,
        ...(_relays[selectedFarm.id] ?? List<bool>.filled(7, false)),
      ]);

  final AiAssistantService ai = AiAssistantService();

  int _idCounter = 0;
  Timer? _timer;
  bool _busy = false;
  bool _liveData = true;
  ThemeMode _themeMode = ThemeMode.dark;

  // ---------------------------------------------------------------------------
  // Getter
  // ---------------------------------------------------------------------------

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  bool get liveData => _liveData;
  ThemeMode get themeMode => _themeMode;

  List<Farm> get farms => List<Farm>.unmodifiable(_farms);
  Farm get selectedFarm => _farms.firstWhere((f) => f.id == _selectedFarmId,
      orElse: () => _farms.first);

  List<IrrigationSchedule> get schedules => _schedules
      .where((s) => s.farmId == selectedFarm.id)
      .toList()
    ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

  List<PlantTask> get tasks {
    final list = _tasks.where((t) => t.farmId == selectedFarm.id).toList();
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return a.due.compareTo(b.due);
    });
    return list;
  }

  List<AlertItem> get alerts =>
      _alerts.where((a) => a.farmId == selectedFarm.id).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  List<AlertItem> get allAlerts => List<AlertItem>.unmodifiable(
      _alerts..sort((a, b) => b.time.compareTo(a.time)));

  int get unreadAlertCount => _alerts.where((a) => !a.read).length;

  List<IrrigationLog> get irrigationLogs =>
      _irrigationLogs.where((l) => l.farmId == selectedFarm.id).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  List<ChatMessage> get chat => List<ChatMessage>.unmodifiable(_chat);

  int get pendingTaskCount => _tasks.where((t) => !t.done).length;

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  void login({required String email, required String name}) {
    _user = AppUser(
      id: 'user-1',
      name: name.isEmpty ? 'Petani Hebat' : name,
      email: email.isEmpty ? 'demo@smartfarming.id' : email,
      role: UserRole.owner,
    );
    if (_liveData) startLive();
    _controlTimer ??=
        Timer.periodic(const Duration(seconds: 1), (_) => controlTick());
    notifyListeners();
  }

  void logout() {
    emergencyStop();
    _user = null;
    stopLive();
    _controlTimer?.cancel();
    _controlTimer = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Navigasi / tema
  // ---------------------------------------------------------------------------

  void selectFarm(String farmId) {
    if (_selectedFarmId == farmId) return;
    _selectedFarmId = farmId;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLiveData(bool value) {
    _liveData = value;
    if (value) {
      startLive();
    } else {
      stopLive();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Data live (simulasi sensor masuk tiap beberapa detik)
  // ---------------------------------------------------------------------------

  void startLive() {
    _timer ??=
        Timer.periodic(const Duration(seconds: 6), (_) => simulateTick());
  }

  void stopLive() {
    _timer?.cancel();
    _timer = null;
  }

  void suspend() {
    stopLive();
    _controlTimer?.cancel();
    _controlTimer = null;
  }

  void resume() {
    controlTick();
    if (!isLoggedIn) return;
    if (_liveData) startLive();
    _controlTimer ??=
        Timer.periodic(const Duration(seconds: 1), (_) => controlTick());
  }

  /// Menghasilkan satu siklus pembacaan sensor baru.
  ///
  /// Dipanggil otomatis oleh timer di [startLive], dan dipakai oleh test
  /// untuk memverifikasi logika irigasi tanpa menunggu waktu nyata.
  void simulateTick() {
    if (!_liveData) return;
    final rnd = Random();
    final now = DateTime.now();

    _farms = _farms.map((farm) {
      if (_scenarios[farm.id] == DemoScenario.offline) return farm;
      final metrics = <SensorType, SensorMetric>{};
      for (final type in kSensorOrder) {
        final current = farm.metric(type);
        final span = switch (type) {
          SensorType.soilMoisture => 1.4,
          SensorType.temperature => 0.4,
          SensorType.humidity => 0.8,
          SensorType.pressure => 0.3,
          SensorType.rain => 0.4,
        };
        var next = current.value + (rnd.nextDouble() - 0.5) * span;
        if (type == SensorType.soilMoisture && farm.pumpOn) next += 2.0;
        next = next.clamp(_floorOf(type), _ceilOf(type));
        next = double.parse(next.toStringAsFixed(1));

        final history = <TimePoint>[...current.history, TimePoint(now, next)];
        history.removeWhere(
            (p) => p.time.isBefore(now.subtract(const Duration(hours: 24))));
        while (history.length > 1440) {
          history.removeAt(0);
        }
        metrics[type] =
            current.copyWith(value: next, history: history, updatedAt: now);
      }
      var updated = farm.copyWith(metrics: metrics, lastSync: now);
      updated = _applyAutoIrrigation(updated);
      _checkLowMoisture(updated);
      return updated;
    }).toList();

    notifyListeners();
  }

  double _floorOf(SensorType type) => switch (type) {
        SensorType.soilMoisture => 5,
        SensorType.temperature => 12,
        SensorType.humidity => 25,
        SensorType.pressure => 995,
        SensorType.rain => 0,
      };

  double _ceilOf(SensorType type) => switch (type) {
        SensorType.soilMoisture => 95,
        SensorType.temperature => 42,
        SensorType.humidity => 98,
        SensorType.pressure => 1025,
        SensorType.rain => 25,
      };

  /// Logika irigasi otomatis: nyalakan pompa bila tanah di bawah ambang,
  /// matikan bila sudah cukup basah.
  Farm _applyAutoIrrigation(Farm farm) {
    if (!farm.autoIrrigation) return farm;
    if (_scenarios[farm.id] == DemoScenario.offline || farm.rain > 5) {
      _stopPump(farm.id);
      return farm.copyWith(pumpOn: false);
    }
    final moisture = farm.soilMoisture;
    if (!farm.pumpOn &&
        moisture < farm.moistureThreshold &&
        !(_cooldowns[farm.id]?.isAfter(_clock()) ?? false)) {
      _armPump(farm, farm.irrigationDurationMinutes);
      _addLog(farm, 'Otomatis');
      _pushAlert(
        AlertItem(
          id: _newId('alert'),
          farmId: farm.id,
          title: 'Irigasi otomatis aktif',
          message: 'Kelembapan tanah ${moisture.toStringAsFixed(0)}% < ambang '
              '${farm.moistureThreshold.toStringAsFixed(0)}%. Pompa dinyalakan '
              'selama ${farm.irrigationDurationMinutes} menit.',
          level: AlertLevel.warning,
          time: DateTime.now(),
        ),
      );
      return farm.copyWith(pumpOn: true);
    }
    if (farm.pumpOn && moisture > farm.moistureThreshold + 15) {
      _stopPump(farm.id);
      return farm.copyWith(pumpOn: false);
    }
    return farm;
  }

  void _checkLowMoisture(Farm farm) {
    if (farm.soilMoisture >= farm.moistureThreshold) return;
    if (farm.autoIrrigation) return; // sudah ditangani irigasi otomatis
    final already = _alerts.any(
        (a) => a.farmId == farm.id && !a.read && a.title == 'Tanah kering');
    if (already) return;
    _pushAlert(
      AlertItem(
        id: _newId('alert'),
        farmId: farm.id,
        title: 'Tanah kering',
        message:
            'Kelembapan tanah ${farm.soilMoisture.toStringAsFixed(0)}% di bawah '
            'ambang ${farm.moistureThreshold.toStringAsFixed(0)}%. Pertimbangkan menyiram.',
        level: AlertLevel.warning,
        time: DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Irigasi
  // ---------------------------------------------------------------------------

  void togglePump() {
    if (!selectedFarm.pumpOn) {
      runIrrigation();
      return;
    }
    final farm = selectedFarm;
    _stopPump(farm.id);
    _updateFarm(farm.copyWith(pumpOn: false, autoIrrigation: false));
    NotificationService.toast('Pompa dimatikan • mode manual');
  }

  void runIrrigation({int? minutes}) {
    final farm = selectedFarm;
    if (!nodeOnline) {
      NotificationService.toast(
          'Node offline. Pulihkan skenario sebelum menyiram.');
      return;
    }
    final duration = (minutes ?? farm.irrigationDurationMinutes).clamp(1, 30);
    _armPump(farm, duration);
    _updateFarm(farm.copyWith(pumpOn: true));
    _addLog(farm, 'Manual', minutes: duration);
    _pushAlert(
      AlertItem(
        id: _newId('alert'),
        farmId: farm.id,
        title: 'Penyiraman manual dimulai',
        message:
            'Pompa menyala ${minutes ?? farm.irrigationDurationMinutes} menit.',
        level: AlertLevel.info,
        time: DateTime.now(),
      ),
    );
    NotificationService.toast('Penyiraman dimulai…');
    notifyListeners();
  }

  void setAutoIrrigation(bool value) {
    _updateFarm(selectedFarm.copyWith(autoIrrigation: value));
  }

  void setMoistureThreshold(double value) {
    _updateFarm(selectedFarm.copyWith(moistureThreshold: value));
  }

  void setIrrigationDuration(double value) {
    _updateFarm(
        selectedFarm.copyWith(irrigationDurationMinutes: value.round()));
  }

  void _addLog(Farm farm, String trigger, {int? minutes}) {
    _irrigationLogs.add(
      IrrigationLog(
        id: _newId('log'),
        farmId: farm.id,
        time: DateTime.now(),
        durationMinutes: minutes ?? farm.irrigationDurationMinutes,
        trigger: trigger,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Jadwal
  // ---------------------------------------------------------------------------

  void toggleSchedule(String id) {
    _schedules = _schedules
        .map((s) => s.id == id ? s.copyWith(enabled: !s.enabled) : s)
        .toList();
    notifyListeners();
  }

  void addSchedule(IrrigationSchedule schedule) {
    _schedules = <IrrigationSchedule>[..._schedules, schedule];
    notifyListeners();
  }

  void removeSchedule(String id) {
    _schedules = _schedules.where((s) => s.id != id).toList();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Tugas perawatan
  // ---------------------------------------------------------------------------

  void toggleTask(String id) {
    _tasks =
        _tasks.map((t) => t.id == id ? t.copyWith(done: !t.done) : t).toList();
    notifyListeners();
  }

  void addTask(PlantTask task) {
    _tasks = <PlantTask>[..._tasks, task];
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lahan
  // ---------------------------------------------------------------------------

  void addFarm(
      {required String name, required String crop, required String location}) {
    final farm = Farm(
      id: _newId('farm'),
      name: name,
      location: location,
      crop: crop,
      areaHectare: 0.5,
      ownerName: _user?.name ?? 'Petani',
      members: <String>[_user?.name ?? 'Petani'],
      metrics: <SensorType, SensorMetric>{
        for (final type in kSensorOrder)
          type: SensorMetric(
            type: type,
            value: type == SensorType.pressure ? 1010 : 50,
            history: const <TimePoint>[],
            updatedAt: DateTime.now(),
          ),
      },
      pumpOn: false,
      autoIrrigation: false,
      moistureThreshold: 45,
      irrigationDurationMinutes: 10,
      lastSync: DateTime.now(),
    );
    _farms = <Farm>[..._farms, farm];
    _selectedFarmId = farm.id;
    NotificationService.toast('Lahan "$name" ditambahkan');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Peringatan
  // ---------------------------------------------------------------------------

  void markAlertRead(String id) {
    _alerts =
        _alerts.map((a) => a.id == id ? a.copyWith(read: true) : a).toList();
    notifyListeners();
  }

  void markAllAlertsRead() {
    _alerts = _alerts.map((a) => a.copyWith(read: true)).toList();
    notifyListeners();
  }

  void _pushAlert(AlertItem alert) {
    _alerts = <AlertItem>[alert, ..._alerts];
    if (_alerts.length > 200) _alerts.removeLast();
    if (_notificationsEnabled) NotificationService.show(alert);
  }

  // ---------------------------------------------------------------------------
  // Chatbot
  // ---------------------------------------------------------------------------

  void _seedChat() {
    _chat.add(
      ChatMessage(
        id: _newId('msg'),
        text:
            'Halo! Saya asisten AI smart farming Anda. Saya membaca data sensor '
            'secara langsung. Tanya soal kelembapan, irigasi, hama, atau jadwal perawatan.',
        fromUser: false,
        time: DateTime.now(),
      ),
    );
  }

  Future<void> sendChat(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _chat.add(
      ChatMessage(
          id: _newId('msg'),
          text: trimmed,
          fromUser: true,
          time: DateTime.now()),
    );
    _busy = true;
    notifyListeners();

    final reply = await ai.reply(trimmed, farm: selectedFarm);
    if (_disposed) return;

    _chat.add(
      ChatMessage(
          id: _newId('msg'),
          text: reply,
          fromUser: false,
          time: DateTime.now()),
    );
    _busy = false;
    notifyListeners();
  }

  void clearChat() {
    _chat.clear();
    _seedChat();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  void _updateFarm(Farm farm) {
    _farms = _farms.map((f) => f.id == farm.id ? farm : f).toList();
    notifyListeners();
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  void _armPump(Farm farm, int minutes) {
    _pumpDeadlines[farm.id] = _clock().add(Duration(minutes: minutes));
    _relays.putIfAbsent(farm.id, () => List<bool>.filled(7, false))[0] = true;
  }

  void _stopPump(String farmId) {
    _pumpDeadlines.remove(farmId);
    _cooldowns[farmId] = _clock().add(const Duration(minutes: 5));
    final relays = _relays[farmId];
    if (relays != null) {
      for (var i = 0; i < 6; i++) {
        relays[i] = false;
      }
    }
  }

  /// Foreground demo controller. Real scheduling belongs to Box 2 firmware.
  void controlTick() {
    if (_disposed) return;
    final now = _clock();
    var changed = false;
    _farms = _farms.map((f) {
      final deadline = _pumpDeadlines[f.id];
      if (f.pumpOn && deadline != null && !now.isBefore(deadline)) {
        _stopPump(f.id);
        changed = true;
        _pushAlert(AlertItem(
            id: _newId('alert'),
            farmId: f.id,
            title: 'Penyiraman selesai',
            message: 'Pompa berhenti karena durasi tercapai.',
            level: AlertLevel.info,
            time: now));
        return f.copyWith(pumpOn: false);
      }
      return f;
    }).toList();
    if (_user != null) {
      for (final s in _schedules) {
        final day = '${now.year}-${now.month}-${now.day}';
        if (!s.enabled ||
            s.hour != now.hour ||
            s.minute != now.minute ||
            (s.weekdays.isNotEmpty && !s.weekdays.contains(now.weekday)) ||
            _scheduleRuns[s.id] == day) {
          continue;
        }
        _scheduleRuns[s.id] = day;
        final f = _farms.firstWhere((f) => f.id == s.farmId);
        if (f.pumpOn ||
            f.rain > 5 ||
            _scenarios[f.id] == DemoScenario.offline) {
          continue;
        }
        _armPump(f, s.durationMinutes);
        _addLog(f, 'Jadwal', minutes: s.durationMinutes);
        _farms = _farms
            .map((x) => x.id == f.id ? x.copyWith(pumpOn: true) : x)
            .toList();
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void emergencyStop() {
    for (final f in _farms) {
      _stopPump(f.id);
    }
    _relays.clear();
    _farms = _farms
        .map((f) => f.copyWith(pumpOn: false, autoIrrigation: false))
        .toList();
    // Disable foreground schedules too, so STOP cannot be undone by a timer.
    _schedules = _schedules.map((s) => s.copyWith(enabled: false)).toList();
    notifyListeners();
  }

  bool setRelay(int channel, bool on) {
    if (channel < 0 || channel > 7) return false;
    if (channel == 0) {
      if (on != selectedFarm.pumpOn) togglePump();
      return selectedFarm.pumpOn == on;
    }
    if (on && (!nodeOnline || (channel < 7 && !selectedFarm.pumpOn))) {
      NotificationService.toast(
          'Nyalakan pompa terlebih dahulu; node harus online.');
      return false;
    }
    final outputs =
        _relays.putIfAbsent(selectedFarm.id, () => List<bool>.filled(7, false));
    if (on && ((channel == 4 && outputs[4]) || (channel == 5 && outputs[3]))) {
      NotificationService.toast(
          'Fertigasi A dan B tidak boleh aktif bersamaan.');
      return false;
    }
    outputs[channel - 1] = on;
    notifyListeners();
    return true;
  }

  void applyScenario(DemoScenario value) {
    final farm = selectedFarm;
    _scenarios[farm.id] = value;
    _cooldowns.remove(farm.id);
    final moisture = value == DemoScenario.dry
        ? 22.0
        : value == DemoScenario.rain
            ? 78.0
            : 62.0;
    final now = _clock();
    var updated = farm;
    if (value != DemoScenario.offline) {
      updated = farm.copyWith(lastSync: now, metrics: {
        ...farm.metrics,
        SensorType.soilMoisture: farm.metric(SensorType.soilMoisture).copyWith(
            value: moisture,
            updatedAt: now,
            history: [
              ...farm.metric(SensorType.soilMoisture).history,
              TimePoint(now, moisture)
            ]),
        SensorType.rain: farm.metric(SensorType.rain).copyWith(
            value: value == DemoScenario.rain ? 12 : 0, updatedAt: now),
      });
    }
    if (value == DemoScenario.offline || value == DemoScenario.rain) {
      _stopPump(farm.id);
      updated = updated.copyWith(pumpOn: false);
    }
    updated = _applyAutoIrrigation(updated);
    _checkLowMoisture(updated);
    _pushAlert(AlertItem(
        id: _newId('scenario'),
        farmId: farm.id,
        title: 'Skenario: ${value.label}',
        message: switch (value) {
          DemoScenario.normal =>
            'Pembacaan kembali normal. Node simulasi tersambung.',
          DemoScenario.dry =>
            'Kelembapan 22%. Aktifkan mode otomatis untuk melihat respons pompa.',
          DemoScenario.rain => 'Hujan 12 mm. Irigasi otomatis ditunda.',
          DemoScenario.offline =>
            'Telemetri node berhenti. Pompa demo dimatikan.',
        },
        level:
            value == DemoScenario.normal ? AlertLevel.info : AlertLevel.warning,
        time: now));
    _updateFarm(updated);
  }

  SoilMeasurement _sample(Farm farm, String plot, String point, String notes) {
    final r = Random();
    return SoilMeasurement(
        id: _newId('soil'),
        farmId: farm.id,
        plot: plot,
        point: point,
        time: _clock(),
        moisture: farm.soilMoisture,
        temperature: 23 + r.nextDouble() * 3,
        ph: 6.1 + r.nextDouble() * .6,
        ec: 710 + r.nextInt(140).toDouble(),
        nitrogen: 65 + r.nextInt(20),
        phosphorus: 28 + r.nextInt(12),
        potassium: 115 + r.nextInt(30),
        notes: notes);
  }

  SoilMeasurement measureSoil(
      {required String plot, required String point, String notes = ''}) {
    if (plot.trim().isEmpty || point.trim().isEmpty) {
      throw ArgumentError('Plot dan titik wajib diisi');
    }
    final measurement =
        _sample(selectedFarm, plot.trim(), point.trim(), notes.trim());
    _measurements.insert(0, measurement);
    if (_measurements.length > 300) _measurements.removeLast();
    notifyListeners();
    return measurement;
  }

  void setNotifications(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  Map<String, dynamic> _snapshot() => {
        'version': 1,
        'farms': _farms.map(DemoCodec.farm).toList(),
        'selected': _selectedFarmId,
        'dark': _themeMode == ThemeMode.dark,
        'live': _liveData,
        'notifications': _notificationsEnabled,
        'schedules': _schedules.map(DemoCodec.schedule).toList(),
        'tasks': _tasks.map(DemoCodec.task).toList(),
        'alerts': _alerts.map(DemoCodec.alert).toList(),
        'logs': _irrigationLogs.map(DemoCodec.log).toList(),
        'soil': _measurements.map((m) => m.toJson()).toList(),
        'runs': _scheduleRuns,
      };

  void _restore() {
    try {
      final raw = _storage?.read();
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['version'] != 1) return;
      final farms =
          (j['farms'] as List).map((x) => DemoCodec.readFarm(x)).toList();
      if (farms.isEmpty) return;
      final schedules = (j['schedules'] as List)
          .map((x) => DemoCodec.readSchedule(x))
          .toList();
      final tasks =
          (j['tasks'] as List).map((x) => DemoCodec.readTask(x)).toList();
      final alerts =
          (j['alerts'] as List).map((x) => DemoCodec.readAlert(x)).toList();
      final logs =
          (j['logs'] as List).map((x) => DemoCodec.readLog(x)).toList();
      final soil =
          (j['soil'] as List).map((x) => SoilMeasurement.fromJson(x)).toList();
      _farms = farms;
      _schedules = schedules;
      _tasks = tasks;
      _alerts = alerts;
      _irrigationLogs = logs;
      _measurements = soil;
      _selectedFarmId = j['selected'] as String;
      _themeMode = j['dark'] == true ? ThemeMode.dark : ThemeMode.light;
      _liveData = j['live'] != false;
      _notificationsEnabled = j['notifications'] != false;
      _scheduleRuns.addAll(Map<String, String>.from(j['runs'] ?? {}));
    } catch (_) {
      storageError = true;
    }
  }

  Future<void> flush() => _pendingSave;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
    if (_storage == null) return;
    final snapshot = jsonEncode(_snapshot());
    _pendingSave = _pendingSave
        .then((_) => _storage.write(snapshot))
        .catchError((Object _) {
      storageError = true;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _controlTimer?.cancel();
    _cloudChanges?.cancel();
    if (_storage is CloudDemoStorage) _storage.dispose();
    super.dispose();
  }
}

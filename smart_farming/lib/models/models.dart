import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Jenis sensor yang dibaca dari perangkat ESP32.
enum SensorType { soilMoisture, temperature, humidity, pressure, rain }

/// Urutan tampilan sensor di UI.
const List<SensorType> kSensorOrder = <SensorType>[
  SensorType.soilMoisture,
  SensorType.temperature,
  SensorType.humidity,
  SensorType.pressure,
  SensorType.rain,
];

extension SensorTypeInfo on SensorType {
  String get label => switch (this) {
        SensorType.soilMoisture => 'Kelembapan Tanah',
        SensorType.temperature => 'Suhu Udara',
        SensorType.humidity => 'Kelembapan Udara',
        SensorType.pressure => 'Tekanan Udara',
        SensorType.rain => 'Curah Hujan',
      };

  String get shortLabel => switch (this) {
        SensorType.soilMoisture => 'Tanah',
        SensorType.temperature => 'Suhu',
        SensorType.humidity => 'Lembap',
        SensorType.pressure => 'Tekanan',
        SensorType.rain => 'Hujan',
      };

  String get unit => switch (this) {
        SensorType.soilMoisture => '%',
        SensorType.temperature => '°C',
        SensorType.humidity => '%',
        SensorType.pressure => 'hPa',
        SensorType.rain => 'mm',
      };

  IconData get icon => switch (this) {
        SensorType.soilMoisture => Icons.water_drop_outlined,
        SensorType.temperature => Icons.thermostat,
        SensorType.humidity => Icons.opacity,
        SensorType.pressure => Icons.speed,
        SensorType.rain => Icons.grain,
      };

  /// Contoh perangkat keras yang dipakai di sisi ESP32.
  String get hardware => switch (this) {
        SensorType.soilMoisture => 'Sensor kelembapan tanah kapasitif/resistif',
        SensorType.temperature => 'BME280 — suhu',
        SensorType.humidity => 'BME280 — kelembapan',
        SensorType.pressure => 'BME280 — tekanan',
        SensorType.rain => 'Rain sensor analog/digital',
      };

  /// Satuan pembacaan mentah dari sensor sebelum dikonversi.
  String get rawHint => switch (this) {
        SensorType.soilMoisture => 'ADC 0–4095 → 0–100%',
        SensorType.temperature => 'I2C BME280',
        SensorType.humidity => 'I2C BME280',
        SensorType.pressure => 'I2C BME280',
        SensorType.rain => 'ADC 0–4095 → intensitas',
      };
}

/// Satu titik data pada deret waktu.
class TimePoint {
  const TimePoint(this.time, this.value);

  final DateTime time;
  final double value;
}

/// Nilai terkini + riwayat untuk satu sensor.
class SensorMetric {
  const SensorMetric({
    required this.type,
    required this.value,
    required this.history,
    required this.updatedAt,
  });

  final SensorType type;
  final double value;
  final List<TimePoint> history;
  final DateTime updatedAt;

  double get min =>
      history.isEmpty ? value : history.map((p) => p.value).reduce((a, b) => a < b ? a : b);

  double get max =>
      history.isEmpty ? value : history.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  double get average => history.isEmpty
      ? value
      : history.map((p) => p.value).reduce((a, b) => a + b) / history.length;

  SensorMetric copyWith({double? value, List<TimePoint>? history, DateTime? updatedAt}) {
    return SensorMetric(
      type: type,
      value: value ?? this.value,
      history: history ?? this.history,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Status kesehatan nilai sensor terhadap ambang batas.
enum MetricStatus { low, normal, high }

extension MetricStatusInfo on MetricStatus {
  String get label => switch (this) {
        MetricStatus.low => 'Rendah',
        MetricStatus.normal => 'Normal',
        MetricStatus.high => 'Tinggi',
      };

  Color get color => switch (this) {
        MetricStatus.low => Palette.danger,
        MetricStatus.normal => Palette.success,
        MetricStatus.high => Palette.warning,
      };

  IconData get icon => switch (this) {
        MetricStatus.low => Icons.arrow_downward,
        MetricStatus.normal => Icons.check,
        MetricStatus.high => Icons.arrow_upward,
      };
}

/// Satu lahan/kebun yang dikelola pengguna.
class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.crop,
    required this.areaHectare,
    required this.ownerName,
    required this.members,
    required this.metrics,
    required this.pumpOn,
    required this.autoIrrigation,
    required this.moistureThreshold,
    required this.irrigationDurationMinutes,
    required this.lastSync,
  });

  final String id;
  final String name;
  final String location;
  final String crop;
  final double areaHectare;
  final String ownerName;

  /// Nama anggota yang punya akses (multi-user).
  final List<String> members;
  final Map<SensorType, SensorMetric> metrics;
  final bool pumpOn;
  final bool autoIrrigation;

  /// Ambang batas kelembapan tanah (%) untuk menyalakan pompa otomatis.
  final double moistureThreshold;
  final int irrigationDurationMinutes;
  final DateTime lastSync;

  SensorMetric metric(SensorType type) =>
      metrics[type] ?? SensorMetric(type: type, value: 0, history: const [], updatedAt: lastSync);

  double get soilMoisture => metric(SensorType.soilMoisture).value;
  double get temperature => metric(SensorType.temperature).value;
  double get humidity => metric(SensorType.humidity).value;
  double get pressure => metric(SensorType.pressure).value;
  double get rain => metric(SensorType.rain).value;

  /// Skor kasar 0–100 dari kondisi sensor (dipakai di dasbor & analitik).
  int get healthScore {
    var score = 100.0;
    if (soilMoisture < moistureThreshold) {
      score -= (moistureThreshold - soilMoisture) * 1.5;
    }
    if (rain > 5) score -= 10;
    if (temperature > 34) score -= 8;
    return score.clamp(0, 100).round();
  }

  MetricStatus statusOf(SensorType type) {
    switch (type) {
      case SensorType.soilMoisture:
        if (value(type) < moistureThreshold) return MetricStatus.low;
        if (value(type) > 85) return MetricStatus.high;
        return MetricStatus.normal;
      case SensorType.temperature:
        if (value(type) > 34) return MetricStatus.high;
        if (value(type) < 18) return MetricStatus.low;
        return MetricStatus.normal;
      case SensorType.humidity:
        if (value(type) < 40) return MetricStatus.low;
        if (value(type) > 85) return MetricStatus.high;
        return MetricStatus.normal;
      case SensorType.pressure:
        if (value(type) < 1000) return MetricStatus.low;
        if (value(type) > 1020) return MetricStatus.high;
        return MetricStatus.normal;
      case SensorType.rain:
        if (value(type) > 10) return MetricStatus.high;
        if (value(type) > 1) return MetricStatus.normal;
        return MetricStatus.normal;
    }
  }

  double value(SensorType type) => metric(type).value;

  Farm copyWith({
    String? name,
    String? location,
    String? crop,
    double? areaHectare,
    List<String>? members,
    Map<SensorType, SensorMetric>? metrics,
    bool? pumpOn,
    bool? autoIrrigation,
    double? moistureThreshold,
    int? irrigationDurationMinutes,
    DateTime? lastSync,
  }) {
    return Farm(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      crop: crop ?? this.crop,
      areaHectare: areaHectare ?? this.areaHectare,
      ownerName: ownerName,
      members: members ?? this.members,
      metrics: metrics ?? this.metrics,
      pumpOn: pumpOn ?? this.pumpOn,
      autoIrrigation: autoIrrigation ?? this.autoIrrigation,
      moistureThreshold: moistureThreshold ?? this.moistureThreshold,
      irrigationDurationMinutes: irrigationDurationMinutes ?? this.irrigationDurationMinutes,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

/// Jadwal penyiraman berulang.
class IrrigationSchedule {
  const IrrigationSchedule({
    required this.id,
    required this.farmId,
    required this.label,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    required this.enabled,
    this.weekdays = const <int>{},
  });

  final String id;
  final String farmId;
  final String label;
  final int hour;
  final int minute;
  final int durationMinutes;
  final bool enabled;

  /// 1 = Senin … 7 = Minggu. Kosong berarti setiap hari.
  final Set<int> weekdays;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get dayLabel {
    if (weekdays.isEmpty || weekdays.length == 7) return 'Setiap hari';
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => names[(d - 1).clamp(0, 6)]).join(', ');
  }

  IrrigationSchedule copyWith({
    String? label,
    int? hour,
    int? minute,
    int? durationMinutes,
    bool? enabled,
    Set<int>? weekdays,
  }) {
    return IrrigationSchedule(
      id: id,
      farmId: farmId,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      enabled: enabled ?? this.enabled,
      weekdays: weekdays ?? this.weekdays,
    );
  }
}

/// Catatan satu kali penyiraman.
class IrrigationLog {
  const IrrigationLog({
    required this.id,
    required this.farmId,
    required this.time,
    required this.durationMinutes,
    required this.trigger,
  });

  final String id;
  final String farmId;
  final DateTime time;
  final int durationMinutes;
  final String trigger; // 'Manual', 'Otomatis', 'Jadwal'
}

enum TaskType { watering, fertilizing, pruning, pestControl, harvest, other }

extension TaskTypeInfo on TaskType {
  String get label => switch (this) {
        TaskType.watering => 'Penyiraman',
        TaskType.fertilizing => 'Pemupukan',
        TaskType.pruning => 'Pemangkasan',
        TaskType.pestControl => 'Pengendalian Hama',
        TaskType.harvest => 'Panen',
        TaskType.other => 'Lainnya',
      };

  IconData get icon => switch (this) {
        TaskType.watering => Icons.water_drop,
        TaskType.fertilizing => Icons.eco,
        TaskType.pruning => Icons.content_cut,
        TaskType.pestControl => Icons.bug_report_outlined,
        TaskType.harvest => Icons.agriculture,
        TaskType.other => Icons.task_alt,
      };
}

/// Tugas perawatan tanaman dengan tenggat waktu.
class PlantTask {
  const PlantTask({
    required this.id,
    required this.farmId,
    required this.title,
    required this.notes,
    required this.type,
    required this.due,
    this.done = false,
  });

  final String id;
  final String farmId;
  final String title;
  final String notes;
  final TaskType type;
  final DateTime due;
  final bool done;

  bool get isOverdue => !done && due.isBefore(DateTime.now());

  PlantTask copyWith({String? title, String? notes, TaskType? type, DateTime? due, bool? done}) {
    return PlantTask(
      id: id,
      farmId: farmId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      due: due ?? this.due,
      done: done ?? this.done,
    );
  }
}

enum AlertLevel { info, warning, critical }

extension AlertLevelInfo on AlertLevel {
  String get label => switch (this) {
        AlertLevel.info => 'Info',
        AlertLevel.warning => 'Perhatian',
        AlertLevel.critical => 'Kritis',
      };

  Color get color => switch (this) {
        AlertLevel.info => Palette.info,
        AlertLevel.warning => Palette.warning,
        AlertLevel.critical => Palette.danger,
      };

  IconData get icon => switch (this) {
        AlertLevel.info => Icons.info_outline,
        AlertLevel.warning => Icons.warning_amber_rounded,
        AlertLevel.critical => Icons.error_outline,
      };
}

/// Notifikasi/peringatan dalam aplikasi.
class AlertItem {
  const AlertItem({
    required this.id,
    required this.farmId,
    required this.title,
    required this.message,
    required this.level,
    required this.time,
    this.read = false,
  });

  final String id;
  final String farmId;
  final String title;
  final String message;
  final AlertLevel level;
  final DateTime time;
  final bool read;

  AlertItem copyWith({bool? read}) => AlertItem(
        id: id,
        farmId: farmId,
        title: title,
        message: message,
        level: level,
        time: time,
        read: read ?? this.read,
      );
}

/// Pesan pada percakapan chatbot AI.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.time,
  });

  final String id;
  final String text;
  final bool fromUser;
  final DateTime time;
}

enum UserRole { owner, worker }

extension UserRoleInfo on UserRole {
  String get label => switch (this) {
        UserRole.owner => 'Pemilik Lahan',
        UserRole.worker => 'Pekerja',
      };
}

/// Pengguna aplikasi (multi-user).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

import 'dart:math';

import '../models/models.dart';

/// Sumber data tiruan (dummy) untuk MVP.
///
/// Nanti kelas ini diganti oleh repository yang memanggil REST API
/// backend (XAMPP/Docker + MySQL). Bentuk modelnya sengaja dibuat sama
/// dengan yang akan dikirim server agar penggantian hanya di lapisan ini.
class MockData {
  MockData._();

  static const String farmAId = 'farm-a';
  static const String farmBId = 'farm-b';

  static List<Farm> farms() => <Farm>[_tomatoFarm(), _riceFarm()];

  static Farm _tomatoFarm() {
    return Farm(
      id: farmAId,
      name: 'Kebun Mikiko • Blok A',
      location: 'Asah Gobleg, Bali',
      crop: 'Tomat',
      areaHectare: 0.17,
      ownerName: 'Budi Santoso',
      members: const ['Budi Santoso', 'Siti Aminah', 'Andi Pratama'],
      metrics: <SensorType, SensorMetric>{
        SensorType.soilMoisture:
            _metric(SensorType.soilMoisture, base: 56, amplitude: 6, seed: 3),
        SensorType.temperature:
            _metric(SensorType.temperature, base: 29.5, amplitude: 4, seed: 11),
        SensorType.humidity:
            _metric(SensorType.humidity, base: 68, amplitude: 9, seed: 5),
        SensorType.pressure:
            _metric(SensorType.pressure, base: 1009, amplitude: 3, seed: 8),
        SensorType.rain:
            _metric(SensorType.rain, base: 0.4, amplitude: 0.8, seed: 2),
      },
      pumpOn: false,
      autoIrrigation: true,
      moistureThreshold: 40,
      irrigationDurationMinutes: 10,
      lastSync: DateTime.now(),
    );
  }

  static Farm _riceFarm() {
    return Farm(
      id: farmBId,
      name: 'Area Pembibitan • Demo',
      location: 'Asah Gobleg, Bali',
      crop: 'Padi IR64',
      areaHectare: 1.5,
      ownerName: 'Budi Santoso',
      members: const ['Budi Santoso', 'Siti Aminah'],
      metrics: <SensorType, SensorMetric>{
        SensorType.soilMoisture:
            _metric(SensorType.soilMoisture, base: 64, amplitude: 7, seed: 21),
        SensorType.temperature: _metric(SensorType.temperature,
            base: 31.8, amplitude: 3.5, seed: 13),
        SensorType.humidity:
            _metric(SensorType.humidity, base: 76, amplitude: 8, seed: 15),
        SensorType.pressure:
            _metric(SensorType.pressure, base: 1007, amplitude: 2.5, seed: 18),
        SensorType.rain:
            _metric(SensorType.rain, base: 1.6, amplitude: 1.5, seed: 22),
      },
      pumpOn: false,
      autoIrrigation: false,
      moistureThreshold: 55,
      irrigationDurationMinutes: 20,
      lastSync: DateTime.now(),
    );
  }

  static SensorMetric _metric(
    SensorType type, {
    required double base,
    required double amplitude,
    required int seed,
    int hours = 24,
  }) {
    final rnd = Random(seed);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour)
        .subtract(Duration(hours: hours - 1));
    final history = <TimePoint>[];
    for (var i = 0; i < hours; i++) {
      final t = start.add(Duration(hours: i));
      final v = base +
          amplitude * sin(i / 3.2) +
          (rnd.nextDouble() - 0.5) * amplitude * 0.6;
      history.add(TimePoint(t, _round(v)));
    }
    return SensorMetric(
      type: type,
      value: history.last.value,
      history: history,
      updatedAt: now,
    );
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(1));

  static List<IrrigationSchedule> schedules() {
    return <IrrigationSchedule>[
      IrrigationSchedule(
        id: 'sch-1',
        farmId: farmAId,
        label: 'Penyiraman pagi',
        hour: 6,
        minute: 0,
        durationMinutes: 10,
        enabled: true,
      ),
      IrrigationSchedule(
        id: 'sch-2',
        farmId: farmAId,
        label: 'Penyiraman sore',
        hour: 17,
        minute: 30,
        durationMinutes: 8,
        enabled: true,
        weekdays: const {1, 3, 5},
      ),
      IrrigationSchedule(
        id: 'sch-3',
        farmId: farmBId,
        label: 'Pengairan sawah',
        hour: 5,
        minute: 30,
        durationMinutes: 25,
        enabled: false,
        weekdays: const {1, 4},
      ),
      IrrigationSchedule(
        id: 'sch-4',
        farmId: farmBId,
        label: 'Pengairan tambahan',
        hour: 15,
        minute: 0,
        durationMinutes: 15,
        enabled: true,
      ),
    ];
  }

  static List<PlantTask> tasks() {
    final now = DateTime.now();
    return <PlantTask>[
      PlantTask(
        id: 'task-1',
        farmId: farmAId,
        title: 'Cek kelembapan tanah & kalibrasi sensor',
        notes: 'Pastikan probe tertancap 10 cm di zona akar.',
        type: TaskType.watering,
        due: now.add(const Duration(hours: 4)),
      ),
      PlantTask(
        id: 'task-2',
        farmId: farmAId,
        title: 'Pemupukan NPK 16-16-16',
        notes: 'Dosis 15 g per tanaman, larutkan sebelum aplikasi.',
        type: TaskType.fertilizing,
        due: now.add(const Duration(days: 2)),
      ),
      PlantTask(
        id: 'task-3',
        farmId: farmAId,
        title: 'Pemangkasan tunas air',
        notes: 'Buang tunas ketiak daun untuk menambah bobot buah.',
        type: TaskType.pruning,
        due: now.add(const Duration(days: 4)),
      ),
      PlantTask(
        id: 'task-4',
        farmId: farmBId,
        title: 'Pengamatan hama wereng',
        notes: 'Cek perangkap cahaya, catat populasi.',
        type: TaskType.pestControl,
        due: now.subtract(const Duration(hours: 6)),
      ),
      PlantTask(
        id: 'task-5',
        farmId: farmBId,
        title: 'Perkiraan panen gabah',
        notes: 'Umur 105 HST, cek kadar air sebelum panen.',
        type: TaskType.harvest,
        due: now.add(const Duration(days: 7)),
        done: true,
      ),
    ];
  }

  static List<AlertItem> initialAlerts() {
    final now = DateTime.now();
    return <AlertItem>[
      AlertItem(
        id: 'alert-1',
        farmId: farmAId,
        title: 'Kelembapan tanah rendah',
        message:
            'Kelembapan tanah 31% berada di bawah ambang 40%. Irigasi otomatis sudah disiapkan.',
        level: AlertLevel.warning,
        time: now.subtract(const Duration(minutes: 25)),
      ),
      AlertItem(
        id: 'alert-2',
        farmId: farmAId,
        title: 'Prakiraan hujan ringan',
        message:
            'Curah hujan terdeteksi 0.4 mm. Pertimbangkan menunda penyiraman sore.',
        level: AlertLevel.info,
        time: now.subtract(const Duration(hours: 3)),
        read: true,
      ),
      AlertItem(
        id: 'alert-3',
        farmId: farmBId,
        title: 'Pompa menyala lama',
        message: 'Pompa sawah menyala lebih dari 20 menit. Periksa debit air.',
        level: AlertLevel.critical,
        time: now.subtract(const Duration(minutes: 55)),
      ),
    ];
  }

  static List<IrrigationLog> irrigationLogs() {
    final now = DateTime.now();
    return <IrrigationLog>[
      IrrigationLog(
        id: 'log-1',
        farmId: farmAId,
        time: now.subtract(const Duration(hours: 7)),
        durationMinutes: 10,
        trigger: 'Jadwal',
      ),
      IrrigationLog(
        id: 'log-2',
        farmId: farmAId,
        time: now.subtract(const Duration(hours: 20)),
        durationMinutes: 12,
        trigger: 'Otomatis',
      ),
      IrrigationLog(
        id: 'log-3',
        farmId: farmBId,
        time: now.subtract(const Duration(minutes: 55)),
        durationMinutes: 20,
        trigger: 'Manual',
      ),
    ];
  }
}

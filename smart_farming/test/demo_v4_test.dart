import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/models/models.dart';
import 'package:smart_farming/models/soil_measurement.dart';
import 'package:smart_farming/services/demo_storage.dart';
import 'package:smart_farming/state/app_state.dart';

class MemoryStorage implements DemoStorage {
  String? value;
  @override
  String? read() => value;
  @override
  Future<void> write(String data) async {
    value = data;
  }
}

void main() {
  test('timer pompa tetap berhenti walau telemetri dijeda dan lahan diganti',
      () {
    // Seed data uses the current day; keep the injected clock on that day so
    // initial alerts cannot appear to come from the future as the date changes.
    var now = DateTime.now();
    final state = AppState(clock: () => now);
    addTearDown(state.dispose);
    state.setAutoIrrigation(false);
    state.runIrrigation(minutes: 5);
    expect(state.selectedFarm.pumpOn, isTrue);
    state.setLiveData(false);
    state.selectFarm('farm-b');
    now = now.add(const Duration(minutes: 5));
    state.controlTick();
    state.selectFarm('farm-a');
    expect(state.selectedFarm.pumpOn, isFalse);
    expect(state.relayStates.take(7), everyElement(isFalse));
    expect(state.alerts.first.title, 'Penyiraman selesai');
  });

  test('interlock pompa, fertigasi dan STOP berlaku untuk semua lahan', () {
    final state = AppState();
    addTearDown(state.dispose);
    expect(state.setRelay(4, true), isFalse);
    state.runIrrigation(minutes: 5);
    expect(state.setRelay(4, true), isTrue);
    expect(state.setRelay(5, true), isFalse);
    state.selectFarm('farm-b');
    state.runIrrigation(minutes: 5);
    state.emergencyStop();
    for (final f in state.farms) {
      state.selectFarm(f.id);
      expect(state.selectedFarm.pumpOn, isFalse);
      expect(state.selectedFarm.autoIrrigation, isFalse);
      expect(state.schedules.every((s) => !s.enabled), isTrue);
      expect(state.relayStates, everyElement(isFalse));
    }
  });

  test('skenario kering, hujan dan node offline mengubah respons otomatis', () {
    final state = AppState();
    addTearDown(state.dispose);
    state.setAutoIrrigation(true);
    state.applyScenario(DemoScenario.dry);
    expect(state.selectedFarm.pumpOn, isTrue);
    state.applyScenario(DemoScenario.rain);
    expect(state.selectedFarm.pumpOn, isFalse);
    state.simulateTick();
    expect(state.selectedFarm.pumpOn, isFalse);
    state.applyScenario(DemoScenario.offline);
    final before = state.selectedFarm.lastSync;
    state.simulateTick();
    state.runIrrigation(minutes: 5);
    expect(state.nodeOnline, isFalse);
    expect(state.selectedFarm.pumpOn, isFalse);
    expect(state.selectedFarm.lastSync, before);
    state.applyScenario(DemoScenario.normal);
    expect(state.nodeOnline, isTrue);
  });

  test('hasil soil tester terikat lahan dan tidak menjadi input kendali', () {
    final state = AppState();
    addTearDown(state.dispose);
    final moisture = state.selectedFarm.soilMoisture;
    final pump = state.selectedFarm.pumpOn;
    final m = state.measureSoil(
        plot: 'Zona B', point: 'Titik 3', notes: 'Sebelum irigasi');
    expect(m.toJson()['quality'], 'simulated');
    expect(SoilMeasurement.fromJson(m.toJson()).point, 'Titik 3');
    expect(state.selectedFarm.soilMoisture, moisture);
    expect(state.selectedFarm.pumpOn, pump);
    state.selectFarm('farm-b');
    expect(state.measurements.any((x) => x.id == m.id), isFalse);
    expect(() => state.measureSoil(plot: ' ', point: '1'), throwsArgumentError);
  });

  test('lahan, tugas, jadwal, ambang dan sampel pulih setelah restart',
      () async {
    final storage = MemoryStorage();
    final first = AppState(storage: storage);
    first.addFarm(name: 'Cabai demo', crop: 'Cabai', location: 'Bali');
    final id = first.selectedFarm.id;
    first.setMoistureThreshold(52);
    first.addSchedule(IrrigationSchedule(
        id: 'custom',
        farmId: id,
        label: 'Pagi',
        hour: 7,
        minute: 30,
        durationMinutes: 5,
        enabled: true));
    first.addTask(PlantTask(
        id: 'task-custom',
        farmId: id,
        title: 'Cek probe',
        notes: '',
        type: TaskType.other,
        due: DateTime(2026, 10, 20)));
    first.measureSoil(plot: 'Zona C', point: 'Titik 2');
    first.runIrrigation(minutes: 5);
    await first.flush();
    first.dispose();
    final restored = AppState(storage: storage);
    addTearDown(restored.dispose);
    expect(restored.selectedFarm.id, id);
    expect(restored.selectedFarm.moistureThreshold, 52);
    expect(restored.schedules.single.id, 'custom');
    expect(restored.tasks.single.title, 'Cek probe');
    expect(restored.measurements.single.point, 'Titik 2');
    expect(restored.irrigationLogs.first.durationMinutes, 5);
    expect(restored.selectedFarm.pumpOn, isFalse);
    expect(restored.relayStates, everyElement(isFalse));
    expect(restored.storageError, isFalse);
  });

  test('snapshot rusak tidak menghalangi masuk demo', () {
    final storage = MemoryStorage()..value = '{invalid';
    final state = AppState(storage: storage);
    addTearDown(state.dispose);
    expect(state.farms, isNotEmpty);
    expect(state.storageError, isTrue);
    state.login(email: '', name: 'Demo');
    expect(state.isLoggedIn, isTrue);
  });

  test('jadwal hanya dieksekusi sekali per hari, sesuai hari dan durasi', () {
    final now = DateTime(2026, 10, 19, 12, 15);
    final state = AppState(clock: () => now);
    addTearDown(state.dispose);
    state.login(email: '', name: 'Demo');
    state.addSchedule(IrrigationSchedule(
        id: 'now',
        farmId: state.selectedFarm.id,
        label: 'Sekarang',
        hour: 12,
        minute: 15,
        durationMinutes: 7,
        enabled: true,
        weekdays: {now.weekday}));
    state.controlTick();
    state.controlTick();
    expect(state.selectedFarm.pumpOn, isTrue);
    expect(
        state.irrigationLogs
            .where((l) => l.trigger == 'Jadwal' && l.durationMinutes == 7)
            .length,
        1);
    expect(state.pumpDeadline, now.add(const Duration(minutes: 7)));
    state.emergencyStop();
    state.controlTick();
    expect(state.selectedFarm.pumpOn, isFalse);
  });
}

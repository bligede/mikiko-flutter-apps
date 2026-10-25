import '../models/models.dart';

/// JSON adapters kept outside domain models and UI.
class DemoCodec {
  static Map<String, dynamic> farm(Farm f) => {
        'id': f.id,
        'name': f.name,
        'location': f.location,
        'crop': f.crop,
        'area': f.areaHectare,
        'owner': f.ownerName,
        'members': f.members,
        'auto': f.autoIrrigation,
        'threshold': f.moistureThreshold,
        'duration': f.irrigationDurationMinutes,
        'sync': f.lastSync.toIso8601String(),
        'metrics': f.metrics.values
            .map((m) => {
                  'type': m.type.name,
                  'value': m.value,
                  'updated': m.updatedAt.toIso8601String(),
                  'history': m.history
                      .map((p) => [p.time.toIso8601String(), p.value])
                      .toList(),
                })
            .toList(),
      };

  static Farm readFarm(Map<String, dynamic> j) => Farm(
        id: j['id'],
        name: j['name'],
        location: j['location'],
        crop: j['crop'],
        areaHectare: (j['area'] as num).toDouble(),
        ownerName: j['owner'],
        members: List<String>.from(j['members']),
        pumpOn: false,
        autoIrrigation: j['auto'],
        moistureThreshold: (j['threshold'] as num).toDouble(),
        irrigationDurationMinutes: j['duration'],
        lastSync: DateTime.parse(j['sync']),
        metrics: {
          for (final m in j['metrics'])
            SensorType.values.byName(m['type']): SensorMetric(
              type: SensorType.values.byName(m['type']),
              value: (m['value'] as num).toDouble(),
              updatedAt: DateTime.parse(m['updated']),
              history: [
                for (final p in m['history'])
                  TimePoint(DateTime.parse(p[0]), (p[1] as num).toDouble())
              ],
            ),
        },
      );

  static Map<String, dynamic> schedule(IrrigationSchedule s) => {
        'id': s.id,
        'farm': s.farmId,
        'label': s.label,
        'hour': s.hour,
        'minute': s.minute,
        'duration': s.durationMinutes,
        'enabled': s.enabled,
        'days': s.weekdays.toList(),
      };
  static IrrigationSchedule readSchedule(Map<String, dynamic> j) =>
      IrrigationSchedule(
        id: j['id'],
        farmId: j['farm'],
        label: j['label'],
        hour: j['hour'],
        minute: j['minute'],
        durationMinutes: j['duration'],
        enabled: j['enabled'],
        weekdays: Set<int>.from(j['days']),
      );

  static Map<String, dynamic> task(PlantTask t) => {
        'id': t.id,
        'farm': t.farmId,
        'title': t.title,
        'notes': t.notes,
        'type': t.type.name,
        'due': t.due.toIso8601String(),
        'done': t.done,
      };
  static PlantTask readTask(Map<String, dynamic> j) => PlantTask(
        id: j['id'],
        farmId: j['farm'],
        title: j['title'],
        notes: j['notes'],
        type: TaskType.values.byName(j['type']),
        due: DateTime.parse(j['due']),
        done: j['done'],
      );

  static Map<String, dynamic> alert(AlertItem a) => {
        'id': a.id,
        'farm': a.farmId,
        'title': a.title,
        'message': a.message,
        'level': a.level.name,
        'time': a.time.toIso8601String(),
        'read': a.read,
      };
  static AlertItem readAlert(Map<String, dynamic> j) => AlertItem(
        id: j['id'],
        farmId: j['farm'],
        title: j['title'],
        message: j['message'],
        level: AlertLevel.values.byName(j['level']),
        time: DateTime.parse(j['time']),
        read: j['read'],
      );

  static Map<String, dynamic> log(IrrigationLog l) => {
        'id': l.id,
        'farm': l.farmId,
        'time': l.time.toIso8601String(),
        'duration': l.durationMinutes,
        'trigger': l.trigger,
      };
  static IrrigationLog readLog(Map<String, dynamic> j) => IrrigationLog(
        id: j['id'],
        farmId: j['farm'],
        time: DateTime.parse(j['time']),
        durationMinutes: j['duration'],
        trigger: j['trigger'],
      );
}

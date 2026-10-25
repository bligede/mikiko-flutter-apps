import 'dart:convert';

/// Separate Firestore documents avoid a growing, shared snapshot document.
class CloudRecordCodec {
  static const collections = {
    'farms': 'farms',
    'schedules': 'schedules',
    'tasks': 'tasks',
    'alerts': 'alerts',
    'logs': 'irrigationLogs',
    'soil': 'soilMeasurements',
  };

  static Map<String, Map<String, dynamic>> records(String snapshot) {
    final data = jsonDecode(snapshot) as Map<String, dynamic>;
    final result = <String, Map<String, dynamic>>{};
    for (final entry in collections.entries) {
      for (final raw in data[entry.key] as List) {
        final record = Map<String, dynamic>.from(raw as Map);
        final id = record['id'] ?? record['measurement_id'];
        if (id is! String || id.isEmpty || id.contains('/')) {
          throw FormatException('ID data cloud tidak valid');
        }
        if (entry.key == 'farms') {
          // Keep representative hourly history, rather than thousands of
          // six-second samples inside each farm document.
          record['metrics'] = (record['metrics'] as List).map((rawMetric) {
            final metric = Map<String, dynamic>.from(rawMetric as Map);
            final hourly = <String, dynamic>{};
            for (final point in metric['history'] as List) {
              hourly[(point[0] as String).substring(0, 13)] = {
                'time': point[0],
                'value': point[1]
              };
            }
            metric['history'] = hourly.values.toList();
            return metric;
          }).toList();
        }
        result['${entry.value}/$id'] = record;
      }
    }
    result['settings/app'] = {
      for (final key in [
        'version',
        'selected',
        'dark',
        'live',
        'notifications',
        'runs'
      ])
        key: data[key],
    };
    return result;
  }

  static String fingerprint(String path, Map<String, dynamic> payload) {
    final stable = Map<String, dynamic>.from(payload);
    if (path.startsWith('farms/')) {
      // Simulated telemetry must not generate a billable write every tick.
      stable.remove('metrics');
      stable.remove('sync');
    }
    return jsonEncode(stable);
  }

  static String? snapshot(Map<String, Map<String, dynamic>> records) {
    final farms = records.entries
        .where((e) => e.key.startsWith('farms/'))
        .map((e) => e.value)
        .toList();
    if (farms.isEmpty) return null;
    final settings = records['settings/app'] ?? {};
    return jsonEncode({
      'version': 1,
      'selected': settings['selected'] ?? farms.first['id'],
      'dark': settings['dark'] ?? true,
      'live': settings['live'] ?? true,
      'notifications': settings['notifications'] ?? true,
      'runs': settings['runs'] ?? {},
      for (final c in collections.entries)
        c.key: records.entries
            .where((e) => e.key.startsWith('${c.value}/'))
            .map((e) {
          final payload = Map<String, dynamic>.from(e.value);
          if (c.key == 'farms') {
            payload['metrics'] = (payload['metrics'] as List)
                .map((m) => {
                      ...Map<String, dynamic>.from(m as Map),
                      'history': [
                        for (final p in m['history'] as List)
                          [p['time'], p['value']]
                      ],
                    })
                .toList();
          }
          return payload;
        }).toList(),
    });
  }
}

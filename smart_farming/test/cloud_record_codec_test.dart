import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/data/mock_data.dart';
import 'package:smart_farming/services/cloud_record_codec.dart';
import 'package:smart_farming/services/demo_codec.dart';

Map<String, dynamic> fixture() => {
      'version': 1,
      'selected': 'farm-a',
      'dark': true,
      'live': true,
      'notifications': true,
      'runs': <String, String>{},
      'farms': MockData.farms().map(DemoCodec.farm).toList(),
      'schedules': [],
      'tasks': [],
      'alerts': [],
      'logs': [],
      'soil': [],
    };

void main() {
  test(
      'farm history converts to Firestore-safe maps and restores to chart data',
      () {
    final records = CloudRecordCodec.records(jsonEncode(fixture()));
    void validate(dynamic value) {
      if (value is List) {
        expect(value.any((v) => v is List), isFalse,
            reason: 'Firestore rejects nested arrays');
        for (final v in value) {
          validate(v);
        }
      } else if (value is Map) {
        for (final v in value.values) {
          validate(v);
        }
      }
    }

    validate(records);
    final raw =
        jsonDecode(CloudRecordCodec.snapshot(records)!) as Map<String, dynamic>;
    final farm = DemoCodec.readFarm(raw['farms'][0]);
    expect(farm.id, 'farm-a');
    expect(farm.metrics.values.first.history.length, 24);
    expect(raw['selected'], 'farm-a');
  });

  test('six-second simulation ticks do not produce billable farm writes', () {
    final data = fixture();
    final initial = CloudRecordCodec.records(jsonEncode(data));
    final farm = (data['farms'] as List).first as Map<String, dynamic>;
    farm['sync'] =
        DateTime.now().add(const Duration(seconds: 6)).toIso8601String();
    (farm['metrics'] as List).first['value'] = 22.0;
    final after = CloudRecordCodec.records(jsonEncode(data));
    expect(
        CloudRecordCodec.fingerprint('farms/farm-a', initial['farms/farm-a']!),
        CloudRecordCodec.fingerprint('farms/farm-a', after['farms/farm-a']!));
    farm['threshold'] = 55.0;
    final configured = CloudRecordCodec.records(jsonEncode(data));
    expect(
        CloudRecordCodec.fingerprint('farms/farm-a', initial['farms/farm-a']!),
        isNot(CloudRecordCodec.fingerprint(
            'farms/farm-a', configured['farms/farm-a']!)));
  });

  test('IDs cannot create nested Firestore paths', () {
    final data = fixture();
    (data['farms'] as List).first['id'] = 'other/path';
    expect(() => CloudRecordCodec.records(jsonEncode(data)),
        throwsFormatException);
  });

  test('empty cloud database leaves local seed/migration to the app', () {
    expect(CloudRecordCodec.snapshot({}), isNull);
  });
}

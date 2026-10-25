import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// A single versioned snapshot keeps local demo data independent of a backend.
abstract class DemoStorage {
  String? read();
  Future<void> write(String value);
}

abstract class CloudDemoStorage implements DemoStorage {
  String get projectId;
  String get userId;
  int get pendingWrites;
  String? get syncError;
  Stream<void> get changes;
  Future<void> synchronize();
  void dispose();
}

class PreferencesDemoStorage implements DemoStorage {
  PreferencesDemoStorage(this.preferences);
  final SharedPreferences preferences;
  static const key = 'mikiko.demo.v1';

  @override
  String? read() => preferences.getString(key);

  @override
  Future<void> write(String value) async {
    if (!await preferences.setString(key, value)) {
      throw StateError('Penyimpanan lokal tidak tersedia');
    }
  }
}

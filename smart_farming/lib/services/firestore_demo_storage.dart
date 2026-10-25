import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_record_codec.dart';
import 'demo_storage.dart';

class FirestoreDemoStorage implements CloudDemoStorage {
  FirestoreDemoStorage._(this.database, this.preferences, this.userId);
  final FirebaseFirestore database;
  final SharedPreferences preferences;
  @override
  final String userId;
  @override
  String get projectId => database.app.options.projectId;
  String get _key => 'mikiko.cloud.cache.v1.$userId';
  String? _cached;
  final _fingerprints = <String, String>{};
  final _commits = <Future<void>>{};
  final _changes = StreamController<void>.broadcast();
  @override
  String? syncError;
  @override
  int get pendingWrites => _commits.length;
  @override
  Stream<void> get changes => _changes.stream;

  static Future<FirestoreDemoStorage> open(
      {required String userId,
      FirebaseFirestore? database,
      SharedPreferences? preferences}) async {
    final store = FirestoreDemoStorage._(database ?? FirebaseFirestore.instance,
        preferences ?? await SharedPreferences.getInstance(), userId);
    store._cached = store.preferences.getString(store._key);
    try {
      await store._load().timeout(const Duration(seconds: 10));
    } catch (_) {
      if (store._cached == null) {
        store.dispose();
        rethrow;
      }
      store.syncError = 'Offline. Perubahan tetap tersimpan di smartphone.';
    }
    if (store._cached == null) {
      // Preserve measurements and farms from the existing v0.2 demo when
      // upgrading the same Android installation to its new cloud backend.
      store._cached = store.preferences.getString(PreferencesDemoStorage.key);
      if (store._cached != null) {
        await store.preferences.setString(store._key, store._cached!);
        await store.preferences.setBool('${store._key}.dirty', true);
      }
    }
    return store;
  }

  DocumentReference<Map<String, dynamic>> get _user =>
      database.collection('users').doc(userId);

  Future<void> _load() async {
    final records = <String, Map<String, dynamic>>{};
    var fromCache = false;
    await Future.wait([...CloudRecordCodec.collections.values, 'settings']
        .map((collection) async {
      final snapshot = await _user.collection(collection).get();
      fromCache = fromCache || snapshot.metadata.isFromCache;
      for (final doc in snapshot.docs) {
        final payload = doc.data()['payload'];
        if (payload is Map) {
          records['$collection/${doc.id}'] = Map<String, dynamic>.from(payload);
        }
      }
    }));
    _fingerprints
      ..clear()
      ..addAll(records.map((path, payload) =>
          MapEntry(path, CloudRecordCodec.fingerprint(path, payload))));
    final remote = CloudRecordCodec.snapshot(records);
    final dirty = preferences.getBool('$_key.dirty') ?? false;
    if (!dirty && !(fromCache && remote == null && _cached != null)) {
      _cached = remote;
      if (remote != null) await preferences.setString(_key, remote);
    }
  }

  @override
  String? read() => _cached;

  @override
  Future<void> write(String value) async {
    _cached = value;
    if (!await preferences.setString(_key, value)) {
      throw StateError('Penyimpanan lokal tidak tersedia');
    }
    final records = CloudRecordCodec.records(value);
    final changed = records.entries
        .where((e) =>
            _fingerprints[e.key] !=
            CloudRecordCodec.fingerprint(e.key, e.value))
        .toList();
    final removed =
        _fingerprints.keys.where((key) => !records.containsKey(key)).toList();
    if (changed.isEmpty && removed.isEmpty) return;
    await preferences.setBool('$_key.dirty', true);
    var batch = database.batch();
    var count = 0;
    void submit() {
      if (count == 0) return;
      _submit(batch);
      batch = database.batch();
      count = 0;
    }

    for (final record in changed) {
      batch.set(
          _user
              .collection(record.key.split('/').first)
              .doc(record.key.split('/').last),
          {
            'payload': record.value,
            'mode': 'simulation',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _fingerprints[record.key] =
          CloudRecordCodec.fingerprint(record.key, record.value);
      if (++count >= 400) submit();
    }
    for (final key in removed) {
      batch.delete(
          _user.collection(key.split('/').first).doc(key.split('/').last));
      _fingerprints.remove(key);
      if (++count >= 400) submit();
    }
    submit();
  }

  void _submit(WriteBatch batch) {
    late final Future<void> task;
    task = batch.commit().then((_) async {
      syncError = null;
      if (_commits.length == 1) await preferences.setBool('$_key.dirty', false);
    }).catchError((Object _) {
      _fingerprints.clear();
      syncError = 'Belum tersinkron ke Firebase. Data tetap tersimpan di HP.';
    }).whenComplete(() {
      _commits.remove(task);
      _notify();
    });
    _commits.add(task);
    _notify();
    // Firestore queues writes offline. Waiting for server acknowledgement here
    // would block later local saves, so the repository tracks it separately.
    unawaited(task);
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Future<void> synchronize() async {
    final cached = _cached;
    if (cached != null) {
      _fingerprints.clear();
      await write(cached);
    }
    await Future.wait(_commits.toList()).timeout(const Duration(seconds: 12));
    if (syncError != null) throw StateError(syncError!);
    await _load().timeout(const Duration(seconds: 10));
  }

  @override
  void dispose() {
    unawaited(_changes.close());
  }
}

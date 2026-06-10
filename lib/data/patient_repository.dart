import 'package:hive_flutter/hive_flutter.dart';

import '../models/patient.dart';

/// Offline patient store backed by Hive. Patients are persisted as plain
/// maps (no generated adapters needed), keyed by patient id.
class PatientRepository {
  static const _boxName = 'patients';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  List<Patient> getAll() {
    final list = _box.values
        .map((e) => Patient.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  Patient? getById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Patient.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> save(Patient patient) async {
    await _box.put(patient.id, patient.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  bool exists(String id) => _box.containsKey(id);
}

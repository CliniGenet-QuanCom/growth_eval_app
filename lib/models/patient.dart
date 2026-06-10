import '../calc/growth_calc.dart';
import 'measurement.dart';

/// A patient record with demographic data, optional birth-size data
/// (Feature 1) and a time-ordered list of measurements (Feature 2/3).
class Patient {
  String id; // No / 患者ID
  String? name; // 名前 (任意)
  Sex sex;
  DateTime birthDate;

  // --- Birth / gestational data (optional, Feature 1) ---
  int? gestWeek; // 在胎週数 22-41
  int? gestDay; // 在胎日数 0-6
  int? parity; // 1=初産, 2=経産
  double? birthWeightGrams;
  double? birthLengthCm;
  double? birthHeadCm;

  List<Measurement> measurements;

  Patient({
    required this.id,
    this.name,
    required this.sex,
    required this.birthDate,
    this.gestWeek,
    this.gestDay,
    this.parity,
    this.birthWeightGrams,
    this.birthLengthCm,
    this.birthHeadCm,
    List<Measurement>? measurements,
  }) : measurements = measurements ?? [];

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : 'No.$id';

  List<Measurement> get sortedMeasurements {
    final list = [...measurements];
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sex': sex.code,
        'birthDate': birthDate.toIso8601String(),
        'gestWeek': gestWeek,
        'gestDay': gestDay,
        'parity': parity,
        'birthWeightGrams': birthWeightGrams,
        'birthLengthCm': birthLengthCm,
        'birthHeadCm': birthHeadCm,
        'measurements': measurements.map((m) => m.toMap()).toList(),
      };

  factory Patient.fromMap(Map map) => Patient(
        id: map['id'] as String,
        name: map['name'] as String?,
        sex: SexLabel.fromCode(map['sex'] as String),
        birthDate: DateTime.parse(map['birthDate'] as String),
        gestWeek: map['gestWeek'] as int?,
        gestDay: map['gestDay'] as int?,
        parity: map['parity'] as int?,
        birthWeightGrams: (map['birthWeightGrams'] as num?)?.toDouble(),
        birthLengthCm: (map['birthLengthCm'] as num?)?.toDouble(),
        birthHeadCm: (map['birthHeadCm'] as num?)?.toDouble(),
        measurements: ((map['measurements'] as List?) ?? [])
            .map((e) => Measurement.fromMap(e as Map))
            .toList(),
      );
}

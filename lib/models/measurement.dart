/// A single time-point measurement for a patient (Feature 2 inputs).
class Measurement {
  String id;
  DateTime date;
  double heightCm;
  double weightKg;
  double? igf; // IGF-I (ng/ml), optional

  Measurement({
    required this.id,
    required this.date,
    required this.heightCm,
    required this.weightKg,
    this.igf,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'igf': igf,
      };

  factory Measurement.fromMap(Map map) => Measurement(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        igf: (map['igf'] as num?)?.toDouble(),
      );
}

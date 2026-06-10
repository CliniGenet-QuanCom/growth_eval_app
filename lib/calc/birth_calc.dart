import '../data/birth_reference.dart';
import 'growth_calc.dart';
import 'lms.dart';

/// Parity for the birth-weight reference selection.
enum Parity {
  primipara, // 初産 = 1
  multipara, // 経産 = 2
}

/// A single percentile/SDS pair (null = out of applicable range -> "*").
class PctSds {
  final double? percentile;
  final double? sds;
  const PctSds(this.percentile, this.sds);
  static const empty = PctSds(null, null);
  bool get isEmpty => percentile == null && sds == null;
}

/// Result bundle for Feature 1 (在胎期間別出生時体格指数).
class BirthResult {
  final PctSds weight;
  final PctSds length;
  final PctSds head;
  // Corrected-age (修正週) values – only present when an exam date is given.
  final int? correctedWeeks;
  final int? correctedDays;
  final PctSds correctedWeight;
  final PctSds correctedLength;
  final PctSds correctedHead;

  const BirthResult({
    required this.weight,
    required this.length,
    required this.head,
    this.correctedWeeks,
    this.correctedDays,
    this.correctedWeight = PctSds.empty,
    this.correctedLength = PctSds.empty,
    this.correctedHead = PctSds.empty,
  });
}

bool _gaInRange(int week) => week >= 22 && week <= 41;

int _rowIndex(int week, int day) => (week - 22) * 7 + day;

List<List<double>> _weightTable(Sex sex, Parity parity) {
  if (sex == Sex.male) {
    return parity == Parity.primipara
        ? birthWeightMalePrimi
        : birthWeightMaleMulti;
  }
  return parity == Parity.primipara
      ? birthWeightFemalePrimi
      : birthWeightFemaleMulti;
}

PctSds _lookup(List<List<double>> table, int week, int day, double value) {
  if (!_gaInRange(week)) return PctSds.empty;
  final idx = _rowIndex(week, day);
  if (idx < 0 || idx >= table.length) return PctSds.empty;
  final lms = table[idx];
  final z = lmsSds(value, lms[0], lms[1], lms[2]);
  return PctSds(percentileFromSds(z), z);
}

/// Birth weight in grams (input <200 is treated as kg and converted).
double normaliseBirthWeightGrams(double raw) => raw < 200 ? raw * 1000.0 : raw;

BirthResult computeBirth({
  required Sex sex,
  required Parity parity,
  required int gestWeek,
  required int gestDay,
  required double birthWeightGrams,
  double? birthLengthCm,
  double? birthHeadCm,
  // optional corrected-age inputs
  DateTime? birthDate,
  DateTime? examDate,
  double? examWeightGrams,
  double? examLengthCm,
  double? examHeadCm,
}) {
  final weight =
      _lookup(_weightTable(sex, parity), gestWeek, gestDay, birthWeightGrams);
  final length = birthLengthCm == null
      ? PctSds.empty
      : _lookup(birthLength, gestWeek, gestDay, birthLengthCm);
  final head = birthHeadCm == null
      ? PctSds.empty
      : _lookup(birthHead, gestWeek, gestDay, birthHeadCm);

  // Corrected gestational age, if an exam date is supplied.
  if (birthDate != null && examDate != null) {
    final totalDays =
        examDate.difference(birthDate).inDays + gestWeek * 7 + gestDay;
    final cw = totalDays ~/ 7;
    final cd = totalDays % 7;
    final cWeight = examWeightGrams == null
        ? PctSds.empty
        : _lookup(_weightTable(sex, parity), cw, cd, examWeightGrams);
    final cLength = examLengthCm == null
        ? PctSds.empty
        : _lookup(birthLength, cw, cd, examLengthCm);
    final cHead = examHeadCm == null
        ? PctSds.empty
        : _lookup(birthHead, cw, cd, examHeadCm);
    return BirthResult(
      weight: weight,
      length: length,
      head: head,
      correctedWeeks: cw,
      correctedDays: cd,
      correctedWeight: cWeight,
      correctedLength: cLength,
      correctedHead: cHead,
    );
  }

  return BirthResult(weight: weight, length: length, head: head);
}

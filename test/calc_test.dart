import 'package:flutter_test/flutter_test.dart';
import 'package:pediatric_growth/calc/age.dart';
import 'package:pediatric_growth/calc/birth_calc.dart';
import 'package:pediatric_growth/calc/growth_calc.dart';
import 'package:pediatric_growth/calc/lms.dart';

/// Reference values were cross-checked against the source workbooks'
/// coefficient tables (see tools/gen_data.py and the sanity script).
void main() {
  group('LMS / normal distribution', () {
    test('normsdist(0) ~ 0.5', () {
      expect(normsdist(0), closeTo(0.5, 1e-6));
    });
    test('normsdist(1.96) ~ 0.975', () {
      expect(normsdist(1.96), closeTo(0.975, 1e-3));
    });
    test('median value gives SDS 0', () {
      expect(lmsSds(10, 1, 10, 0.1), closeTo(0, 1e-9));
    });
    test('lmsValue inverts lmsSds', () {
      final v = lmsValue(1.0, -0.5, 16.0, 0.12);
      expect(lmsSds(v, -0.5, 16.0, 0.12), closeTo(1.0, 1e-6));
    });
  });

  group('Weight SDS (Isojima)', () {
    test('median male newborn ~ 0 SDS', () {
      final lms = weightLms(Sex.male, 0);
      expect(lms.m, closeTo(2.998, 0.001)); // median ~3.0 kg
      expect(lmsSds(2.998, lms.l, lms.m, lms.s), closeTo(0, 1e-6));
    });
    test('male median weight at 120 months', () {
      final lms = weightLms(Sex.male, 120);
      expect(lms.m, closeTo(31.39, 0.05));
    });
  });

  group('Height SDS', () {
    test('boy 49cm at birth ~ 0 SDS', () {
      final sds = heightSds(Sex.male, const AgeParts(0, 0, 0), 49.0);
      expect(sds, isNotNull);
      expect(sds!, closeTo(0.019, 0.01));
    });
    test('age >= 18 -> null', () {
      expect(heightSds(Sex.male, const AgeParts(18, 0, 0), 170), isNull);
    });
  });

  group('Birth size', () {
    test('male primipara 40w0d 3000g ~ 39th percentile', () {
      final r = computeBirth(
        sex: Sex.male,
        parity: Parity.primipara,
        gestWeek: 40,
        gestDay: 0,
        birthWeightGrams: 3000,
      );
      expect(r.weight.percentile, closeTo(38.9, 0.5));
      expect(r.weight.sds, closeTo(-0.281, 0.01));
    });
    test('out-of-range gestational age -> empty', () {
      final r = computeBirth(
        sex: Sex.male,
        parity: Parity.primipara,
        gestWeek: 20,
        gestDay: 0,
        birthWeightGrams: 1000,
      );
      expect(r.weight.isEmpty, isTrue);
    });
  });

  group('BMI LMS', () {
    test('male 5y (60 mo) median BMI ~ 15.3', () {
      final lms = bmiLms(Sex.male, 60);
      expect(lms.m, closeTo(15.319, 0.05));
    });
  });

  group('Weight input normalisation', () {
    test('values >= 200 treated as grams', () {
      expect(normaliseWeightKg(3200), closeTo(3.2, 1e-9));
      expect(normaliseWeightKg(15.5), closeTo(15.5, 1e-9));
    });
  });
}

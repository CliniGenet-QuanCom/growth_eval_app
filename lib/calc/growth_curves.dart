import '../data/height_reference.dart';
import 'growth_calc.dart';
import 'lms.dart';

/// The five reference SD lines drawn on every growth chart.
const List<double> kSdLines = [-2, -1, 0, 1, 2];

/// A point on a reference curve: x = age in years, y = measurement.
class CurvePoint {
  final double ageYears;
  final double value;
  const CurvePoint(this.ageYears, this.value);
}

enum ChartMetric { height, weight, bmi }

/// Generates the reference percentile curves (one list per SD line in
/// [kSdLines]) for the given metric/sex up to [maxYears].
List<List<CurvePoint>> referenceCurves(
  ChartMetric metric,
  Sex sex,
  double maxYears,
) {
  final curves = List.generate(kSdLines.length, (_) => <CurvePoint>[]);
  final maxMonths = (maxYears * 12).round();

  switch (metric) {
    case ChartMetric.height:
      final mean = sex == Sex.male ? heightMeanMale : heightMeanFemale;
      final sd = sex == Sex.male ? heightSdMale : heightSdFemale;
      for (var month = 0; month <= maxMonths; month++) {
        final y = month ~/ 12;
        final mo = month % 12;
        if (y > 17) break;
        final mu = mean[mo][y];
        final si = sd[mo][y];
        for (var i = 0; i < kSdLines.length; i++) {
          curves[i].add(CurvePoint(month / 12.0, mu + kSdLines[i] * si));
        }
      }
      break;
    case ChartMetric.weight:
      for (var month = 0; month <= maxMonths; month++) {
        final lms = weightLms(sex, month.toDouble());
        for (var i = 0; i < kSdLines.length; i++) {
          final v = lmsValue(kSdLines[i], lms.l, lms.m, lms.s);
          if (!v.isNaN) curves[i].add(CurvePoint(month / 12.0, v));
        }
      }
      break;
    case ChartMetric.bmi:
      for (var month = 0; month <= maxMonths; month++) {
        // BMI engine uses decimal months ~ months here.
        final lms = bmiLms(sex, month.toDouble());
        for (var i = 0; i < kSdLines.length; i++) {
          final v = lmsValue(kSdLines[i], lms.l, lms.m, lms.s);
          if (!v.isNaN) curves[i].add(CurvePoint(month / 12.0, v));
        }
      }
      break;
  }
  return curves;
}

const List<String> kSdLabels = ['-2SD', '-1SD', '中央値', '+1SD', '+2SD'];

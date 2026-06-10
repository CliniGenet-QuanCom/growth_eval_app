import 'dart:math' as math;

import '../data/bmi_lms.dart';
import '../data/height_reference.dart';
import '../data/igf_reference.dart';
import '../data/stdbw.dart';
import '../data/weight_sds.dart';
import 'age.dart';
import 'lms.dart';

enum Sex { male, female }

extension SexLabel on Sex {
  String get code => this == Sex.male ? 'M' : 'F';
  String get jp => this == Sex.male ? '男' : '女';
  static Sex fromCode(String c) => c.toUpperCase() == 'F' ? Sex.female : Sex.male;
}

/// A single LMS triple.
class Lms {
  final double l, m, s;
  const Lms(this.l, this.m, this.s);
}

/// Outputs of Feature 2 (体格指数計算). A null field means "not applicable"
/// (displayed as "*" in the UI, as in the source workbooks).
class GrowthResult {
  final AgeParts age;
  final double decimalAge;
  final double? heightSds;
  final double? obesity1Murata; // 肥満度① 幼児 (村田)
  final double? obesity2ItoAge; // 肥満度② 学童 年齢別 (伊藤)
  final double? obesity3ItoHeight; // 肥満度③ 身長別 (伊藤)
  final double bmi;
  final double? bmiPercentile;
  final double? bmiSds;
  final double? weightSds;
  final double? igfPercentile;
  final double? igfSds;

  const GrowthResult({
    required this.age,
    required this.decimalAge,
    required this.heightSds,
    required this.obesity1Murata,
    required this.obesity2ItoAge,
    required this.obesity3ItoHeight,
    required this.bmi,
    required this.bmiPercentile,
    required this.bmiSds,
    required this.weightSds,
    required this.igfPercentile,
    required this.igfSds,
  });
}

const double _kUpperAgeYears = 17.583; // weight/BMI applicability ceiling

double _horner(List<double> coeffsHighToLow, double x) {
  double r = 0;
  for (final c in coeffsHighToLow) {
    r = r * x + c;
  }
  return r;
}

double _logistic(List<double> mnop, double x) =>
    mnop[0] + mnop[1] / (1 + math.exp(mnop[2] + mnop[3] * x));

// ---------------- Height SDS (2000 reference) ----------------

double? heightSds(Sex sex, AgeParts age, double heightCm) {
  if (age.years >= 18) return null;
  final mean = sex == Sex.male ? heightMeanMale : heightMeanFemale;
  final sd = sex == Sex.male ? heightSdMale : heightSdFemale;
  final m = mean[age.months][age.years];
  final s = sd[age.months][age.years];
  if (s == 0) return null;
  return (heightCm - m) / s;
}

// ---------------- Weight SDS (Isojima piecewise LMS) ----------------

Lms weightLms(Sex sex, double months) {
  double l, m, s;
  if (sex == Sex.male) {
    l = _horner(wL_male, months);
  } else {
    l = months < wL_female_hi_W
        ? _horner(wL_female_lo, months)
        : wL_female_hi_U + wL_female_hi_V * (months - wL_female_hi_W);
  }
  if (sex == Sex.male) {
    if (months < 45) {
      m = _horner(wM_male_a, months);
    } else if (months < 153) {
      m = _horner(wM_male_b, months);
    } else {
      m = _logistic(wM_male_logit, months);
    }
  } else {
    if (months < 43.8) {
      m = _horner(wM_female_a, months) - 0.010431 * (1 - months / 210);
    } else if (months < 123) {
      m = _horner(wM_female_b, months) - 0.010431 * (1 - 1 / months);
    } else {
      m = _logistic(wM_female_logit, months) - 0.010431 * (1 - months / 210);
    }
  }
  if (sex == Sex.male) {
    s = months < 162 ? _horner(wS_male_lo, months) : _horner(wS_male_hi, months);
  } else {
    if (months < 156) {
      s = _horner(wS_female_lo, months);
    } else if (months < 186) {
      s = wS_female_U +
          (wS_female_V - wS_female_U) / 24 * (months - 186) +
          wS_female_W * math.pow(186 - months, 2) -
          0.005;
    } else {
      s = wS_female_U + (wS_female_V - wS_female_U) / 24 * (months - 186) - 0.005;
    }
  }
  return Lms(l, m, s);
}

double? weightSds(Sex sex, AgeParts age, double weightKg) {
  if (age.years + age.months / 12 > _kUpperAgeYears) return null;
  final lms = weightLms(sex, age.totalMonths.toDouble());
  return lmsSds(weightKg, lms.l, lms.m, lms.s);
}

// ---------------- BMI LMS ----------------

double _bmiSegment(List<List<double>> segs, double x) {
  for (final seg in segs) {
    if (x < seg[0]) {
      return seg[1] * x * x * x + seg[2] * x * x + seg[3] * x + seg[4];
    }
  }
  final seg = segs.last;
  return seg[1] * x * x * x + seg[2] * x * x + seg[3] * x + seg[4];
}

Lms bmiLms(Sex sex, double decMonths) {
  final l = _bmiSegment(sex == Sex.male ? bmiLMale : bmiLFemale, decMonths);
  final m = _bmiSegment(sex == Sex.male ? bmiMMale : bmiMFemale, decMonths);
  final s = _bmiSegment(sex == Sex.male ? bmiSMale : bmiSFemale, decMonths);
  return Lms(l, m, s);
}

// ---------------- Standard-weight obesity indices ----------------

double _murataStd(Sex sex, double heightCm) {
  final c = sex == Sex.male ? murataMale : murataFemale;
  return c[0] * heightCm * heightCm + c[1] * heightCm + c[2];
}

double _itoHeightStd(Sex sex, double heightCm) {
  final x = heightCm / 100.0;
  final band = heightCm < 140 ? 0 : (heightCm <= 149 ? 1 : 2);
  final row = (sex == Sex.male ? 0 : 3) + band;
  final c = itoHeightCubic[row];
  return c[0] * x * x * x + c[1] * x * x + c[2] * x + c[3];
}

// ---------------- IGF-I ----------------

double? igfSds(Sex sex, AgeParts age, double igf) {
  if (age.years > 77) return null;
  final table = sex == Sex.male ? igfMale : igfFemale;
  final row = table[age.years];
  return lmsSds(igf, row[0], row[1], row[2]);
}

// ---------------- Top-level Feature 2 ----------------

GrowthResult computeGrowth({
  required Sex sex,
  required DateTime birth,
  required DateTime exam,
  required double heightCm,
  required double weightKg,
  double? igf,
}) {
  final age = ageParts(birth, exam);
  final dec = decimalAge(birth, exam);
  final decMonths = decimalMonths(birth, exam);

  // height SDS
  final hSds = heightSds(sex, age, heightCm);

  // obesity ①: 村田 (幼児) 1<=age<6, 70<=h<120
  double? ob1;
  if (dec >= 1 && dec < 6 && heightCm >= 70 && heightCm < 120) {
    final std = _murataStd(sex, heightCm);
    ob1 = (weightKg - std) / std * 100;
  }

  // obesity ②: 伊藤 年齢別 (学童) age>=6, age<=17
  double? ob2;
  if (dec >= 6 && age.years <= 17) {
    final idx = age.years - 5; // age 5 -> 0
    if (idx >= 0 && idx < 13) {
      final ab = sex == Sex.male ? itoAgeLinearMale[idx] : itoAgeLinearFemale[idx];
      final std = ab[0] * heightCm + ab[1];
      ob2 = (weightKg - std) / std * 100;
    }
  }

  // obesity ③: 伊藤 身長別 age>=6, 101<=h<(M181/F174), age<=17.583
  double? ob3;
  final upperH = sex == Sex.male ? 181 : 174;
  if (dec >= 6 &&
      heightCm >= 101 &&
      heightCm < upperH &&
      age.years + age.months / 12 <= _kUpperAgeYears) {
    final std = _itoHeightStd(sex, heightCm);
    ob3 = (weightKg - std) / std * 100;
  }

  // BMI
  final bmi = weightKg / math.pow(heightCm / 100.0, 2);
  double? bmiPct, bmiSdsVal;
  if (age.years + age.months / 12 <= _kUpperAgeYears) {
    final lms = bmiLms(sex, decMonths);
    final z = lmsSds(bmi, lms.l, lms.m, lms.s);
    bmiSdsVal = z;
    bmiPct = percentileFromSds(z);
  }

  // weight SDS
  final wSds = weightSds(sex, age, weightKg);

  // IGF-I
  double? igfPct, igfS;
  if (igf != null && age.years <= 77) {
    final z = igfSds(sex, age, igf);
    if (z != null) {
      igfS = z;
      igfPct = percentileFromSds(z);
    }
  }

  return GrowthResult(
    age: age,
    decimalAge: dec,
    heightSds: hSds,
    obesity1Murata: ob1,
    obesity2ItoAge: ob2,
    obesity3ItoHeight: ob3,
    bmi: bmi,
    bmiPercentile: bmiPct,
    bmiSds: bmiSdsVal,
    weightSds: wSds,
    igfPercentile: igfPct,
    igfSds: igfS,
  );
}

/// Normalises a raw weight entry: values >= 200 are treated as grams.
double normaliseWeightKg(double raw) => raw >= 200 ? raw / 1000.0 : raw;

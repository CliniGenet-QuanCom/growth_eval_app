// Age arithmetic mirroring Excel's DATEDIF behaviour, used by every
// calculation so the app reproduces the reference workbooks.

class AgeParts {
  /// Completed whole years (DATEDIF "Y").
  final int years;

  /// Completed months within the current year, 0-11 (DATEDIF "YM").
  final int months;

  /// Completed days within the current month (DATEDIF "MD").
  final int days;

  const AgeParts(this.years, this.months, this.days);

  /// Total completed months since birth (= years*12 + months), the integer
  /// month index used by the weight-SDS engine.
  int get totalMonths => years * 12 + months;

  /// "Y年Mか月" style label.
  String get label => '$years歳$monthsか月';
}

/// Equivalent of Excel DATEDIF for the "Y", "YM", "MD" units combined.
AgeParts ageParts(DateTime birth, DateTime exam) {
  int y = exam.year - birth.year;
  int m = exam.month - birth.month;
  int d = exam.day - birth.day;
  if (d < 0) {
    m -= 1;
    // days in the month preceding the exam month
    final prevMonthLastDay = DateTime(exam.year, exam.month, 0).day;
    d += prevMonthLastDay;
  }
  if (m < 0) {
    y -= 1;
    m += 12;
  }
  return AgeParts(y, m, d);
}

/// Decimal age in years (anniversary based, leap-year aware) – matches the
/// fractional-age column of the workbooks closely.
double decimalAge(DateTime birth, DateTime exam) {
  final p = ageParts(birth, exam);
  final anniversary = DateTime(birth.year + p.years, birth.month, birth.day);
  final nextAnniversary =
      DateTime(birth.year + p.years + 1, birth.month, birth.day);
  final yearDays = nextAnniversary.difference(anniversary).inDays;
  final frac = exam.difference(anniversary).inDays / yearDays;
  return p.years + frac;
}

/// Decimal age expressed in months, as the BMI-LMS engine expects
/// (decimalYears * 365.25 / 30.4375).
double decimalMonths(DateTime birth, DateTime exam) =>
    decimalAge(birth, exam) * 365.25 / 30.4375;

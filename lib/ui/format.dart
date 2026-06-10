import 'package:intl/intl.dart';

final _date = DateFormat('yyyy/MM/dd');

String fmtDate(DateTime d) => _date.format(d);

/// Formats a nullable numeric result. null -> "*" (out of applicable range),
/// matching the reference workbooks.
String fmtNum(double? v, {int digits = 2, String unit = ''}) {
  if (v == null) return '*';
  if (v.isNaN) return '*';
  return v.toStringAsFixed(digits) + unit;
}

String fmtSds(double? v) => v == null || v.isNaN
    ? '*'
    : (v >= 0 ? '+' : '') + v.toStringAsFixed(2);

String fmtPct(double? v) =>
    v == null || v.isNaN ? '*' : '${v.toStringAsFixed(1)}%ile';

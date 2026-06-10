import 'dart:math' as math;

/// LMS method (Box-Cox) helpers and the normal cumulative distribution
/// implemented with an erf approximation (NORMSDIST equivalent).

/// Abramowitz & Stegun 7.1.26 approximation of the error function.
/// Maximum absolute error ~1.5e-7, which is more than enough for SDS work.
double erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;
  final t = 1.0 / (1.0 + p * ax);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

/// Cumulative standard-normal probability (Excel NORMSDIST).
double normsdist(double z) => 0.5 * (1.0 + erf(z / math.sqrt2));

/// SDS (z-score) for a measurement [x] given the LMS parameters.
/// SDS = ((x/M)^L - 1) / (L * S), with the L->0 limit handled.
double lmsSds(double x, double l, double m, double s) {
  if (l.abs() < 1e-7) {
    return math.log(x / m) / s;
  }
  return (math.pow(x / m, l) - 1) / (l * s);
}

/// Inverse LMS: the measurement value corresponding to a given [z] (SDS).
/// value = M * (1 + L*S*z)^(1/L), with the L->0 limit handled.
double lmsValue(double z, double l, double m, double s) {
  if (l.abs() < 1e-7) {
    return m * math.exp(s * z);
  }
  final base = 1 + l * s * z;
  if (base <= 0) return double.nan;
  return m * math.pow(base, 1 / l).toDouble();
}

/// Percentile (0-100) from an SDS via the normal distribution.
double percentileFromSds(double sds) => normsdist(sds) * 100.0;

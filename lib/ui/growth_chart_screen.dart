import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../calc/age.dart';
import '../calc/growth_calc.dart';
import '../calc/growth_curves.dart';
import '../calc/lms.dart';
import '../models/measurement.dart';
import '../models/patient.dart';
import 'format.dart';

class GrowthChartScreen extends StatefulWidget {
  final Patient patient;
  const GrowthChartScreen({super.key, required this.patient});

  @override
  State<GrowthChartScreen> createState() => _GrowthChartScreenState();
}

class _GrowthChartScreenState extends State<GrowthChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _infantRange = false; // false: 0-18, true: 0-6

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final age = decimalAge(widget.patient.birthDate, DateTime.now());
    _infantRange = age <= 6;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  double get _maxYears => _infantRange ? 6 : 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('成長曲線 — ${widget.patient.displayName}'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '身長'),
            Tab(text: '体重'),
            Tab(text: 'BMI'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('幼児期 0-6歳')),
                ButtonSegment(value: false, label: Text('全体 0-18歳')),
              ],
              selected: {_infantRange},
              onSelectionChanged: (s) =>
                  setState(() => _infantRange = s.first),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('ピンチイン／アウトで拡大・縮小、測定点をタップで詳細表示',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ChartView(
                    patient: widget.patient,
                    metric: ChartMetric.height,
                    maxYears: _maxYears,
                    unit: 'cm'),
                _ChartView(
                    patient: widget.patient,
                    metric: ChartMetric.weight,
                    maxYears: _maxYears,
                    unit: 'kg'),
                _ChartView(
                    patient: widget.patient,
                    metric: ChartMetric.bmi,
                    maxYears: _maxYears,
                    unit: ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientPoint {
  final double ageYears;
  final double value;
  final Measurement measurement;
  final double? sds;
  const _PatientPoint(this.ageYears, this.value, this.measurement, this.sds);
}

class _ChartView extends StatelessWidget {
  final Patient patient;
  final ChartMetric metric;
  final double maxYears;
  final String unit;

  const _ChartView({
    required this.patient,
    required this.metric,
    required this.maxYears,
    required this.unit,
  });

  static const _curveColors = [
    Color(0xFFBDBDBD),
    Color(0xFF90CAF9),
    Color(0xFF1565C0),
    Color(0xFF90CAF9),
    Color(0xFFBDBDBD),
  ];

  List<_PatientPoint> _patientPoints() {
    final pts = <_PatientPoint>[];
    for (final m in patient.sortedMeasurements) {
      final age = decimalAge(patient.birthDate, m.date);
      if (age > maxYears) continue;
      final ageInt = ageParts(patient.birthDate, m.date);
      double value;
      double? sds;
      switch (metric) {
        case ChartMetric.height:
          value = m.heightCm;
          sds = heightSds(patient.sex, ageInt, m.heightCm);
          break;
        case ChartMetric.weight:
          value = m.weightKg;
          sds = weightSds(patient.sex, ageInt, m.weightKg);
          break;
        case ChartMetric.bmi:
          value = m.weightKg / ((m.heightCm / 100) * (m.heightCm / 100));
          final lms = bmiLms(patient.sex,
              decimalMonths(patient.birthDate, m.date));
          sds = (ageInt.years + ageInt.months / 12) <= 17.583
              ? lmsSds(value, lms.l, lms.m, lms.s)
              : null;
          break;
      }
      pts.add(_PatientPoint(age, value, m, sds));
    }
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final curves = referenceCurves(metric, patient.sex, maxYears);
    final points = _patientPoints();

    double minY = double.infinity, maxY = -double.infinity;
    for (final c in curves) {
      for (final p in c) {
        if (p.value < minY) minY = p.value;
        if (p.value > maxY) maxY = p.value;
      }
    }
    for (final p in points) {
      if (p.value < minY) minY = p.value;
      if (p.value > maxY) maxY = p.value;
    }
    if (!minY.isFinite) {
      minY = 0;
      maxY = 1;
    }
    final pad = (maxY - minY) * 0.05 + 1;
    minY -= pad;
    maxY += pad;

    final bars = <LineChartBarData>[
      for (var i = 0; i < curves.length; i++)
        LineChartBarData(
          spots: [for (final p in curves[i]) FlSpot(p.ageYears, p.value)],
          isCurved: false,
          color: _curveColors[i],
          barWidth: i == 2 ? 2.2 : 1.2,
          dotData: const FlDotData(show: false),
        ),
      // patient series (last bar)
      LineChartBarData(
        spots: [for (final p in points) FlSpot(p.ageYears, p.value)],
        isCurved: false,
        color: Theme.of(context).colorScheme.error,
        barWidth: 2,
        dotData: const FlDotData(show: true),
      ),
    ];

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: maxYears,
        minY: minY,
        maxY: maxY,
        lineBarsData: bars,
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('年齢（歳）',
                style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxYears <= 6 ? 1 : 2,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(unit, style: const TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              // Only show tooltip content for the patient series.
              if (s.barIndex != bars.length - 1) {
                return null;
              }
              final idx = s.spotIndex;
              if (idx < 0 || idx >= points.length) return null;
              final p = points[idx];
              return LineTooltipItem(
                '${fmtDate(p.measurement.date)}\n'
                '${p.value.toStringAsFixed(metric == ChartMetric.height ? 1 : 2)}$unit\n'
                'SDS ${fmtSds(p.sds)}',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Column(
        children: [
          const _Legend(),
          const SizedBox(height: 4),
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 3, color: c),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        item(const Color(0xFFBDBDBD), '±2SD'),
        item(const Color(0xFF90CAF9), '±1SD'),
        item(const Color(0xFF1565C0), '中央値'),
        item(Theme.of(context).colorScheme.error, '測定値'),
      ],
    );
  }
}

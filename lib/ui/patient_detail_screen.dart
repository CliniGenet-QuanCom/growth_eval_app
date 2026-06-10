import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calc/age.dart';
import '../calc/growth_calc.dart';
import '../data/patient_repository.dart';
import '../models/measurement.dart';
import '../models/patient.dart';
import 'format.dart';
import 'growth_chart_screen.dart';
import 'measurement_edit_screen.dart';
import 'patient_edit_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late PatientRepository _repo;
  Patient? _patient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = context.read<PatientRepository>();
    _reload();
  }

  void _reload() => setState(() => _patient = _repo.getById(widget.patientId));

  Future<void> _addMeasurement() async {
    final p = _patient!;
    final m = await Navigator.push<Measurement>(
      context,
      MaterialPageRoute(
          builder: (_) => MeasurementEditScreen(birthDate: p.birthDate)),
    );
    if (m != null) {
      p.measurements.add(m);
      await _repo.save(p);
      _reload();
    }
  }

  Future<void> _editMeasurement(Measurement existing) async {
    final p = _patient!;
    final m = await Navigator.push<Measurement>(
      context,
      MaterialPageRoute(
          builder: (_) => MeasurementEditScreen(
              birthDate: p.birthDate, existing: existing)),
    );
    if (m != null) {
      await _repo.save(p);
      _reload();
    }
  }

  Future<void> _deleteMeasurement(Measurement m) async {
    final p = _patient!;
    p.measurements.removeWhere((x) => x.id == m.id);
    await _repo.save(p);
    _reload();
  }

  Future<void> _editPatient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientEditScreen(existing: _patient)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;
    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final measurements = p.sortedMeasurements.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit), onPressed: _editPatient),
        ],
      ),
      body: Column(
        children: [
          _PatientHeader(patient: p),
          if (p.measurements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.show_chart),
                  label: const Text('成長曲線を表示'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GrowthChartScreen(patient: p)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: measurements.isEmpty
                ? const Center(child: Text('測定値がありません'))
                : ListView.builder(
                    itemCount: measurements.length,
                    itemBuilder: (context, i) => _MeasurementCard(
                      patient: p,
                      measurement: measurements[i],
                      onEdit: () => _editMeasurement(measurements[i]),
                      onDelete: () => _deleteMeasurement(measurements[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeasurement,
        icon: const Icon(Icons.add),
        label: const Text('測定値を追加'),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  final Patient patient;
  const _PatientHeader({required this.patient});

  @override
  Widget build(BuildContext context) {
    final age = ageParts(patient.birthDate, DateTime.now());
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: patient.sex == Sex.male
                  ? Colors.blue.shade100
                  : Colors.pink.shade100,
              child: Text(patient.sex.jp,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No.${patient.id}',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('生年月日 ${fmtDate(patient.birthDate)}'),
                  Text('現在 ${age.label}'),
                  if (patient.gestWeek != null)
                    Text(
                        '在胎 ${patient.gestWeek}週${patient.gestDay ?? 0}日 ・ ${patient.parity == 2 ? "経産" : "初産"}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Patient patient;
  final Measurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeasurementCard({
    required this.patient,
    required this.measurement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = computeGrowth(
      sex: patient.sex,
      birth: patient.birthDate,
      exam: measurement.date,
      heightCm: measurement.heightCm,
      weightKg: measurement.weightKg,
      igf: measurement.igf,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text('${fmtDate(measurement.date)}　(${r.age.label})'),
        subtitle: Text(
            '身長 ${measurement.heightCm}cm ・ 体重 ${measurement.weightKg}kg'
            '${measurement.igf != null ? " ・ IGF-I ${measurement.igf}" : ""}'),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          _resultTable(context, r),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('編集'),
                  onPressed: onEdit),
              TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('削除'),
                  onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultTable(BuildContext context, GrowthResult r) {
    final rows = <List<String>>[
      ['年齢', '${r.age.label}（${r.decimalAge.toStringAsFixed(2)}歳）'],
      ['身長SDS', fmtSds(r.heightSds)],
      ['肥満度① 幼児(村田)', fmtNum(r.obesity1Murata, digits: 1, unit: '%')],
      ['肥満度② 学童(伊藤・年齢別)', fmtNum(r.obesity2ItoAge, digits: 1, unit: '%')],
      ['肥満度③ (伊藤・身長別)', fmtNum(r.obesity3ItoHeight, digits: 1, unit: '%')],
      ['BMI', fmtNum(r.bmi, digits: 2)],
      ['BMIパーセンタイル', fmtPct(r.bmiPercentile)],
      ['BMI-SDS', fmtSds(r.bmiSds)],
      ['体重SDS', fmtSds(r.weightSds)],
      ['IGF-I パーセンタイル', fmtPct(r.igfPercentile)],
      ['IGF-I SDS', fmtSds(r.igfSds)],
    ];
    return Table(
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2)},
      children: [
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(row[0],
                    style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(row[1],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
      ],
    );
  }
}

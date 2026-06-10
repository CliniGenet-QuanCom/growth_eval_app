import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc/birth_calc.dart';
import '../calc/growth_calc.dart';
import 'format.dart';

class BirthCalculatorScreen extends StatefulWidget {
  const BirthCalculatorScreen({super.key});

  @override
  State<BirthCalculatorScreen> createState() => _BirthCalculatorScreenState();
}

class _BirthCalculatorScreenState extends State<BirthCalculatorScreen> {
  Sex _sex = Sex.male;
  Parity _parity = Parity.primipara;
  final _week = TextEditingController();
  final _day = TextEditingController(text: '0');
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _head = TextEditingController();

  // optional corrected-age inputs
  DateTime? _birthDate;
  DateTime? _examDate;
  final _exWeight = TextEditingController();
  final _exLength = TextEditingController();
  final _exHead = TextEditingController();

  BirthResult? _result;
  String? _warning;

  @override
  void dispose() {
    for (final c in [
      _week,
      _day,
      _weight,
      _length,
      _head,
      _exWeight,
      _exLength,
      _exHead
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _d(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  void _calculate() {
    final week = int.tryParse(_week.text.trim());
    final day = int.tryParse(_day.text.trim()) ?? 0;
    final w = _d(_weight);
    if (week == null || w == null) {
      setState(() {
        _warning = '在胎週数と出生体重は必須です';
        _result = null;
      });
      return;
    }
    if (week < 22 || week > 41) {
      setState(() {
        _warning = '在胎22週未満／42週以上は適用範囲外です（「*」表示）';
      });
    } else {
      _warning = null;
    }
    final res = computeBirth(
      sex: _sex,
      parity: _parity,
      gestWeek: week,
      gestDay: day,
      birthWeightGrams: normaliseBirthWeightGrams(w),
      birthLengthCm: _d(_length),
      birthHeadCm: _d(_head),
      birthDate: _birthDate,
      examDate: _examDate,
      examWeightGrams: _d(_exWeight) == null
          ? null
          : normaliseBirthWeightGrams(_d(_exWeight)!),
      examLengthCm: _d(_exLength),
      examHeadCm: _d(_exHead),
    );
    setState(() => _result = res);
  }

  Future<void> _pick(bool isBirth) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _examDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('出生時体格指数の計算')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<Sex>(
            segments: const [
              ButtonSegment(value: Sex.male, label: Text('男 (M)')),
              ButtonSegment(value: Sex.female, label: Text('女 (F)')),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<Parity>(
            segments: const [
              ButtonSegment(
                  value: Parity.primipara, label: Text('初産 (1)')),
              ButtonSegment(
                  value: Parity.multipara, label: Text('経産 (2)')),
            ],
            selected: {_parity},
            onSelectionChanged: (s) => setState(() => _parity = s.first),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _week,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: '在胎週数 (22-41) *',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _day,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: '在胎日数 (0-6)',
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: '出生体重（g。200未満はkgとして自動換算）*',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _length,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: '出生身長 (cm)',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _head,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: '出生頭囲 (cm)',
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('修正週数換算（任意）',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text(_birthDate == null
                      ? '生年月日'
                      : fmtDate(_birthDate!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(false),
                  child:
                      Text(_examDate == null ? '検査日' : fmtDate(_examDate!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exWeight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: '検査時体重（g。200未満はkg換算）',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _exLength,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: '検査時身長 (cm)',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _exHead,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: '検査時頭囲 (cm)',
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.calculate),
            label: const Text('計算する'),
            onPressed: _calculate,
          ),
          if (_warning != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_warning!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final BirthResult result;
  const _ResultCard({required this.result});

  TableRow _row(String label, PctSds v) => TableRow(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(fmtPct(v.percentile),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(fmtSds(v.sds),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('出生時', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.4),
              },
              children: [
                const TableRow(children: [
                  Text('項目',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('パーセンタイル',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('SDS',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                _row('出生体重', r.weight),
                _row('出生身長', r.length),
                _row('出生頭囲', r.head),
              ],
            ),
            if (r.correctedWeeks != null) ...[
              const Divider(height: 28),
              Text('修正 ${r.correctedWeeks}週${r.correctedDays}日',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.4),
                },
                children: [
                  _row('修正体重', r.correctedWeight),
                  _row('修正身長', r.correctedLength),
                  _row('修正頭囲', r.correctedHead),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

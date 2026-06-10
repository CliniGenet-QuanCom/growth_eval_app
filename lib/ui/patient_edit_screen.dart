import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../calc/growth_calc.dart';
import '../data/patient_repository.dart';
import '../models/patient.dart';
import 'format.dart';

class PatientEditScreen extends StatefulWidget {
  final Patient? existing;
  const PatientEditScreen({super.key, this.existing});

  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _name;
  late TextEditingController _gestWeek;
  late TextEditingController _gestDay;
  late TextEditingController _bw;
  late TextEditingController _bl;
  late TextEditingController _bh;
  Sex _sex = Sex.male;
  int _parity = 1;
  DateTime? _birthDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = TextEditingController(text: e?.id ?? '');
    _name = TextEditingController(text: e?.name ?? '');
    _gestWeek = TextEditingController(text: e?.gestWeek?.toString() ?? '');
    _gestDay = TextEditingController(text: e?.gestDay?.toString() ?? '');
    _bw = TextEditingController(text: e?.birthWeightGrams?.toString() ?? '');
    _bl = TextEditingController(text: e?.birthLengthCm?.toString() ?? '');
    _bh = TextEditingController(text: e?.birthHeadCm?.toString() ?? '');
    _sex = e?.sex ?? Sex.male;
    _parity = e?.parity ?? 1;
    _birthDate = e?.birthDate;
  }

  @override
  void dispose() {
    for (final c in [_id, _name, _gestWeek, _gestDay, _bw, _bl, _bh]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
      locale: const Locale('ja'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _parseInt(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('生年月日を入力してください')));
      return;
    }
    final repo = context.read<PatientRepository>();
    final id = _id.text.trim();
    if (!_isEdit && repo.exists(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('この患者ID／Noは既に使われています')));
      return;
    }
    final p = widget.existing ??
        Patient(id: id, sex: _sex, birthDate: _birthDate!);
    p.id = id;
    p.name = _name.text.trim().isEmpty ? null : _name.text.trim();
    p.sex = _sex;
    p.birthDate = _birthDate!;
    p.gestWeek = _parseInt(_gestWeek);
    p.gestDay = _parseInt(_gestDay);
    p.parity = _parity;
    p.birthWeightGrams = _parse(_bw);
    p.birthLengthCm = _parse(_bl);
    p.birthHeadCm = _parse(_bh);
    await repo.save(p);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '患者情報の編集' : '患者の追加')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _id,
              enabled: !_isEdit,
              decoration: const InputDecoration(
                  labelText: 'No / 患者ID *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必須項目です' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: '名前（任意）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('男 (M)')),
                ButtonSegment(value: Sex.female, label: Text('女 (F)')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_birthDate == null
                  ? '生年月日を選択 *'
                  : '生年月日：${fmtDate(_birthDate!)}'),
              onPressed: _pickDate,
            ),
            const Divider(height: 32),
            Text('出生時情報（任意・出生時体格計算に使用）',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gestWeek,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: '在胎週数 (22-41)',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _gestDay,
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
            DropdownButtonFormField<int>(
              initialValue: _parity,
              decoration: const InputDecoration(
                  labelText: '初産 / 経産', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('初産 (1)')),
                DropdownMenuItem(value: 2, child: Text('経産 (2)')),
              ],
              onChanged: (v) => setState(() => _parity = v ?? 1),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bw,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '出生体重（g。200未満はkgとして自動換算）',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: '出生身長 (cm)',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bh,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: '出生頭囲 (cm)',
                        border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

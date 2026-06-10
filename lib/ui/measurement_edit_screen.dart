import 'package:flutter/material.dart';

import '../calc/growth_calc.dart';
import '../models/measurement.dart';
import 'format.dart';

/// Returns the edited/created Measurement, or null if cancelled.
class MeasurementEditScreen extends StatefulWidget {
  final DateTime birthDate;
  final Measurement? existing;
  const MeasurementEditScreen(
      {super.key, required this.birthDate, this.existing});

  @override
  State<MeasurementEditScreen> createState() => _MeasurementEditScreenState();
}

class _MeasurementEditScreenState extends State<MeasurementEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _height;
  late TextEditingController _weight;
  late TextEditingController _igf;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _height = TextEditingController(text: e?.heightCm.toString() ?? '');
    _weight = TextEditingController(text: e?.weightKg.toString() ?? '');
    _igf = TextEditingController(text: e?.igf?.toString() ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _igf.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.birthDate,
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final rawW = double.parse(_weight.text.trim());
    final m = widget.existing ??
        Measurement(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: _date,
          heightCm: 0,
          weightKg: 0,
        );
    m.date = _date;
    m.heightCm = double.parse(_height.text.trim());
    m.weightKg = normaliseWeightKg(rawW); // >=200 -> grams -> kg
    m.igf = _igf.text.trim().isEmpty ? null : double.tryParse(_igf.text.trim());
    Navigator.pop(context, m);
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return '必須項目です';
    if (double.tryParse(v.trim()) == null) return '数値を入力してください';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null ? '測定値の追加' : '測定値の編集')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('検査日：${fmtDate(_date)}'),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _height,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '身長 (cm) *', border: OutlineInputBorder()),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '体重 (kg) *',
                  helperText: '200以上はg入力とみなして自動換算します',
                  border: OutlineInputBorder()),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _igf,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'IGF-I (ng/ml)（任意）',
                  border: OutlineInputBorder()),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calc/age.dart';
import '../calc/growth_calc.dart';
import '../data/patient_repository.dart';
import '../models/patient.dart';
import 'birth_calculator_screen.dart';
import 'format.dart';
import 'patient_detail_screen.dart';
import 'patient_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PatientRepository _repo;
  List<Patient> _patients = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = context.read<PatientRepository>();
    _reload();
  }

  void _reload() => setState(() => _patients = _repo.getAll());

  Future<void> _addPatient() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PatientEditScreen()),
    );
    if (created == true) _reload();
  }

  Future<void> _openPatient(Patient p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: p.id)),
    );
    _reload();
  }

  Future<void> _confirmDelete(Patient p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('${p.displayName} を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(p.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小児体格指数'),
        actions: [
          IconButton(
            tooltip: '出生時体格計算',
            icon: const Icon(Icons.child_friendly_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BirthCalculatorScreen()),
            ),
          ),
        ],
      ),
      body: _patients.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              itemCount: _patients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _patients[i];
                final age = ageParts(p.birthDate, DateTime.now());
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.sex == Sex.male
                        ? Colors.blue.shade100
                        : Colors.pink.shade100,
                    child: Text(p.sex.jp),
                  ),
                  title: Text(p.displayName),
                  subtitle: Text(
                      '生年月日 ${fmtDate(p.birthDate)} ・ ${age.label} ・ 測定${p.measurements.length}件'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(p),
                  ),
                  onTap: () => _openPatient(p),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPatient,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('患者追加'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('患者が登録されていません'),
          const SizedBox(height: 4),
          const Text('右下の「患者追加」から登録してください',
              style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

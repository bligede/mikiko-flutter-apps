import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/soil_measurement.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SoilTesterScreen extends StatefulWidget {
  const SoilTesterScreen({super.key});
  @override
  State<SoilTesterScreen> createState() => _SoilTesterScreenState();
}

class _SoilTesterScreenState extends State<SoilTesterScreen> {
  final _point = TextEditingController(text: 'Titik 1');
  final _notes = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _plot = 'Zona A';
  bool _measuring = false;
  int _step = 0;
  static const _steps = [
    'Menstabilkan probe',
    'Membaca 7 parameter',
    'Menyimpan hasil'
  ];

  @override
  void dispose() {
    _point.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _measure() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _measuring = true;
      _step = 0;
    });
    for (var i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _step = i);
      await Future<void>.delayed(const Duration(milliseconds: 850));
    }
    if (!mounted) return;
    final result = context
        .read<AppState>()
        .measureSoil(plot: _plot, point: _point.text, notes: _notes.text);
    setState(() => _measuring = false);
    _showResult(result);
  }

  void _showResult(SoilMeasurement m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hasil pengukuran',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  '${m.plot} • ${m.point} • ${kDateTimeFormat.format(m.time)}'),
              const SizedBox(height: 16),
              const Chip(
                  avatar: Icon(Icons.science_outlined, size: 16),
                  label: Text('Data simulasi • tersimpan lokal')),
              const SizedBox(height: 16),
              ..._values(m).map((v) => InfoRow(v.$1, v.$2)),
              if (m.notes.isNotEmpty) ...[
                const Divider(height: 24),
                Text('Catatan: ${m.notes}')
              ],
              const SizedBox(height: 16),
              Text(
                  'pH, EC, dan NPK adalah pembacaan berkala. Validasi sensor dengan metode referensi sebelum digunakan untuk keputusan pemupukan.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Salin data pengukuran'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(
                          text: const JsonEncoder.withIndent('  ')
                              .convert(m.toJson())));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data JSON disalin')));
                      }
                    },
                  )),
            ]),
      ),
    );
  }

  List<(String, String)> _values(SoilMeasurement m) => [
        ('Kelembapan tanah', '${m.moisture.toStringAsFixed(1)} %'),
        ('Suhu tanah', '${m.temperature.toStringAsFixed(1)} °C'),
        ('pH', m.ph.toStringAsFixed(2)),
        ('EC', '${m.ec.toStringAsFixed(0)} µS/cm'),
        ('Nitrogen (N)', '${m.nitrogen} mg/kg'),
        ('Fosfor (P)', '${m.phosphorus} mg/kg'),
        ('Kalium (K)', '${m.potassium} mg/kg'),
      ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = Theme.of(context).colorScheme;
    final readings = state.measurements;
    return Scaffold(
      appBar: AppBar(title: const Text('Soil Tester')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.science_outlined,
                  size: 32, color: c.onPrimaryContainer),
              const Spacer(),
              Text('7-IN-1',
                  style: TextStyle(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                      color: c.onPrimaryContainer))
            ]),
            const SizedBox(height: 20),
            Text('Kenali tanah Anda.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(
                'Kelembapan, suhu, pH, EC, dan NPK\n${state.selectedFarm.name}',
                style: TextStyle(color: c.onPrimaryContainer, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 24),
        const SectionHeader('Pengukuran baru',
            subtitle: 'Pilih zona dan tandai titik pengambilan sampel'),
        AppCard(
            child: Form(
                key: _form,
                child: Column(children: [
                  DropdownButtonFormField<String>(
                    initialValue: _plot,
                    decoration: const InputDecoration(
                        labelText: 'Plot / zona',
                        prefixIcon: Icon(Icons.grid_view_outlined)),
                    items: ['Zona A', 'Zona B', 'Zona C']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged:
                        _measuring ? null : (v) => setState(() => _plot = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _point,
                      enabled: !_measuring,
                      maxLength: 60,
                      decoration: const InputDecoration(
                          labelText: 'Titik ukur',
                          prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Isi titik ukur terlebih dahulu'
                          : null),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _notes,
                      enabled: !_measuring,
                      maxLength: 250,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Catatan lapangan (opsional)',
                          hintText:
                              'Contoh: sebelum irigasi, kedalaman 10 cm')),
                  const SizedBox(height: 18),
                  if (_measuring) ...[
                    LinearProgressIndicator(value: (_step + 1) / 3),
                    const SizedBox(height: 10),
                    Text('${_steps[_step]}…'),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _measuring ? null : _measure,
                        icon: const Icon(Icons.science_outlined),
                        label: Text(
                            _measuring ? 'Mengukur…' : 'Mulai pengukuran demo'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                      )),
                  const SizedBox(height: 10),
                  Text(
                      'Simulasi ±3 detik. Pengukuran fisik mengikuti waktu stabilisasi probe.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ]))),
        const SizedBox(height: 26),
        SectionHeader('Riwayat pengukuran',
            subtitle: '${readings.length} hasil • tersimpan di perangkat ini'),
        for (final m in readings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
                onTap: () => _showResult(m),
                child: Row(children: [
                  CircleAvatar(
                      backgroundColor: c.primaryContainer,
                      child: Icon(Icons.science_outlined,
                          color: c.onPrimaryContainer)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${m.plot} / ${m.point}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(kDateTimeFormat.format(m.time),
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(
                            'pH ${m.ph.toStringAsFixed(1)}  •  EC ${m.ec.toStringAsFixed(0)} µS/cm',
                            style: TextStyle(color: c.primary, fontSize: 12)),
                      ])),
                  const Icon(Icons.chevron_right),
                ])),
          ),
      ]),
    );
  }
}

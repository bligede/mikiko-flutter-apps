import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

class FarmsScreen extends StatelessWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Lahan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFarm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah lahan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          const SectionHeader(
            'Lahan Anda',
            subtitle: 'Satu akun dapat mengelola beberapa lahan (multi-user)',
          ),
          ...state.farms.map((farm) {
            final active = farm.id == state.selectedFarm.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                onTap: () => state.selectFarm(farm.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.yard,
                          color: active ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            farm.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                          ),
                        ),
                        if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InfoRow('Komoditas', farm.crop, icon: Icons.grass),
                    InfoRow('Lokasi', farm.location, icon: Icons.place_outlined),
                    InfoRow('Luas', '${farm.areaHectare} ha', icon: Icons.square_foot),
                    InfoRow('Pemilik', farm.ownerName, icon: Icons.person_outline),
                    InfoRow(
                      'Skor kesehatan',
                      '${farm.healthScore}/100',
                      icon: Icons.monitor_heart_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anggota (${farm.members.length})',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: farm.members
                          .map(
                            (m) => Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: CircleAvatar(
                                child: Text(m.substring(0, 1).toUpperCase()),
                              ),
                              label: Text(m),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => state.selectFarm(farm.id),
                        icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                        label: Text(active ? 'Sedang dipantau' : 'Pantau lahan ini'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddFarm(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const _AddFarmDialog());
  }
}

class _AddFarmDialog extends StatefulWidget {
  const _AddFarmDialog();

  @override
  State<_AddFarmDialog> createState() => _AddFarmDialogState();
}

class _AddFarmDialogState extends State<_AddFarmDialog> {
  final _name = TextEditingController();
  final _crop = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _crop.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return AlertDialog(
      title: const Text('Tambah Lahan Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama lahan'),
          ),
          TextField(
            controller: _crop,
            decoration: const InputDecoration(labelText: 'Komoditas (mis. Cabai)'),
          ),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Lokasi'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            state.addFarm(
              name: _name.text.trim(),
              crop: _crop.text.trim().isEmpty ? 'Tanaman' : _crop.text.trim(),
              location: _location.text.trim().isEmpty ? 'Belum diisi' : _location.text.trim(),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

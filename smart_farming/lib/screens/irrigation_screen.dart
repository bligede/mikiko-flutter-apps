import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/common.dart';

class IrrigationScreen extends StatelessWidget {
  const IrrigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final farm = state.selectedFarm;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        _PumpCard(farm: farm),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () {
            state.emergencyStop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Semua output, mode otomatis, dan jadwal dihentikan')));
          },
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('STOP SEMUA OUTPUT'),
          style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.all(16)),
        ),
        const SizedBox(height: 20),
        const SectionHeader('Field Controller · 8 Kanal',
            subtitle: 'Kontrol simulasi Box 2 • perubahan langsung terlihat'),
        AppCard(
            child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Buka kontrol relay'),
                subtitle: Text(
                    '${state.relayStates.where((on) => on).length} dari 8 kanal aktif'),
                children: [
              for (var i = 0; i < 8; i++)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: CircleAvatar(
                      radius: 15,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 12))),
                  title: Text(
                      const [
                        'Pompa utama',
                        'Irigasi zona A',
                        'Irigasi zona B',
                        'Irigasi zona C',
                        'Fertigasi A',
                        'Fertigasi B',
                        'Mist / kabut',
                        'Lampu kebun'
                      ][i],
                      style: const TextStyle(fontSize: 14)),
                  value: state.relayStates[i],
                  onChanged: (value) => state.setRelay(i, value),
                ),
              const Divider(height: 24),
              Text(
                  'Interlock demo: kanal air memerlukan pompa. Fertigasi A dan B saling mengunci. STOP juga menonaktifkan mode otomatis dan jadwal.',
                  style: theme.textTheme.bodySmall),
            ])),
        const SizedBox(height: 18),
        const SectionHeader('Kontrol Manual',
            subtitle: 'Menyalakan pompa di luar jadwal'),
        Row(
          children: <Widget>[
            Expanded(
              child: AppCard(
                onTap: () => state.runIrrigation(minutes: 5),
                child: const Column(
                  children: <Widget>[
                    Icon(Icons.timer_outlined,
                        size: 26, color: Palette.petaniBlue),
                    SizedBox(height: 6),
                    Text('Siram 5 menit',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                onTap: () => state.runIrrigation(minutes: 15),
                child: const Column(
                  children: <Widget>[
                    Icon(Icons.timer, size: 26, color: Palette.petaniBlue),
                    SizedBox(height: 6),
                    Text('Siram 15 menit',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          'Irigasi Otomatis',
          subtitle: 'Berdasarkan pembacaan sensor kelembapan tanah',
        ),
        AppCard(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: farm.autoIrrigation,
                onChanged: state.setAutoIrrigation,
                title: const Text('Aktifkan mode otomatis'),
                subtitle: Text(
                  farm.autoIrrigation
                      ? 'Pompa dikendalikan oleh ambang kelembapan.'
                      : 'Pompa hanya bisa dinyalakan manual.',
                ),
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ambang kelembapan tanah: ${farm.moistureThreshold.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Slider(
                value: farm.moistureThreshold,
                min: 10,
                max: 80,
                divisions: 70,
                label: '${farm.moistureThreshold.toStringAsFixed(0)}%',
                onChanged:
                    farm.autoIrrigation ? state.setMoistureThreshold : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Durasi penyiraman: ${farm.irrigationDurationMinutes} menit',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Slider(
                value: farm.irrigationDurationMinutes.toDouble(),
                min: 2,
                max: 30,
                divisions: 28,
                label: '${farm.irrigationDurationMinutes} menit',
                onChanged: state.setIrrigationDuration,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.water_drop_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kelembapan sekarang ${farm.soilMoisture.toStringAsFixed(1)}% '
                        '(ambang ${farm.moistureThreshold.toStringAsFixed(0)}%).',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('Jadwal Aktif'),
        if (state.schedules.isEmpty)
          const AppCard(
            child:
                EmptyState(icon: Icons.event_busy, title: 'Belum ada jadwal'),
          )
        else
          ...state.schedules.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.timeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(s.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${s.dayLabel} • ${s.durationMinutes} menit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                        value: s.enabled,
                        onChanged: (_) => state.toggleSchedule(s.id)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const SectionHeader('Riwayat Penyiraman'),
        if (state.irrigationLogs.isEmpty)
          const AppCard(
              child:
                  EmptyState(icon: Icons.history, title: 'Belum ada riwayat'))
        else
          ...state.irrigationLogs.take(6).map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: <Widget>[
                        Icon(_triggerIcon(log.trigger),
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(log.trigger,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                kDateTimeFormat.format(log.time),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text('${log.durationMinutes} menit',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  IconData _triggerIcon(String trigger) => switch (trigger) {
        'Manual' => Icons.pan_tool_alt,
        'Otomatis' => Icons.autorenew,
        _ => Icons.schedule,
      };
}

class _PumpCard extends StatelessWidget {
  const _PumpCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final on = farm.pumpOn;
    final color = on ? Palette.success : theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: on ? Palette.success : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: on
                  ? Colors.white.withValues(alpha: 0.2)
                  : theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop,
              size: 32,
              color: on ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  on ? 'POMPA MENYALA' : 'POMPA MATI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: on ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  on
                      ? 'Simulasi aktif • selesai ${state.pumpDeadline == null ? "sesuai durasi" : kTimeFormat.format(state.pumpDeadline!)}'
                      : 'Tidak ada aliran air simulasi',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: on
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: state.togglePump,
                  style: FilledButton.styleFrom(
                    backgroundColor: on ? Colors.white : color,
                    foregroundColor: on ? Palette.success : Colors.white,
                  ),
                  icon: Icon(on ? Icons.power_off : Icons.power_settings_new,
                      size: 18),
                  label: Text(on ? 'Matikan' : 'Nyalakan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

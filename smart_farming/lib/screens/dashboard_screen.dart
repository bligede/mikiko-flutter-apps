import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'sensor_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final farm = state.selectedFarm;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        state.setLiveData(state.liveData);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _HealthCard(farm: farm),
          const SizedBox(height: 18),
          SectionHeader(
            'Monitor Sensor',
            subtitle: 'Diperbarui ${relativeTime(farm.lastSync)}',
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.65,
            children: kSensorOrder
                .map(
                  (type) => SensorCard(
                    farm: farm,
                    type: type,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SensorDetailScreen(type: type),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          SectionHeader('Aksi Cepat'),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickAction(
                  icon: Icons.water_drop,
                  label: 'Siram\nSekarang',
                  color: Palette.petaniBlue,
                  onTap: () => state.runIrrigation(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.autorenew,
                  label: farm.autoIrrigation ? 'Otomatis\nAKTIF' : 'Otomatis\nMATI',
                  color: farm.autoIrrigation ? Palette.success : theme.colorScheme.outline,
                  onTap: () => state.setAutoIrrigation(!farm.autoIrrigation),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.power_settings_new,
                  label: farm.pumpOn ? 'Matikan\nPompa' : 'Nyalakan\nPompa',
                  color: farm.pumpOn ? Palette.danger : Palette.success,
                  onTap: state.togglePump,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            'Tugas Terdekat',
            subtitle: '${state.pendingTaskCount} tugas belum selesai',
          ),
          if (state.tasks.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.task_alt,
                title: 'Belum ada tugas',
                message: 'Tambahkan tugas perawatan di tab Jadwal.',
              ),
            )
          else
            ...state.tasks.take(3).map((task) => _TaskTile(task: task)),
          const SizedBox(height: 22),
          SectionHeader(
            'Peringatan Terbaru',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
              ),
              child: const Text('Lihat semua'),
            ),
          ),
          if (state.alerts.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: 'Semua aman',
                message: 'Tidak ada peringatan aktif untuk lahan ini.',
              ),
            )
          else
            ...state.alerts.take(3).map((alert) => _AlertTile(alert: alert)),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final score = farm.healthScore;
    final color = score >= 75
        ? Palette.success
        : score >= 50
            ? Palette.warning
            : Palette.danger;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.primary, scheme.primary.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Skor Kesehatan Lahan',
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          '$score',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' / 100',
                          style: theme.textTheme.titleSmall?.copyWith(color: scheme.onPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 66,
                width: 66,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Chip(
                icon: farm.pumpOn ? Icons.power : Icons.power_off,
                label: farm.pumpOn ? 'Pompa menyala' : 'Pompa mati',
              ),
              _Chip(
                icon: farm.autoIrrigation ? Icons.autorenew : Icons.pan_tool_alt_outlined,
                label: farm.autoIrrigation
                    ? 'Otomatis > ${farm.moistureThreshold.toStringAsFixed(0)}%'
                    : 'Mode manual',
              ),
              _Chip(icon: Icons.square_foot, label: '${farm.areaHectare} ha'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: scheme.onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final PlantTask task;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Checkbox(
              value: task.done,
              onChanged: (_) => state.toggleTask(task.id),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(task.type.icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        task.type.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: task.isOverdue
                            ? Palette.danger
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kDateTimeFormat.format(task.due),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: task.isOverdue
                              ? Palette.danger
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.read<AppState>().markAlertRead(alert.id),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: alert.level.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert.level.icon, size: 18, color: alert.level.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          alert.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        relativeTime(alert.time),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(alert.message, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

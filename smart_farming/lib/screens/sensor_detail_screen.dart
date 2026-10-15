import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/metric_chart.dart';

class SensorDetailScreen extends StatelessWidget {
  const SensorDetailScreen({super.key, required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final farm = state.selectedFarm;
    final metric = farm.metric(type);
    final status = farm.statusOf(type);
    final theme = Theme.of(context);
    final color = status.color;

    return Scaffold(
      appBar: AppBar(title: Text(type.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(type.icon, color: color, size: 30),
                    const SizedBox(width: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          metric.value.toStringAsFixed(1),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(type.unit, style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const Spacer(),
                    StatusPill(status),
                  ],
                ),
                const SizedBox(height: 16),
                MetricLineChart(points: metric.history, color: color, height: 180),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Statistik 24 jam', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    StatTile(label: 'Terendah', value: '${metric.min.toStringAsFixed(1)}${type.unit}'),
                    StatTile(label: 'Tertinggi', value: '${metric.max.toStringAsFixed(1)}${type.unit}'),
                    StatTile(label: 'Rata-rata', value: '${metric.average.toStringAsFixed(1)}${type.unit}'),
                    StatTile(label: 'Sampel', value: '${metric.history.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (type == SensorType.soilMoisture) _ThresholdCard(farm: farm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Perangkat & pembacaan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                InfoRow('Sumber', type.hardware, icon: Icons.sensors),
                InfoRow('Format data', type.rawHint, icon: Icons.data_object),
                InfoRow('Topik MQTT', 'sensor/${farm.id}/${type.name}', icon: Icons.cloud_outlined),
                InfoRow('Endpoint API', 'GET /api/farms/${farm.id}/readings?type=${type.name}', icon: Icons.api),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ambang irigasi otomatis',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Pompa menyala bila kelembapan tanah turun di bawah nilai ini.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Slider(
                    value: farm.moistureThreshold,
                    min: 10,
                    max: 80,
                    divisions: 70,
                    label: '${farm.moistureThreshold.toStringAsFixed(0)}%',
                    onChanged: state.setMoistureThreshold,
                  ),
                ),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${farm.moistureThreshold.toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

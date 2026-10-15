import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/common.dart';
import '../widgets/metric_chart.dart';
import 'sensor_detail_screen.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final farm = state.selectedFarm;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.memory, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Perangkat ESP32',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Palette.success.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(Icons.wifi, size: 13, color: Palette.success),
                        SizedBox(width: 4),
                        Text(
                          'Terhubung',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Palette.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const InfoRow('Node', 'esp32-node-01', icon: Icons.router_outlined),
              const InfoRow('Interval kirim', 'setiap 5 detik', icon: Icons.timer_outlined),
              InfoRow('Sinkron terakhir', relativeTime(farm.lastSync), icon: Icons.sync),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('Semua Sensor', subtitle: 'Ketuk untuk melihat riwayat lengkap'),
        ...kSensorOrder.map((type) {
          final metric = farm.metric(type);
          final status = farm.statusOf(type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SensorDetailScreen(type: type)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(type.icon, color: status.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              type.label,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              metric.updatedAt.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))
                                  ? 'live'
                                  : relativeTime(metric.updatedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(status),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            metric.value.toStringAsFixed(1),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: status.color,
                            ),
                          ),
                          Text(type.unit, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MetricLineChart(
                    points: metric.history,
                    color: status.color,
                    height: 70,
                    showLabels: false,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

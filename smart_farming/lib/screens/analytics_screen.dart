import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/metric_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _hours = 24;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final farm = state.selectedFarm;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitik & Riwayat'),
        actions: <Widget>[
          PopupMenuButton<int>(
            initialValue: _hours,
            onSelected: (v) => setState(() => _hours = v),
            itemBuilder: (_) => const <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: 6, child: Text('6 jam terakhir')),
              PopupMenuItem<int>(value: 12, child: Text('12 jam terakhir')),
              PopupMenuItem<int>(value: 24, child: Text('24 jam terakhir')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Text('$_hours jam'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Skor kesehatan lahan', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        '${farm.healthScore}/100',
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${farm.name} • ${farm.crop}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 72,
                  width: 72,
                  child: CircularProgressIndicator(
                    value: farm.healthScore / 100,
                    strokeWidth: 9,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Tren Sensor', subtitle: 'Grafik historis tiap sensor'),
          ...kSensorOrder.map((type) {
            final metric = farm.metric(type);
            final status = farm.statusOf(type);
            final points = metric.history.length > _hours
                ? metric.history.sublist(metric.history.length - _hours)
                : metric.history;
            final color = status.color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(type.icon, size: 18, color: color),
                        const SizedBox(width: 8),
                        Text(
                          type.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '${metric.value.toStringAsFixed(1)} ${type.unit}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MetricLineChart(points: points, color: color, height: 140),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

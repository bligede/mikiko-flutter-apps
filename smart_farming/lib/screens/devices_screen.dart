import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final devices = [
      (
        Icons.tablet_mac_outlined,
        'Box 1 · HMI Gateway',
        'ESP32-S3 · layar sentuh 7 inci',
        'hmi-01',
        'Wi-Fi / MQTT',
        'Catu daya 5 V',
        true
      ),
      (
        Icons.tune,
        'Box 2 · Field Controller',
        'ESP32-S3 · relay 8 kanal',
        'field-01',
        'RS-485 ke HMI',
        'Catu daya 12 V',
        true
      ),
      (
        Icons.sensors,
        'Sensor Node',
        'ESP32-C3 · kelembapan tanah',
        'node-01',
        'ESP-NOW · kirim per jam',
        'Baterai 82% · 4.02 V',
        state.nodeOnline
      ),
      (
        Icons.science_outlined,
        'Portable Soil Tester',
        'ESP32-C3 · probe RS-485 7-in-1',
        'soil-tester-01',
        'Modbus RTU / ESP-NOW',
        'Baterai 76% · 3.92 V',
        true
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Perangkat MIKIKO')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SectionHeader('Satu kebun, satu ekosistem',
            subtitle: 'Arsitektur pilot MIKIKO V4 • seluruh status simulasi'),
        for (final d in devices)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Icon(d.$1, color: theme.colorScheme.primary, size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text(d.$2,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700))),
                      Icon(d.$7 ? Icons.check_circle : Icons.cloud_off,
                          color: d.$7
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error)
                    ]),
                    const SizedBox(height: 16),
                    Text(d.$3),
                    const Divider(height: 24),
                    InfoRow('ID perangkat', d.$4),
                    InfoRow('Komunikasi', d.$5),
                    InfoRow('Daya', d.$6),
                    InfoRow('Status demo', d.$7 ? 'Online' : 'Offline'),
                    if (d.$4 == 'node-01') ...[
                      const InfoRow('INA219', '18 mA · panel surya'),
                      InfoRow('Pembaruan',
                          relativeTime(state.selectedFarm.lastSync)),
                    ],
                  ]))),
        Text(
            'Status ini menggambarkan rancangan perangkat. Koneksi fisik MQTT/HTTPS belum diaktifkan dalam demo. Otoritas aktuator pada sistem nyata berada di Box 2.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/brand_logos.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user?.initials ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.name ?? 'Petani',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(user?.email ?? '-',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        user?.role.label ?? '',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            'Merek & Komunitas',
            subtitle: 'Perusahaan dan komunitas di balik sistem ini',
          ),
          const BrandBanner(),
          const SizedBox(height: 20),
          const SectionHeader('Aplikasi'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (_) => state.toggleTheme(),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Mode gelap'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: state.liveData,
                  onChanged: state.setLiveData,
                  secondary: const Icon(Icons.sync),
                  title: const Text('Simulasi data live'),
                  subtitle: const Text(
                      'Perbarui pembacaan sensor tiap beberapa detik'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Notifikasi'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: state.notificationsEnabled,
                  onChanged: state.setNotifications,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Peringatan dalam aplikasi'),
                  subtitle:
                      const Text('Tanah kering, pompa menyala lama, dll.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Koneksi & Integrasi'),
          if (state.cloudEnabled) ...[
            AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      state.cloudSyncError ??
                          (state.pendingCloudWrites > 0
                              ? 'Menyinkronkan perubahan…'
                              : 'Terhubung ke Firebase'),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                      'Data cloud mengikuti identitas tamu pada instalasi HP ini.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_sync_outlined),
                      label: const Text('Sinkron sekarang'),
                      onPressed: () async {
                        try {
                          await state.synchronizeCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Data berhasil disinkronkan ke Firebase')));
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Belum tersambung. Data tetap tersimpan di HP.')));
                          }
                        }
                      }),
                ])),
            const SizedBox(height: 16),
          ],
          if (state.cloudSyncError != null && !state.cloudEnabled)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(state.cloudSyncError!)),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const InfoRow('Perangkat', 'MIKIKO V4 (simulasi)',
                    icon: Icons.memory),
                InfoRow(
                    'Penyimpanan',
                    state.cloudEnabled
                        ? 'Firebase + cache lokal'
                        : 'Lokal di smartphone',
                    icon: Icons.storage),
                const InfoRow('Asisten AI', 'Mesin aturan lokal (offline)',
                    icon: Icons.smart_toy_outlined),
                const SizedBox(height: 10),
                Text(
                  state.cloudEnabled
                      ? 'Lahan, jadwal, tugas, peringatan dan hasil soil tester tersinkron ke Firebase. Cache lokal menjaga demo tetap berjalan saat offline. Sensor dan relay masih simulasi; chat bersifat sementara.'
                      : 'Demo dapat digunakan tanpa internet. Data tersimpan pada smartphone ini. Sensor dan relay masih simulasi; chat bersifat sementara.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang aplikasi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'MIKIKO Smart Farming',
                    applicationVersion: 'v0.3.0 (Firebase V4)',
                    applicationIcon: const MikikoMark(size: 44),
                    children: const <Widget>[
                      Text(
                        'Aplikasi smart farming untuk memantau sensor ESP32, '
                        'mengelola irigasi otomatis, jadwal perawatan, dan konsultasi '
                        'dengan asisten AI.',
                      ),
                      SizedBox(height: 16),
                      MikikoTechnologyLogo(height: 30),
                      SizedBox(height: 14),
                      PetaniMudaKerenLogo(height: 62),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Palette.danger),
                  title: const Text('Keluar dari akun'),
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    state.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

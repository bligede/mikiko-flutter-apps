import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/brand_logos.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'chatbot_screen.dart';
import 'dashboard_screen.dart';
import 'farms_screen.dart';
import 'irrigation_screen.dart';
import 'schedule_screen.dart';
import 'sensors_screen.dart';
import 'settings_screen.dart';

/// Kerangka utama dengan navigasi bawah + laci menu.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = <String>[
    'Dasbor',
    'Sensor',
    'Irigasi',
    'Jadwal',
    'Asisten AI',
  ];

  final _pages = const <Widget>[
    DashboardScreen(),
    SensorsScreen(),
    IrrigationScreen(),
    ScheduleScreen(),
    ChatbotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final farm = state.selectedFarm;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: PopupMenuButton<Farm>(
          onSelected: (f) => state.selectFarm(f.id),
          itemBuilder: (_) => state.farms
              .map(
                (f) => PopupMenuItem<Farm>(
                  value: f,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        f.id == farm.id ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: f.id == farm.id ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${f.crop} • ${f.location}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        _index == 0 ? farm.name : _titles[_index],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                Text(
                  _index == 0 ? '${farm.crop} • ${farm.location}' : farm.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Peringatan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
            ),
            icon: state.unreadAlertCount > 0
                ? Badge.count(count: state.unreadAlertCount, child: const Icon(Icons.notifications_none))
                : const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dasbor'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Sensor'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'Irigasi'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'Asisten'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final scheme = Theme.of(context).colorScheme;

    void go(Widget page) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              color: scheme.primaryContainer,
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primary,
                    child: Text(
                      user?.initials ?? '?',
                      style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user?.name ?? 'Petani',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(user?.email ?? '-', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                          user?.role.label ?? '',
                          style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.yard_outlined),
              title: const Text('Manajemen Lahan'),
              subtitle: Text('${state.farms.length} lahan terdaftar'),
              onTap: () => go(const FarmsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Analitik & Riwayat'),
              onTap: () => go(const AnalyticsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Peringatan'),
              trailing: state.unreadAlertCount > 0
                  ? Badge.count(count: state.unreadAlertCount)
                  : null,
              onTap: () => go(const AlertsScreen()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () => go(const SettingsScreen()),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () {
                Navigator.of(context).pop();
                state.logout();
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MikikoTechnologyLogo(height: 22),
                  const SizedBox(height: 14),
                  const PetaniMudaKerenLogo(height: 44),
                  const SizedBox(height: 12),
                  Text(
                    'Smart Farming MVP • v0.1.0',
                    style: Theme.of(context).textTheme.bodySmall,
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

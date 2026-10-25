import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/brand_logos.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MikikoTechnologyLogo(height: 36),
                  const SizedBox(height: 44),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: c.primaryContainer,
                        borderRadius: BorderRadius.circular(30)),
                    child: Text('SMART FARMING  /  V4',
                        style: TextStyle(
                            color: c.onPrimaryContainer,
                            letterSpacing: 2,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 24),
                  Text('Lebih dekat\ndengan kebun.',
                      style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                          letterSpacing: -1.5)),
                  const SizedBox(height: 18),
                  Text(
                      'Pantau lahan. Atur irigasi. Kenali tanah.\nSemua dalam genggaman Anda.',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: c.onSurfaceVariant, height: 1.65)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [c.primaryContainer, c.surfaceContainerHigh]),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: c.outlineVariant),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.eco_outlined,
                                color: c.primary, size: 30),
                            const Spacer(),
                            Text('PILOT SHOWROOM',
                                style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.8,
                                    color: c.onSurfaceVariant))
                          ]),
                          const SizedBox(height: 24),
                          Text('Kebun Mikiko',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text('Asah Gobleg, Buleleng, Bali'),
                          const SizedBox(height: 18),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _tag(context, Icons.sensors, 'Sensor node'),
                            _tag(context, Icons.tune, '8 kanal'),
                            _tag(context, Icons.science_outlined,
                                'Soil tester 7-in-1'),
                          ]),
                        ]),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.read<AppState>().login(
                            email: 'demo@mikiko.id', name: 'Petani Mikiko'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Masuk cepat sebagai demo'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18)),
                      )),
                  const SizedBox(height: 14),
                  Text(
                      context.watch<AppState>().cloudEnabled
                          ? 'Demo Firebase • Data tersimpan di cloud dan di HP.\nSeluruh pembacaan dan kontrol merupakan simulasi.'
                          : 'Demo lokal • Tanpa akun dan tanpa perangkat fisik.\nSeluruh pembacaan dan kontrol merupakan simulasi.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: c.onSurfaceVariant, height: 1.6)),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 18),
                  const Center(child: PetaniMudaKerenLogo(height: 48)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, IconData icon, String label) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        side: BorderSide.none,
        backgroundColor:
            Theme.of(context).colorScheme.surface.withValues(alpha: .6),
        visualDensity: VisualDensity.compact,
      );
}

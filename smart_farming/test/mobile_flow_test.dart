import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_farming/main.dart';
import 'package:smart_farming/screens/home_shell.dart';
import 'package:smart_farming/screens/soil_tester_screen.dart';
import 'package:smart_farming/state/app_state.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
        'demo di layar ${width.toInt()}px: navigasi dan pengukuran tanah',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const SmartFarmingApp());
      await tester.ensureVisible(find.text('Masuk cepat sebagai demo'));
      await tester.tap(find.text('Masuk cepat sebagai demo'));
      await tester.pump();
      final state = tester.element(find.byType(HomeShell)).read<AppState>();
      state.suspend();
      await tester.pumpAndSettle();
      for (final title in [
        'Sensor',
        'Irigasi',
        'Jadwal',
        'Asisten',
        'Dasbor'
      ]) {
        await tester.tap(find.descendant(
            of: find.byType(NavigationBar), matching: find.text(title)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$title pada $width px');
      }
      await tester.tap(find.text('Soil Tester'));
      await tester.pumpAndSettle();
      final before = state.measurements.length;
      await tester.drag(
          find.descendant(
              of: find.byType(SoilTesterScreen),
              matching: find.byType(ListView)),
          const Offset(0, -480));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mulai pengukuran demo'));
      await tester.tap(find.text('Mulai pengukuran demo'));
      await tester.pump();
      for (var step = 0; step < 3; step++) {
        await tester.pump(const Duration(milliseconds: 900));
      }
      await tester.pumpAndSettle();
      expect(find.text('Hasil pengukuran'), findsOneWidget);
      expect(state.measurements.length, before + 1);
      expect(find.text('Nitrogen (N)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

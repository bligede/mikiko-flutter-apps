import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/demo_storage.dart';
import 'services/firestore_demo_storage.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DemoStorage? storage;
  String? backendNotice;
  try {
    storage = PreferencesDemoStorage(await SharedPreferences.getInstance());
  } catch (_) {
    // Demo remains usable if the OS temporarily denies local preferences.
  }
  if (const bool.fromEnvironment('MIKIKO_FIREBASE', defaultValue: true)) {
    var phase = 'initialize';
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      final auth = FirebaseAuth.instance;
      phase = 'authenticate';
      final user = auth.currentUser ??
          (await auth.signInAnonymously().timeout(const Duration(seconds: 12)))
              .user;
      if (user == null) throw StateError('Identitas cloud tidak tersedia');
      phase = 'load-data';
      storage = await FirestoreDemoStorage.open(userId: user.uid);
    } catch (error) {
      // Useful startup diagnostics without printing credentials or tokens.
      debugPrint('MIKIKO Firebase bootstrap [$phase]: ${error is FirebaseException ? error.code : error}');
      backendNotice =
          'Firebase belum tersambung. Data disimpan lokal di HP; coba buka ulang saat online.';
    }
  }
  runApp(SmartFarmingApp(storage: storage, backendNotice: backendNotice));
}

class SmartFarmingApp extends StatelessWidget {
  const SmartFarmingApp({super.key, this.storage, this.backendNotice});
  final DemoStorage? storage;
  final String? backendNotice;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(storage: storage, backendNotice: backendNotice),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'MIKIKO Smart Farming',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: NotificationService.messengerKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.themeMode,
            home: state.isLoggedIn ? const HomeShell() : const LoginScreen(),
          );
        },
      ),
    );
  }
}

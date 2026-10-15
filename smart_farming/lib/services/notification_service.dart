import 'package:flutter/material.dart';

import '../models/models.dart';

/// Notifikasi dalam aplikasi (in-app).
///
/// MVP memakai SnackBar + daftar peringatan di dalam aplikasi supaya tidak
/// butuh konfigurasi native. Untuk push notification latar belakang nanti,
/// tambahkan `flutter_local_notifications` / Firebase Cloud Messaging dan
/// panggil dari [show].
class NotificationService {
  const NotificationService._();

  /// Dipasang pada MaterialApp agar bisa memunculkan SnackBar dari mana saja.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Mengembalikan messenger aktif, atau null bila belum ada frame/binding.
  ///
  /// Defensif agar aman dipanggil dari unit test murni dan saat aplikasi
  /// belum sempat membangun UI.
  static ScaffoldMessengerState? get _messenger {
    try {
      return messengerKey.currentState;
    } catch (_) {
      return null;
    }
  }

  static void show(AlertItem alert) {
    final messenger = _messenger;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: alert.level.color,
        content: Row(
          children: <Widget>[
            Icon(alert.level.icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alert.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void toast(String message, {bool error = false}) {
    final messenger = _messenger;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFD32F2F) : null,
        ),
      );
  }
}

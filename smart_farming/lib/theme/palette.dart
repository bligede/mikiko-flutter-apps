import 'package:flutter/material.dart';

/// Palet warna aplikasi.
///
/// Lima warna pertama diambil langsung dari moodboard desain (gambar 3),
/// lalu diturunkan menjadi peran Material 3 di [AppTheme.dark].
class Palette {
  const Palette._();

  // ---------------------------------------------------------------------------
  // Moodboard (gambar 3)
  // ---------------------------------------------------------------------------

  /// Hijau sage — warna utama (primary).
  static const Color sage = Color(0xFF8FA98B);

  /// Oranye terbakar — warna aksen (secondary).
  static const Color rust = Color(0xFFC25A1A);

  /// Hijau lumut — permukaan sekunder / kontainer.
  static const Color moss = Color(0xFF4A5D4A);

  /// Teal gelap — permukaan tinggi.
  static const Color deep = Color(0xFF23342F);

  /// Nyaris hitam — latar utama.
  static const Color ink = Color(0xFF141A18);

  // ---------------------------------------------------------------------------
  // Warna merek
  // ---------------------------------------------------------------------------

  /// Biru pada logo "PETANI MUDA".
  static const Color petaniBlue = Color(0xFF1B9BD8);

  /// Hijau pada logo "Keren!".
  static const Color petaniGreen = Color(0xFF71BF2C);

  /// Teal pada logo Mikiko Technology.
  static const Color mikikoTeal = Color(0xFF1FA98E);

  // ---------------------------------------------------------------------------
  // Netral & status
  // ---------------------------------------------------------------------------

  /// Teks terang di atas latar gelap.
  static const Color mist = Color(0xFFE8EDE9);

  /// Teks sekunder.
  static const Color mistDim = Color(0xFFA3B3AB);

  /// Garis tepi.
  static const Color outline = Color(0xFF35473F);

  static const Color success = sage;
  static const Color warning = rust;
  static const Color danger = Color(0xFFD9583F);
  static const Color info = Color(0xFF6FA8A0);

  // Turunan permukaan gelap.
  static const Color containerLowest = Color(0xFF0F1413);
  static const Color containerLow = Color(0xFF1A2320);
  static const Color container = Color(0xFF1E2825);
  static const Color containerHighest = Color(0xFF2C3D37);
  static const Color outlineVariant = Color(0xFF2A3833);

  // Permukaan mode terang.
  static const Color lightSurface = Color(0xFFF3F6F3);
  static const Color lightSurfaceVariant = Color(0xFFE2E9E3);
}

/// Gambar logo resmi (PNG transparan).
///
/// Jika file tersedia di `assets/logos/`, logo resmi dipakai otomatis.
/// Bila belum ada, aplikasi menampilkan versi vektor bawaan sehingga
/// tampilan tetap rapi.
class BrandAssets {
  const BrandAssets._();

  static const String mikiko = 'assets/logos/mikiko_technology.png';
  static const String petaniMudaKeren = 'assets/logos/petani_muda_keren.png';
}

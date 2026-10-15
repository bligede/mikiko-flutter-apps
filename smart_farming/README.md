# Smart Farming — Aplikasi Mobile (Flutter MVP)

**Mikiko Technology** — sistem ini dikembangkan dan dimiliki oleh Mikiko Technology,
dan aktivitasnya dipayungi komunitas **Petani Muda Keren**.

MVP aplikasi **smart farming** berbasis Flutter untuk memantau sensor dari perangkat
**ESP32**, mengelola **irigasi otomatis**, menjadwalkan **perawatan tanaman**, melihat
**riwayat & grafik**, menerima **peringatan**, mengelola **banyak lahan (multi-user)**,
dan berkonsultasi dengan **asisten chatbot AI**.

Aplikasi memakai **dark mode** sebagai tema utama, dengan palet warna dari moodboard
desain (lihat [Palet Warna](#palet-warna)).

Saat ini aplikasi berjalan penuh dengan **data simulasi lokal** (tanpa perlu backend),
sehingga bisa langsung dicoba. Struktur kode sudah disiapkan agar tinggal disambungkan
ke backend nyata (XAMPP/Docker + MySQL) dan broker MQTT ESP32.

---

## Fitur

| Fitur | Status MVP | Keterangan |
|---|---|---|
| Monitor sensor (soil moisture, BME280: suhu/kelembapan/tekanan, rain) | ✅ | Data simulasi, kartu sensor + grafik mini |
| Kontrol irigasi / pompa otomatis | ✅ | Saklar pompa, mode otomatis berbasis ambang kelembapan, log penyiraman |
| Jadwal & pengingat perawatan tanaman | ✅ | Jadwal irigasi berulang + daftar tugas dengan tenggat |
| Data historis + grafik | ✅ | Grafik garis 6/12/24 jam per sensor (CustomPainter, tanpa dependensi) |
| Notifikasi / peringatan (mis. tanah kering) | ✅ | Peringatan dalam aplikasi + SnackBar (push notification = roadmap) |
| Manajemen lahan ganda + multi-user | ✅ | Ganti lahan aktif, daftar anggota per lahan |
| Akses chatbot AI (gratis) | ✅ | Mesin aturan offline; bisa diarahkan ke LLM gratis (Ollama/ lainnya) |

---

## Merek & Logo

| Merek | Peran | Tampil di |
|---|---|---|
| **Mikiko Technology** | Perusahaan yang memiliki sistem ini | Layar login (atas), laci menu, Pengaturan, dialog Tentang |
| **Petani Muda Keren** | Komunitas yang memayungi aktivitas perusahaan | Layar login (bawah), laci menu, Pengaturan, dialog Tentang |

Logo diambil otomatis dari `assets/logos/` bila file tersedia. **Letakkan dua file PNG
berikut** (nama harus persis) untuk memakai logo resmi:

```
assets/logos/mikiko_technology.png
assets/logos/petani_muda_keren.png
```

Selama file belum ada, aplikasi menampilkan **versi vektor bawaan** yang digambar dengan
kode di `lib/widgets/brand_logos.dart`, sehingga tampilan tetap rapi. Detail lengkap ada
di [`assets/logos/README.md`](assets/logos/README.md).

---

## Palet Warna

Dark mode dibangun dari lima warna moodboard, lalu diturunkan menjadi peran Material 3:

| Warna | Hex | Peran di aplikasi |
|---|---|---|
| Hijau sage | `#8FA98B` | `primary` — tombol, indikator aktif, status normal |
| Oranye terbakar | `#C25A1A` | `secondary` — aksen, peringatan |
| Hijau lumut | `#4A5D4A` | `primaryContainer`, garis tepi |
| Teal gelap | `#23342F` | `surfaceContainerHigh` |
| Nyaris hitam | `#141A18` | `surface` / latar utama |

Warna merek untuk fallback logo: biru `#1B9BD8` dan hijau `#71BF2C` (Petani Muda Keren),
teal `#1FA98E` (Mikiko Technology).

Seluruh warna terpusat di **`lib/theme/palette.dart`** — ubah di satu tempat untuk
mengganti tema. Tema terang tetap tersedia dan bisa diaktifkan dari **Pengaturan → Mode gelap**.

---

## Prasyarat

- **Flutter SDK** stable (diuji pada **3.47.7 / Dart 3.13.5**)
- Android Studio (untuk Android) dan/atau Xcode (untuk iOS)
- Emulator/perangkat Android/iOS, atau Chrome (target web)

Cek instalasi:

```bash
flutter --version
flutter doctor
```

---

## Menjalankan

```bash
cd smart_farming
flutter pub get
flutter run          # pilih perangkat saat diminta
```

Menjalankan di target tertentu:

```bash
flutter run -d chrome            # web
flutter run -d emulator-5554     # Android
```

Build rilis:

```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS (butuh macOS/Xcode)
flutter build web --release      # web
```

---

## Struktur Proyek

```
smart_farming/
├── lib/
│   ├── main.dart                 # entry point, provider, tema, gerbang login
│   ├── models/
│   │   └── models.dart           # Farm, SensorMetric, IrrigationSchedule, PlantTask, AlertItem, ChatMessage, AppUser
│   ├── data/
│   │   └── mock_data.dart        # data dummy (pengganti sementara backend)
│   ├── services/
│   │   ├── ai_service.dart       # asisten chatbot (aturan lokal + endpoint LLM opsional)
│   │   └── notification_service.dart
│   ├── state/
│   │   └── app_state.dart        # ChangeNotifier: seluruh state aplikasi
│   ├── theme/
│   │   ├── palette.dart          # palet warna moodboard + warna merek
│   │   └── app_theme.dart        # dark mode (utama) + varian terang
│   ├── widgets/
│   │   ├── common.dart           # AppCard, SensorCard, StatusPill, dll.
│   │   ├── brand_logos.dart      # logo Mikiko Technology & Petani Muda Keren
│   │   └── metric_chart.dart     # grafik garis (CustomPainter)
│   └── screens/
│       ├── login_screen.dart
│       ├── home_shell.dart       # navigasi bawah + laci menu
│       ├── dashboard_screen.dart
│       ├── sensors_screen.dart
│       ├── sensor_detail_screen.dart
│       ├── irrigation_screen.dart
│       ├── schedule_screen.dart
│       ├── analytics_screen.dart
│       ├── farms_screen.dart
│       ├── chatbot_screen.dart
│       ├── alerts_screen.dart
│       └── settings_screen.dart
├── test/
│   ├── app_state_test.dart       # unit test logika (irigasi, jadwal, chat, dll.)
│   └── widget_test.dart          # smoke test alur login → dasbor
└── docs/
    ├── BACKEND.md                # rencana REST API + MySQL (XAMPP/Docker)
    └── ESP32.md                  # topik MQTT + contoh sketch Arduino
```

---

## Testing

```bash
flutter analyze     # harus "No issues found!"
flutter test        # 16 test: logika state, smoke test UI, branding & dark mode
```

---

## Cara masuk (demo)

Di layar login, tekan **"Masuk cepat sebagai demo"** — tidak perlu backend.
Akun: `demo@smartfarming.id` / nama **Pak Budi**.

---

## Roadmap Integrasi

MVP ini sengaja memisahkan **lapisan data** (`lib/data/mock_data.dart`) dari UI, sehingga
mengganti ke backend nyata cukup di satu tempat. Rencana bertahap:

1. **Backend REST + MySQL** (XAMPP/Docker) — lihat [`docs/BACKEND.md`](docs/BACKEND.md)
   - Endpoint: `/auth/login`, `/farms`, `/farms/{id}/readings`, `/farms/{id}/irrigation`, `/schedules`, `/tasks`, `/alerts`
   - Ganti `MockData` dengan `ApiRepository` yang memakai `package:http`.
2. **Ingest data ESP32** — lihat [`docs/ESP32.md`](docs/ESP32.md)
   - ESP32 publish ke topik MQTT → backend menyimpan ke MySQL → aplikasi membaca REST.
3. **Push notification** — Firebase Cloud Messaging atau `flutter_local_notifications`.
4. **Auth nyata** — JWT/session dari backend, dengan peran pemilik/pekerja.
5. **Chatbot AI daring** — arahkan `AiAssistantService(endpoint: ...)` ke LLM gratis
   (mis. Ollama lokal atau penyedia API gratis).

---

## Catatan Teknis

- **State management**: `provider` (`ChangeNotifier`).
- **Grafik**: implementasi `CustomPainter` sendiri → tanpa dependensi eksternal, bebas
  masalah versi dan ringan.
- **Dependensi runtime**: hanya `provider`, `intl`, `http` (+ `cupertino_icons`).
- **Simulasi live**: pembacaan sensor diperbarui tiap 6 detik (bisa dimatikan di
  Pengaturan) dan memicu logika irigasi otomatis + peringatan.

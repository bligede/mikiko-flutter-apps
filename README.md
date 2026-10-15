# Mikiko Flutter Apps

Kumpulan aplikasi **Flutter** yang dikembangkan oleh **Mikiko Technology**, dengan
aktivitas yang dipayungi komunitas **Petani Muda Keren**.

Repo ini adalah wadah beberapa aplikasi — setiap aplikasi berada di foldernya sendiri,
sehingga bisa dibangun, diuji, dan dirilis secara terpisah.

| Aplikasi | Folder | Deskripsi | Status |
|---|---|---|---|
| **Smart Farming** | [`smart_farming/`](smart_farming/) | Monitor sensor ESP32, irigasi otomatis, jadwal perawatan tanaman, analitik, dan chatbot AI | MVP berjalan (data simulasi) |

---

## Smart Farming

MVP aplikasi smart farming berbasis Flutter untuk memantau sensor dari perangkat
**ESP32**, mengelola **irigasi otomatis**, menjadwalkan **perawatan tanaman**, melihat
**riwayat & grafik**, menerima **peringatan**, mengelola **banyak lahan (multi-user)**,
dan berkonsultasi dengan **asisten chatbot AI**.

Saat ini aplikasi berjalan penuh dengan **data simulasi lokal** tanpa backend, jadi bisa
langsung dicoba. Struktur kode sudah dipisahkan agar tinggal disambungkan ke backend
nyata (REST + MySQL) dan broker MQTT dari ESP32.

### Fitur

| Fitur | Status | Keterangan |
|---|---|---|
| Monitor sensor (soil moisture, BME280: suhu/kelembapan/tekanan, rain) | ✅ | Data simulasi, kartu sensor + grafik mini |
| Kontrol irigasi / pompa otomatis | ✅ | Sakelar pompa, mode otomatis berbasis ambang kelembapan, log penyiraman |
| Jadwal & pengingat perawatan tanaman | ✅ | Jadwal irigasi berulang + daftar tugas dengan tenggat |
| Data historis + grafik | ✅ | Grafik garis 6/12/24 jam per sensor (CustomPainter, tanpa dependensi) |
| Notifikasi / peringatan (mis. tanah kering) | ✅ | Peringatan dalam aplikasi + SnackBar (push notification = roadmap) |
| Manajemen lahan ganda + multi-user | ✅ | Ganti lahan aktif, daftar anggota per lahan |
| Akses chatbot AI | ✅ | Mesin aturan offline; bisa diarahkan ke LLM (mis. Ollama) |

### Tampilan

Aplikasi memakai **dark mode** sebagai tema utama, dibangun dari lima warna moodboard
desain dan dipetakan ke peran Material 3:

| Warna | Hex | Peran |
|---|---|---|
| Hijau sage | `#8FA98B` | `primary` — tombol, indikator aktif, status normal |
| Oranye terbakar | `#C25A1A` | `secondary` — aksen, peringatan |
| Hijau lumut | `#4A5D4A` | `primaryContainer`, kontainer |
| Teal gelap | `#23342F` | `surfaceContainerHigh` |
| Nyaris hitam | `#141A18` | latar utama |

Seluruh warna terpusat di `smart_farming/lib/theme/palette.dart`. Tema terang tersedia
dan bisa diaktifkan dari **Pengaturan → Mode gelap**.

### Merek & Logo

| Merek | Peran |
|---|---|
| **Mikiko Technology** | Perusahaan yang memiliki dan mengembangkan sistem ini |
| **Petani Muda Keren** | Komunitas yang memayungi aktivitas perusahaan |

Kedua logo tampil di layar login, laci menu, Pengaturan, dan dialog Tentang. Logo diambil
otomatis dari `smart_farming/assets/logos/` bila tersedia:

```
smart_farming/assets/logos/mikiko_technology.png
smart_farming/assets/logos/petani_muda_keren.png
```

Selama file belum ada, aplikasi menampilkan **versi vektor bawaan** yang digambar dengan
kode sehingga tampilan tetap rapi. Detail ada di
[`smart_farming/assets/logos/README.md`](smart_farming/assets/logos/README.md).

---

## Menjalankan

### Prasyarat

- **Flutter SDK** stable — diuji pada **Flutter 3.47.7 / Dart 3.13.5**
- Android Studio (Android) dan/atau Xcode (iOS)
- Emulator/perangkat Android/iOS, atau Chrome (target web)

```bash
flutter --version
flutter doctor
```

### Menjalankan aplikasi

```bash
cd smart_farming
flutter pub get
flutter run            # pilih perangkat saat diminta
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

### Cara masuk (demo)

Di layar login, tekan **"Masuk cepat sebagai demo"** — tidak perlu backend.
Akun: `demo@smartfarming.id` (nama **Pak Budi**).

---

## Struktur Repo

```
.
├── README.md                     # dokumen ini (ikhtisar repo)
└── smart_farming/                # aplikasi Smart Farming
    ├── lib/
    │   ├── main.dart             # entry point, provider, tema, gerbang login
    │   ├── models/               # Farm, SensorMetric, IrrigationSchedule, PlantTask, AlertItem, ...
    │   ├── data/                 # mock_data.dart — pengganti sementara backend
    │   ├── services/             # ai_service.dart, notification_service.dart
    │   ├── state/                # app_state.dart — ChangeNotifier seluruh state
    │   ├── theme/                # palette.dart, app_theme.dart
    │   ├── widgets/              # komponen bersama + brand_logos + metric_chart
    │   └── screens/              # 12 layar (login, dasbor, sensor, irigasi, jadwal, ...)
    ├── test/                     # unit test logika + smoke test UI
    ├── docs/                     # BACKEND.md, ESP32.md
    └── assets/logos/             # aset logo merek
```

Penjelasan tiap folder, daftar endpoint, dan skema database ada di
[README aplikasi](smart_farming/README.md).

---

## Testing

```bash
cd smart_farming
flutter analyze     # harus "No issues found!"
flutter test        # unit test logika state + smoke test UI (branding & dark mode)
```

---

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [`smart_farming/README.md`](smart_farming/README.md) | Dokumentasi lengkap aplikasi Smart Farming |
| [`smart_farming/docs/BACKEND.md`](smart_farming/docs/BACKEND.md) | Rencana backend REST + MySQL (XAMPP/Docker), skema, kontrak API |
| [`smart_farming/docs/ESP32.md`](smart_farming/docs/ESP32.md) | Perangkat keras, topik & payload MQTT, contoh sketch Arduino |

---

## Roadmap

MVP sengaja memisahkan **lapisan data** dari UI, sehingga mengganti ke backend nyata
cukup di satu tempat (`lib/data/`). Rencana bertahap:

1. **Backend REST + MySQL** — ganti `MockData` dengan `ApiRepository` berbasis `package:http`.
2. **Ingest data ESP32** — ESP32 publish ke MQTT → backend simpan ke MySQL → aplikasi baca REST.
3. **Push notification** — Firebase Cloud Messaging atau `flutter_local_notifications`.
4. **Auth nyata** — JWT/session dari backend, dengan peran pemilik/pekerja.
5. **Chatbot AI daring** — arahkan `AiAssistantService(endpoint: ...)` ke penyedia LLM.

---

## Catatan Teknis

- **State management**: `provider` (`ChangeNotifier`).
- **Grafik**: implementasi `CustomPainter` sendiri → tanpa dependensi eksternal dan ringan.
- **Dependensi runtime**: hanya `provider`, `intl`, `http` (+ `cupertino_icons`).
- **Simulasi live**: pembacaan sensor diperbarui tiap 6 detik (bisa dimatikan di
  Pengaturan) dan memicu logika irigasi otomatis + peringatan.

---

## Lisensi

Belum ada file lisensi di repo ini. Tambahkan `LICENSE` bila syarat penggunaan perlu
ditetapkan secara eksplisit.

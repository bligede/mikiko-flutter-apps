# Demo Android — MIKIKO Smart Farming V4

Aplikasi Flutter v0.2.0 untuk presentasi rancangan MIKIKO V4. Semua pembacaan,
status perangkat, kontrol relay dan respons asisten menggunakan simulasi lokal.
Aplikasi tidak memerlukan akun, API key, internet, ataupun perangkat ESP32.

## Memasang di smartphone

1. Salin `dist/MIKIKO-Smart-Farming-v0.2.0-demo.apk` ke smartphone Android.
2. Buka APK dari Files / File Manager dan pilih **Instal**. Bila Android meminta
   izin memasang dari sumber ini, izinkan untuk File Manager tersebut.
3. Buka **MIKIKO Farming**, lalu tekan **Masuk cepat sebagai demo**.

APK universal mendukung ARM 32-bit, ARM64 dan x86_64, minimum Android 7
(API 24). APK release ditandatangani kunci debug lokal untuk demo;
publikasi Play Store memerlukan konfigurasi kunci rilis tersendiri.

Jika HP tersambung melalui USB dengan USB debugging dan otorisasi ADB aktif:

```powershell
& 'D:\Wahyu\.tools\android-sdk\platform-tools\adb.exe' install -r '.\dist\MIKIKO-Smart-Farming-v0.2.0-demo.apk'
```

## Alur presentasi ±5 menit

1. **Dasbor**: tampilkan Kebun Mikiko di Asah Gobleg, sensor dan menu perangkat.
   Semua angka adalah contoh, bukan hasil pengukuran lapangan.
2. **Tanah kering**: pilih skenario tersebut. Dengan mode otomatis aktif,
   kelembapan 22% memicu pompa. Buka **Irigasi** untuk melihat statusnya.
3. **Hujan**: kembali ke Dasbor dan pilih Hujan. Pompa otomatis berhenti dan
   peringatan tercatat. **Node offline** membekukan telemetri dan mematikan
   pompa demo. Pilih **Normal** untuk memulihkan kondisi.
4. **Kontrol 8 kanal**: di Irigasi, buka kontrol relay. Nyalakan pompa, lalu
   coba kanal zona. Fertigasi A dan B saling mengunci. **STOP SEMUA OUTPUT**
   mematikan semua lahan, mode otomatis, dan jadwal; aktifkan kembali mode
   otomatis/jadwal untuk melanjutkan demonstrasi.
5. **Soil Tester**: buka dari Dasbor/menu samping, pilih zona, isi titik dan
   catatan, lalu **Mulai pengukuran demo**. Tujuh parameter tampil setelah
   sekitar tiga detik. Hasil masuk riwayat dan dapat disalin sebagai JSON.
6. **Jadwal, lahan, asisten**: tambah tugas/jadwal, pindah lahan, dan tanyakan
   kondisi sensor pada asisten offline. Tema terang tersedia di Pengaturan.
7. Tutup dan buka kembali aplikasi untuk menunjukkan data yang tersimpan.
   Masuk demo kembali; sesi masuk dan chat tidak dipulihkan.

## Perilaku demo

- Lahan, tugas, jadwal, ambang, tema, peringatan, log dan hasil soil tester
  tersimpan pada smartphone. Data terpisah menurut lahan.
- Output relay dan pompa kembali mati setelah restart. Telemetri simulasi
  berubah setiap enam detik; interval node fisik di rancangan adalah per jam.
- Timer pompa terpisah dari simulasi sensor. Saat kembali dari background,
  aplikasi memeriksa durasi yang terlampaui. Jadwal berjalan ketika aplikasi
  aktif, bukan sebagai layanan Android di background.
- Jadwal mengikuti jam lokal HP. Hujan >5 mm dan node offline menghalangi
  pemicu otomatis/jadwal; penyiraman manual saat hujan tetap tersedia.
- Soil tester bersifat pengukuran berkala. pH/EC/NPK tidak menjadi input
  irigasi otomatis; probe perlu divalidasi terhadap metode referensi.
- Status baterai, panel surya, arus INA219 dan konektivitas adalah contoh.
- Asisten memakai aturan lokal; tidak ada koneksi LLM atau pengiriman chat.
- MQTT/HTTP, autentikasi pengguna sebenarnya, push notification, otoritas
  aktuator pada Box 2 dan deployment backend belum diaktifkan.

## Pengembangan dan build ulang

Source: `D:\Wahyu\MIKIKO\PROJECT\mikiko-flutter-apps\smart_farming`.

Toolchain: Flutter 3.41.9 / Dart 3.11.5 yang sudah tersedia, Java 21,
Android SDK 36, NDK 28.2, Gradle 8.14, AGP 8.11.1 dan Kotlin 2.2.20.
Java, Android SDK dan Gradle cache berada di `D:\Wahyu\.tools` untuk menghemat
drive C. Flutter dikonfigurasi memakai SDK dan Java tersebut.

```powershell
cd 'D:\Wahyu\MIKIKO\PROJECT\mikiko-flutter-apps\smart_farming'
flutter pub get
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File .\tools\build-demo.ps1
```

Skrip menjalankan pemeriksaan lalu menghasilkan APK di `dist/`.
Untuk pengembangan di HP: `flutter devices`, kemudian `flutter run -d <device-id>`.
Dokumentasi integrasi lanjutan: `BACKEND.md` dan `ESP32.md`.

Sumber rancangan: `MIKIKO V4/MIKIKO_Smart_Farming_Rencana_Pengembangan_Produk_v1.docx`.
Rujukan: [Flutter Android release](https://docs.flutter.dev/deployment/android)
dan [Android SDK Manager](https://developer.android.com/tools/sdkmanager).

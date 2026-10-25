# Firebase backend MIKIKO

Project: **MIKIKO Smart Farming** (`mikiko-smart-farming-q9n33a`).

- [Firebase Console](https://console.firebase.google.com/project/mikiko-smart-farming-q9n33a/overview)
- [Firestore data](https://console.firebase.google.com/project/mikiko-smart-farming-q9n33a/firestore)
- [Authentication](https://console.firebase.google.com/project/mikiko-smart-farming-q9n33a/authentication/users)

Cloud Firestore Standard berada di `asia-southeast2` (Jakarta). Android app
`com.mikiko.smartfarming` dan web app sudah didaftarkan melalui FlutterFire.
Konfigurasi aplikasi berada di `lib/firebase_options.dart` dan
`android/app/google-services.json`. File tersebut adalah konfigurasi client;
tidak mengandung kredensial admin atau service account.

## Data dan identitas

Versi Firebase memakai Firebase Authentication anonim. Identitas tamu
dipertahankan pada instalasi aplikasi yang sama, sehingga demo tetap satu
tombol masuk. Akun Google yang digunakan untuk membuat project adalah akun
pengelola project, bukan akun login pengguna aplikasi.

Data disimpan sebagai dokumen terpisah:

```text
users/{firebaseUid}/
  farms/{farmId}
  schedules/{scheduleId}
  tasks/{taskId}
  alerts/{alertId}
  irrigationLogs/{logId}
  soilMeasurements/{measurementId}
  settings/app
```

Dokumen berisi `payload`, `updatedAt` dari server, dan `mode: simulation`.
Hasil soil tester tetap membawa ID plot, titik, waktu dan status kualitas.
Sampel grafik dikemas menjadi map agar sesuai dengan tipe data Firestore.

Security Rules membatasi akses ke UID masing-masing. Akses tanpa login,
akses pengguna lain, dan penulisan telemetri hardware oleh aplikasi demo
ditolak. Aturan dan indeks dikelola dari `firebase/` dan `firebase.json`.

## Offline, migrasi dan sinkronisasi

- Saat pertama dipasang, versi Firebase memerlukan internet untuk membuat
  identitas anonim dan menghubungi database.
- Data demo lokal v0.2 disalin saat cloud pada instalasi tersebut masih kosong.
  APK baru memakai package dan sertifikat demo yang sama, sehingga bisa
  dipasang sebagai pembaruan APK lama.
- Cache lokal disimpan per UID. Perubahan offline masuk antrean Firestore dan
  dikirim ketika koneksi kembali. Status dan tombol **Sinkron sekarang**
  tersedia di Pengaturan.
- Simulasi sensor tiap enam detik tidak otomatis menghasilkan penulisan
  berbayar ke Firestore setiap tick. Nilai sensor dan grafik disimpan saat
  konfigurasi lahan berubah atau **Sinkron sekarang** dijalankan. Riwayat
  grafik di cloud diringkas menjadi satu sampel per jam.
- Jadwal demo berjalan selama aplikasi aktif; Firebase belum menjalankan
  aktuator atau jadwal melalui server.
- Chat tetap lokal/sementara dan tidak diunggah.

Data tamu terikat identitas instalasi. Menghapus data aplikasi atau mengganti
HP membuat identitas baru; versi ini belum menyediakan akun email/password
atau akses lahan bersama lintas HP. Pertahankan APK v0.2 jika ingin memakai
demo yang sepenuhnya lokal.

## Pengujian dan build

```powershell
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File .\tools\build-demo.ps1
```

Build default menghasilkan `dist/MIKIKO-Smart-Farming-v0.3.0-firebase.apk`.
Gunakan `-Offline` untuk menghasilkan varian lokal tanpa mengaktifkan Firebase.

SDK Firebase terbaru memakai metadata Kotlin 2.4. Konfigurasi Android memakai
Kotlin 2.4.21 dan R8 9.1.29 dengan Gradle 8.14 / AGP 8.11.1. Override R8 berada
di `android/settings.gradle.kts`, mengikuti
[petunjuk resmi R8](https://r8.googlesource.com/r8/+/refs/heads/main/README.md#replacing-r8-in-agp).

Pengujian Security Rules:

```powershell
npm install --prefix .\firebase
$env:JAVA_HOME = 'D:\Wahyu\.tools\java'
$env:Path = $env:JAVA_HOME + '\bin;' + $env:Path
node 'D:\Wahyu\.tools\firebase-cli\node_modules\firebase-tools\lib\bin\firebase.js' emulators:exec --only firestore --project demo-mikiko-smart-farming 'node --test firebase/tests/rules.test.cjs'
```

`firebase/tests/live-smoke.cjs` menguji project sebenarnya: membuat identitas
anonim sementara, menulis/membaca satu dokumen pribadi, menguji penolakan
akses pengguna lain, kemudian menghapus dokumen dan identitas pengujian.

Deploy perubahan aturan dan konfigurasi provider:

```powershell
node 'D:\Wahyu\.tools\firebase-cli\node_modules\firebase-tools\lib\bin\firebase.js' deploy --only firestore,auth --project mikiko-smart-farming-q9n33a
```

Sensor dan kontrol relay masih simulasi. Integrasi ESP32 nyata memerlukan
gateway yang mengirim telemetri dan menangani permintaan kontrol, interlock,
timeout serta acknowledgement dari Box 2. Aturan saat ini sengaja tidak
membuka jalur penulisan hardware dari aplikasi demo.

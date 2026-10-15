# Logo resmi

Letakkan dua file PNG (latar transparan) di folder ini dengan nama **persis** seperti berikut:

| Nama file | Logo | Keterangan |
|---|---|---|
| `mikiko_technology.png` | **Mikiko Technology** | Perusahaan yang memiliki sistem ini |
| `petani_muda_keren.png` | **Petani Muda Keren** | Komunitas yang memayungi aktivitas perusahaan |

Folder ini sudah didaftarkan sebagai aset di `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/logos/
```

Begitu kedua file berada di sini, jalankan ulang aplikasi:

```bash
flutter pub get
flutter run
```

Aplikasi akan **otomatis** memakai logo resmi. Selama file belum ada, aplikasi
menampilkan versi vektor bawaan (digambar dengan kode di
`lib/widgets/brand_logos.dart`) sehingga tampilan tetap rapi.

## Saran ukuran

- `mikiko_technology.png` — tinggi ± 500 px (rasio lebar), latar transparan.
  Versi wordmark berwarna **terang/putih** paling pas karena aplikasi memakai dark mode.
- `petani_muda_keren.png` — tinggi ± 600 px, latar transparan.

## Mengganti nama file

Bila nama file Anda berbeda, ubah konstanta di `lib/theme/palette.dart`:

```dart
class BrandAssets {
  static const String mikiko = 'assets/logos/mikiko_technology.png';
  static const String petaniMudaKeren = 'assets/logos/petani_muda_keren.png';
}
```

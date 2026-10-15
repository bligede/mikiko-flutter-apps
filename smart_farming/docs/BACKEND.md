# Backend Smart Farming — XAMPP / Docker + MySQL + Apache

Dokumen ini adalah **rencana integrasi** backend untuk menggantikan data simulasi
(`lib/data/mock_data.dart`). Aplikasi Flutter saat ini tidak memanggil backend apa pun;
bagian ini disiapkan agar penyambungan berikutnya tinggal mengikuti kontrak di bawah.

---

## 1. Opsi menjalankan

### A. XAMPP (paling cepat untuk pengembangan lokal)

1. Instal XAMPP, jalankan **Apache** + **MySQL**.
2. Salin folder API (PHP) ke `C:\xampp\htdocs\smartfarming\` (Windows) atau `/opt/lampp/htdocs/smartfarming/`.
3. Import skema: buka phpMyAdmin → database `smart_farming` → **Import** `schema.sql`.
4. Uji: `http://localhost/smartfarming/api/farms.php`.

### B. Docker Compose (lebih rapi & portabel)

`docker-compose.yml`:

```yaml
services:
  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: smart_farming
      MYSQL_USER: farming
      MYSQL_PASSWORD: farmingpass
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro

  php:
    image: php:8.2-apache
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./api:/var/www/html
    depends_on:
      - db

  phpmyadmin:
    image: phpmyadmin:latest
    restart: unless-stopped
    ports:
      - "8081:80"
    environment:
      PMA_HOST: db
      PMA_USER: root
      PMA_PASSWORD: rootpass
    depends_on:
      - db

volumes:
  db_data:
```

Jalankan: `docker compose up -d` → API di `http://localhost:8080`, phpMyAdmin di `http://localhost:8081`.

> **Catatan emulator Android:** `localhost` pada emulator menunjuk ke emulator itu sendiri.
> Gunakan `10.0.2.2` untuk mengakses host. Contoh base URL:
> `http://10.0.2.2:8080/api`.

---

## 2. Skema MySQL (`schema.sql`)

```sql
CREATE DATABASE IF NOT EXISTS smart_farming
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smart_farming;

CREATE TABLE users (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(160) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('owner','worker') NOT NULL DEFAULT 'owner',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE farms (
  id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
  name               VARCHAR(160) NOT NULL,
  location           VARCHAR(160),
  crop               VARCHAR(120),
  area_hectare       DECIMAL(6,2) DEFAULT 0,
  owner_id           BIGINT NOT NULL,
  moisture_threshold DECIMAL(5,2) DEFAULT 40,
  irrigation_minutes INT DEFAULT 10,
  auto_irrigation    TINYINT(1) DEFAULT 0,
  pump_on            TINYINT(1) DEFAULT 0,
  created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Multi-user: akses anggota ke lahan
CREATE TABLE farm_members (
  farm_id  BIGINT NOT NULL,
  user_id  BIGINT NOT NULL,
  PRIMARY KEY (farm_id, user_id),
  FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Riwayat pembacaan sensor (satu baris per pengiriman ESP32)
CREATE TABLE sensor_readings (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  farm_id      BIGINT NOT NULL,
  soil_moisture DECIMAL(5,2),
  temperature   DECIMAL(5,2),
  humidity      DECIMAL(5,2),
  pressure      DECIMAL(7,2),
  rain          DECIMAL(5,2),
  recorded_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_farm_time (farm_id, recorded_at),
  FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
);

CREATE TABLE irrigation_schedules (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  farm_id      BIGINT NOT NULL,
  label        VARCHAR(120) NOT NULL,
  hour         TINYINT NOT NULL,
  minute       TINYINT NOT NULL,
  duration_min INT NOT NULL DEFAULT 10,
  weekdays     VARCHAR(20) DEFAULT '',   -- contoh: "1,3,5" (kosong = tiap hari)
  enabled      TINYINT(1) DEFAULT 1,
  FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
);

CREATE TABLE irrigation_logs (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  farm_id      BIGINT NOT NULL,
  started_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  duration_min INT NOT NULL,
  `trigger`    ENUM('Manual','Otomatis','Jadwal') NOT NULL,
  FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
);

CREATE TABLE plant_tasks (
  id       BIGINT AUTO_INCREMENT PRIMARY KEY,
  farm_id  BIGINT NOT NULL,
  title    VARCHAR(200) NOT NULL,
  notes    TEXT,
  type     ENUM('watering','fertilizing','pruning','pestControl','harvest','other') DEFAULT 'other',
  due_at   DATETIME NOT NULL,
  done     TINYINT(1) DEFAULT 0,
  FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
);

CREATE TABLE alerts (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  farm_id    BIGINT NOT NULL,
  title      VARCHAR(160) NOT NULL,
  message    TEXT,
  level      ENUM('info','warning','critical') DEFAULT 'info',
  is_read    TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
);
```

---

## 3. Kontrak REST API

Base URL: `http://<host>/api` — semua respons JSON `{ "success": bool, "data": ..., "message": string }`.
Autentikasi: header `Authorization: Bearer <token>`.

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/auth/login` | Masuk, mengembalikan token + profil |
| POST | `/auth/register` | Daftar akun |
| GET | `/farms` | Daftar lahan milik/anggota pengguna |
| POST | `/farms` | Tambah lahan |
| GET | `/farms/{id}/readings?hours=24` | Riwayat sensor (untuk grafik) |
| GET | `/farms/{id}/latest` | Pembacaan terbaru (untuk kartu sensor) |
| POST | `/farms/{id}/irrigation` | `{ "pump_on": true }` — kontrol manual pompa |
| PUT | `/farms/{id}/settings` | Ambang kelembapan, durasi, mode otomatis |
| GET/POST | `/farms/{id}/schedules` | Jadwal irigasi |
| GET/POST | `/farms/{id}/tasks` | Tugas perawatan |
| PATCH | `/farms/{id}/tasks/{taskId}` | Tandai selesai/belum |
| GET | `/farms/{id}/alerts` | Peringatan |
| POST | `/ingest` | **Endpoint perangkat**: ESP32 mengirim pembacaan sensor |
| POST | `/chat` | Titipkan ke LLM (opsional) |

### Contoh respons `GET /farms/{id}/latest`

```json
{
  "success": true,
  "data": {
    "farm": {
      "id": "1",
      "name": "Kebun Tomat — Blok A",
      "location": "Lembang, Jawa Barat",
      "crop": "Tomat",
      "area_hectare": 0.8,
      "pump_on": false,
      "auto_irrigation": true,
      "moisture_threshold": 40,
      "irrigation_minutes": 10,
      "last_sync": "2026-10-15T12:00:00+07:00"
    },
    "metrics": {
      "soilMoisture": 31.4,
      "temperature": 29.5,
      "humidity": 68.0,
      "pressure": 1009.0,
      "rain": 0.4
    }
  }
}
```

Bentuk ini **sengaja dicocokkan** dengan model Dart di `lib/models/models.dart`
(`Farm`, `SensorMetric`) agar pemetaan JSON → objek sederhana.

### Contoh `POST /ingest` (dari ESP32)

```json
{
  "device_id": "esp32-node-01",
  "farm_id": 1,
  "soil_moisture": 31.4,
  "temperature": 29.5,
  "humidity": 68.0,
  "pressure": 1009.0,
  "rain": 0.4
}
```

---

## 4. Mengganti data simulasi di aplikasi

Buat `lib/data/api_repository.dart` dan ganti pemuatan di `AppState`:

```dart
// lib/data/api_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiRepository {
  ApiRepository({required this.baseUrl, this.token});
  final String baseUrl;      // mis. http://10.0.2.2:8080/api
  final String? token;

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<List<Farm>> fetchFarms() async {
    final res = await http.get(Uri.parse('$baseUrl/farms'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Gagal memuat lahan');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list.map((e) => _farmFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setPump(String farmId, bool on) async {
    await http.post(
      Uri.parse('$baseUrl/farms/$farmId/irrigation'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{'pump_on': on}),
    );
  }

  // _farmFromJson(...) memetakan JSON ke model Farm/SensorMetric.
}
```

Lalu di `AppState`, ganti `MockData.farms()` dengan `_repo.fetchFarms()` dan
panggil endpoint yang sesuai pada `togglePump`, `addSchedule`, `addTask`, dsb.
(Setiap method di `AppState` sudah ditandai komentar `// TODO(api)` untuk ini.)

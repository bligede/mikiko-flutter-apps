# Backend SUBAKO — MQTT + TimescaleDB + Grafana

Dokumen ini menjelaskan backend **nyata** yang dipakai proyek ini, bukan lagi rencana
hipotetis. Sumbernya adalah repo backend:

> **https://github.com/pratamasathya10-coder/subako.esp-now** (branch `main`, HEAD `2c56d02`,
> commit *"Initial commit: SUBAKO IoT monitoring"*, 17 Okt 2026)

Aplikasi Flutter di repo ini **belum** memanggil backend tersebut — masih memakai data
simulasi (`lib/data/mock_data.dart`). Dokumen ini memetakan apa yang sudah tersedia di
backend, apa yang belum, dan kontrak yang perlu dibuat agar aplikasi bisa tersambung.

> Dokumen ini sengaja ditulis mandiri (tanpa tautan ke file aplikasi), sehingga bisa
> disalin apa adanya menjadi `README.md` di repo `subako.esp-now` yang saat ini belum
> punya README.

---

## 1. Arsitektur yang berjalan

```
   Node ESP32 (ESP-NOW)
          │  data sensor
          ▼
   Gateway / node WiFi ──MQTT publish──► Mosquitto :1883
                                              │  topic: subako/sensor
                                              ▼
                                    bridge.py (Python)
                                              │  INSERT
                                              ▼
                                  TimescaleDB :5432  (db: subako)
                                              │
                                              ▼
                                       Grafana :3000
```

Aplikasi Flutter nantinya menjadi **konsumen tambahan** di sisi kanan: membaca data
historis dari database lewat lapisan HTTP, bukan langsung ke MQTT (lihat [§6](#6-yang-belum-ada--celah-yang-harus-ditutup)).

---

## 2. Isi repo backend

| File | Fungsi |
|---|---|
| `docker-compose.yml` | Tiga layanan: `timescaledb` (`timescale/timescaledb:latest-pg16`), `mosquitto` (`eclipse-mosquitto:2`), `grafana` (`grafana/grafana:latest`) |
| `mosquitto/mosquitto.conf` | `listener 1883` + `allow_anonymous true` |
| `bridge/bridge.py` | Subscribe `subako/sensor` → `INSERT` ke tabel `sensor_data` |
| `bridge/simulator.py` | Pemalsu ESP32: publish acak tiap 5 detik |
| `bridge/requirements.txt` | `paho-mqtt==2.1.0`, `psycopg2-binary==2.9.13`, `python-dotenv==1.2.4` |
| `.env.example` | Hanya `POSTGRES_PASSWORD` |
| `grafana/dashboards/subako-dashboard.json` | Dashboard siap impor (±12 KB) |

Database `subako` memakai user `subako`; password diambil dari variabel `POSTGRES_PASSWORD`.

---

## 3. Menjalankan backend

```bash
git clone https://github.com/pratamasathya10-coder/subako.esp-now
cd subako.esp-now

cp .env.example .env         # isi POSTGRES_PASSWORD

docker compose up -d         # TimescaleDB, Mosquitto, Grafana
docker compose ps            # pastikan ketiganya Up
```

Bridge dan simulator dijalankan di host (bukan di dalam Compose):

```bash
cd bridge
python -m venv venv
# Windows: venv\Scripts\activate    |    Linux/macOS: source venv/bin/activate
pip install -r requirements.txt

python simulator.py          # terminal 1 — data uji tiap 5 detik
python bridge.py             # terminal 2 — MQTT → TimescaleDB
```

Cek datanya masuk:

```bash
docker exec -it subako-timescaledb psql -U subako -d subako \
  -c "SELECT * FROM sensor_data ORDER BY time DESC LIMIT 5;"
```

Grafana: <http://localhost:3000> (login awal `admin`/`admin`), lalu impor
`grafana/dashboards/subako-dashboard.json` dan arahkan datasource ke PostgreSQL
`subako-timescaledb:5432`, database `subako`.

**Catatan port:** Grafana memakai **3000**, sama dengan port preview aplikasi Flutter di
dokumen utama. Jalankan salah satunya dengan port berbeda (mis.
`docker compose` → ubah mapping Grafana menjadi `"3001:3000"`) agar tidak bentrok.

---

## 4. Kontrak MQTT (yang benar-benar dipakai)

| Item | Nilai |
|---|---|
| Broker | `localhost:1883` (di-hardcode di `bridge.py` dan `simulator.py`) |
| Topik | `subako/sensor` — satu topik untuk semua perangkat |
| QoS | default (`0`) |
| Format | JSON |

Payload:

```json
{
  "device_id": "ESP32-001",
  "temperature": 28.75,
  "soil_moisture": 61.2
}
```

Hanya tiga field itu yang dibaca `bridge.py`; field lain diabaikan. Nilai yang dipakai
simulator: `temperature` 25–31 °C, `soil_moisture` 30–90 %.

---

## 5. Skema database

Tabel `sensor_data` seperti yang dipakai `bridge.py`:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `time` | `TIMESTAMPTZ` | Diisi `NOW()` oleh bridge (bukan waktu dari perangkat) |
| `device_id` | `TEXT` | Pengenal node, mis. `ESP32-001` |
| `temperature` | `DOUBLE PRECISION` | °C |
| `soil_moisture` | `DOUBLE PRECISION` | % |

Repo backend **tidak menyertakan** file `schema.sql` atau migration — tabel ini dibuat
manual, dan tidak ada pemanggilan `create_hypertable()`. Tanpa itu TimescaleDB hanya
berperilaku seperti PostgreSQL biasa (tanpa kompresi/retensi otomatis). Berikut skema
rujukan yang disarankan, aman dijalankan berulang:

```sql
CREATE TABLE IF NOT EXISTS sensor_data (
  time          TIMESTAMPTZ      NOT NULL,
  device_id     TEXT             NOT NULL,
  temperature   DOUBLE PRECISION,
  soil_moisture DOUBLE PRECISION
);

-- jadikan hypertable (idempotent)
SELECT create_hypertable('sensor_data', 'time', if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS sensor_data_device_time_idx
  ON sensor_data (device_id, time DESC);

-- kompresi data lebih lama dari 7 hari
ALTER TABLE sensor_data SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'device_id'
);
SELECT add_compression_policy('sensor_data', INTERVAL '7 days', if_not_exists => TRUE);

-- agregat 5 menit untuk grafik aplikasi
CREATE MATERIALIZED VIEW IF NOT EXISTS sensor_5m
WITH (timescaledb.continuous) AS
SELECT time_bucket('5 minutes', time) AS bucket,
       device_id,
       avg(temperature)   AS temperature,
       avg(soil_moisture) AS soil_moisture
FROM sensor_data
GROUP BY bucket, device_id;
```

---

## 6. Yang belum ada — celah yang harus ditutup

| Kebutuhan aplikasi | Status di backend |
|---|---|
| Endpoint HTTP untuk membaca data | ❌ Tidak ada. Hanya MQTT dan Grafana |
| `humidity`, `pressure`, `rain` | ❌ Tidak dikirim ESP32, tidak ada kolomnya |
| Tabel/endpoint jadwal, tugas, peringatan | ❌ Belum ada |
| Kendali pompa (relay) | ❌ Belum ada topik perintah |
| Autentikasi / multi-user / peran | ❌ Belum ada |
| Pemetaan `device_id` → lahan (farm) | ❌ Belum ada |
| Backup & retensi data | ❌ Belum ada kebijakan |

### 6a. Lapisan baca HTTP (FastAPI)

Agar aplikasi Flutter bisa menampilkan riwayat sensor, tambahkan satu layanan kecil di
samping `bridge/`. Contoh `bridge/api.py` yang membaca database yang sama:

```python
import os
from datetime import datetime, timedelta

import psycopg2
from dotenv import load_dotenv
from fastapi import FastAPI, Query

load_dotenv()
app = FastAPI(title="SUBAKO Read API")

def db():
    return psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"), port=5432,
        database="subako", user="subako",
        password=os.getenv("POSTGRES_PASSWORD"),
    )

@app.get("/api/health")
def health():
    with db() as c, c.cursor() as cur:
        cur.execute("SELECT 1")
    return {"status": "ok", "time": datetime.utcnow().isoformat()}

@app.get("/api/devices")
def devices():
    with db() as c, c.cursor() as cur:
        cur.execute("SELECT DISTINCT device_id FROM sensor_data ORDER BY 1")
        return [{"device_id": r[0]} for r in cur.fetchall()]

@app.get("/api/devices/{device_id}/readings/latest")
def latest(device_id: str):
    with db() as c, c.cursor() as cur:
        cur.execute(
            """SELECT time, temperature, soil_moisture FROM sensor_data
               WHERE device_id = %s ORDER BY time DESC LIMIT 1""",
            (device_id,),
        )
        row = cur.fetchone()
    if not row:
        return {"device_id": device_id, "reading": None}
    return {"device_id": device_id,
            "reading": {"time": row[0], "temperature": row[1], "soil_moisture": row[2]}}

@app.get("/api/devices/{device_id}/readings")
def readings(device_id: str, hours: int = Query(24, ge=1, le=720)):
    since = datetime.utcnow() - timedelta(hours=hours)
    with db() as c, c.cursor() as cur:
        cur.execute(
            """SELECT bucket, temperature, soil_moisture FROM sensor_5m
               WHERE device_id = %s AND bucket >= %s ORDER BY bucket""",
            (device_id, since),
        )
        return {"device_id": device_id, "points": [
            {"time": r[0], "temperature": r[1], "soil_moisture": r[2]}
            for r in cur.fetchall()
        ]}
```

Jalankan dengan `uvicorn api:app --host 0.0.0.0 --port 8000`
(tambahkan `fastapi` + `uvicorn` ke `requirements.txt`).

### 6b. Pemetaan perangkat → lahan

Aplikasi memakai konsep **lahan (farm)** dengan beberapa sensor; backend hanya mengenal
`device_id`. Tambahkan tabel penghubung:

```sql
CREATE TABLE IF NOT EXISTS device_farm (
  device_id TEXT PRIMARY KEY,
  farm_name TEXT NOT NULL,
  label     TEXT
);
```

### 6c. Kendali pompa

Belum ada jalur perintah. Rancangan yang konsisten dengan topik yang ada:

```
subako/command/{device_id}     # backend → ESP32: {"pump_on": true, "duration_min": 10}
subako/state/{device_id}       # ESP32 → backend: {"pump_on": true}
```

Relay tetap dikendalikan ESP32; aplikasi cukup mengirim perintah ke API, bukan mengaktifkan
pompa sendiri.

---

## 7. Pemetaan field ke aplikasi

| `SensorType` di aplikasi | Label UI | Kolom backend | Status |
|---|---|---|---|
| `soilMoisture` | Kelembapan Tanah | `soil_moisture` | ✅ tersedia |
| `temperature` | Suhu Udara | `temperature` | ✅ tersedia |
| `humidity` | Kelembapan Udara | — | ⚠️ butuh BME280 + kolom baru |
| `pressure` | Tekanan Udara | — | ⚠️ butuh BME280 + kolom baru |
| `rain` | Curah Hujan | — | ⚠️ butuh sensor hujan + kolom baru |

Selama tiga metrik terakhir belum ada di backend, UI sebaiknya menampilkannya sebagai
*tidak tersedia* alih-alih angka simulasi — supaya angka nyata dan angka contoh tidak
tercampur.

Untuk menambahkan metrik baru, perlu tiga perubahan bersamaan:

1. **Payload ESP32** — kirim `humidity`, `pressure`, `rain`.
2. **`bridge.py`** — tambahkan kolom pada `INSERT`.
3. **Skema** — `ALTER TABLE sensor_data ADD COLUMN humidity DOUBLE PRECISION;` (idem untuk
   `pressure`, `rain`), lalu perbarui `sensor_5m`.

---

## 8. Catatan teknis & hal yang perlu dibenahi

Temuan dari membaca kode backend apa adanya:

- **Path `.env` di-hardcode untuk Windows** — `bridge.py` memanggil
  `load_dotenv(r"C:\subako-monitoring\.env")`. Di Linux/macOS/container baris ini gagal
  senyap; ganti dengan `load_dotenv()` agar membaca `.env` di direktori kerja.
- **Host & topik di-hardcode** — `MQTT_BROKER`, `MQTT_PORT`, `MQTT_TOPIC` sebaiknya
  dipindah ke environment variable.
- **`allow_anonymous true`** — broker terbuka untuk siapa pun di jaringan. Untuk produksi
  aktifkan autentikasi (`password_file`) dan/atau TLS `8883`.
- **Tidak ada `create_hypertable()`** — manfaat TimescaleDB (kompresi, retensi, continuous
  aggregate) belum aktif; lihat skema rujukan di §5.
- **Tidak ada retensi** — data akan tumbuh tanpa batas;
  `SELECT add_retention_policy('sensor_data', INTERVAL '1 year');` sebagai titik awal.
- **Waktu dari server** — `NOW()` dipakai, bukan waktu perangkat. Untuk data lapangan yang
  bisa di-buffer saat offline, kirim `ts` dari ESP32 dan simpan itu.
- **Password database polos di `.env`** — sudah benar tidak di-commit (`.gitignore`
  menutup `.env`), tapi pastikan `POSTGRES_PASSWORD` kuat dan tidak dipakai ulang.

---

## 9. Ringkasan status integrasi

| Tahap | Status |
|---|---|
| Ingest ESP32 → MQTT → TimescaleDB | ✅ berjalan (terbukti oleh `bridge.py` + `simulator.py`) |
| Visualisasi operator (Grafana) | ✅ tersedia |
| Lapisan baca HTTP untuk aplikasi | ❌ belum — contoh kode di §6a |
| Penyambungan Flutter ke API | ❌ belum — `MockData` masih dipakai |
| Metrik lengkap (BME280 + hujan) | ❌ belum |
| Kendali pompa, auth, multi-user | ❌ belum |

Langkah berikutnya yang paling masuk akal: pasang `bridge/api.py`, jalankan bersama
`simulator.py`, lalu ganti `MockData` di aplikasi dengan `ApiRepository` berbasis
`package:http` yang mengikuti kontrak di §6a.

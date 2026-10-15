# ESP32 — Pembacaan Sensor & Integrasi

Dokumen ini menjelaskan cara perangkat **ESP32** mengirim data sensor yang dipakai
aplikasi Flutter (soil moisture, BME280, rain sensor) dan menerima perintah pompa.

---

## 1. Perangkat keras

| Sensor | Fungsi | Koneksi umum ke ESP32 |
|---|---|---|
| Soil moisture (kapasitif/resistif) | Kelembapan tanah | Analog `GPIO34` (ADC1) |
| BME280 | Suhu, kelembapan udara, tekanan | I2C — SDA `GPIO21`, SCL `GPIO22` |
| Rain sensor | Deteksi/intensitas hujan | Analog `GPIO35` (ADC1) + digital `GPIO25` |
| Modul relay | Menyalakan pompa | Digital `GPIO26` |

> Pin di atas contoh; sesuaikan dengan board Anda. BME280 memakai alamat I2C `0x76`/`0x77`.

### Konversi nilai

- **Soil moisture**: `ADC 0–4095` → persen. Umumnya nilai basah ~1200, kering ~3500 pada
  sensor kapasitif. Kalibrasi:
  `moisture% = map(adc, DRY_VALUE, WET_VALUE, 0, 100)` lalu `constrain(0, 100)`.
- **Rain**: `0–4095` → `0` (tidak hujan) … `25` mm (sangat lebat), sesuaikan kalibrasi.

---

## 2. Topik MQTT

Struktur topik (siap dipakai backend/broker seperti Mosquitto):

```
smartfarming/{farm_id}/esp32/{device_id}/telemetry     # ESP32 → broker (pembacaan sensor)
smartfarming/{farm_id}/esp32/{device_id}/status        # online/offline (LWT)
smartfarming/{farm_id}/pump/command                    # broker → ESP32 (perintah pompa)
smartfarming/{farm_id}/pump/state                      # ESP32 → broker (status pompa)
```

### Contoh payload `telemetry`

```json
{
  "device_id": "esp32-node-01",
  "farm_id": 1,
  "soil_moisture": 31.4,
  "temperature": 29.5,
  "humidity": 68.0,
  "pressure": 1009.0,
  "rain": 0.4,
  "ts": 1760500000
}
```

### Contoh payload `pump/command`

```json
{ "pump_on": true, "duration_min": 10 }
```

---

## 3. Kerangka sketch Arduino (ringkas)

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_BME280.h>
#include <ArduinoJson.h>

const char* WIFI_SSID = "SSID_ANDA";
const char* WIFI_PASS = "PASSWORD_ANDA";
const char* MQTT_HOST = "192.168.1.10";   // IP broker
const int   MQTT_PORT = 1883;
const char* FARM_ID   = "1";
const char* DEVICE_ID = "esp32-node-01";

const int PIN_SOIL = 34;
const int PIN_RAIN = 35;
const int PIN_RELAY = 26;
const int SOIL_DRY = 3500, SOIL_WET = 1200;

Adafruit_BME280 bme;
WiFiClient net;
PubSubClient mqtt(net);

int soilPercent() {
  int raw = analogRead(PIN_SOIL);
  long pct = map(raw, SOIL_DRY, SOIL_WET, 0, 100);
  return constrain(pct, 0, 100);
}

void publishTelemetry() {
  StaticJsonDocument<256> doc;
  doc["device_id"] = DEVICE_ID;
  doc["farm_id"]   = FARM_ID;
  doc["soil_moisture"] = soilPercent();
  doc["temperature"]   = bme.readTemperature();
  doc["humidity"]      = bme.readHumidity();
  doc["pressure"]      = bme.readPressure() / 100.0F;
  doc["rain"]          = map(analogRead(PIN_RAIN), 0, 4095, 25, 0);
  doc["ts"]            = time(nullptr);

  char buf[256];
  serializeJson(doc, buf);
  String topic = String("smartfarming/") + FARM_ID + "/esp32/" + DEVICE_ID + "/telemetry";
  mqtt.publish(topic.c_str(), buf);
}

void onMessage(char* topic, byte* payload, unsigned int len) {
  StaticJsonDocument<128> doc;
  if (deserializeJson(doc, payload, len)) return;
  if (doc.containsKey("pump_on")) {
    digitalWrite(PIN_RELAY, doc["pump_on"].as<bool>() ? HIGH : LOW);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_RELAY, OUTPUT);
  digitalWrite(PIN_RELAY, LOW);
  Wire.begin();
  bme.begin(0x76);

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) delay(400);

  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMessage);
}

void loop() {
  if (!mqtt.connected()) {
    mqtt.connect(DEVICE_ID);
    String sub = String("smartfarming/") + FARM_ID + "/pump/command";
    mqtt.subscribe(sub.c_str());
  }
  mqtt.loop();
  publishTelemetry();
  delay(5000);   // selaras dengan "interval kirim 5 detik" di aplikasi
}
```

---

## 4. Alur data lengkap

```
ESP32 ──MQTT──► Broker (Mosquitto) ──► Backend (PHP/Node) ──► MySQL
                                            ▲
                                            │ REST (JSON)
                                     Aplikasi Flutter
                                            │
                                     Perintah pompa
                                            ▼
                              Backend ──MQTT──► ESP32 (relay)
```

Aplikasi Flutter hanya berbicara dengan **backend via REST** — tidak langsung ke MQTT —
sehingga aman untuk perangkat mobile dan mudah diaudit.

---

## 5. Tips

- Gunakan **retained message** + **LWT** untuk melacak status online/offline perangkat.
- Simpan `device_id` per lahan agar satu backend bisa melayani banyak node.
- Untuk keamanan: aktifkan autentikasi broker (username/password) dan gunakan TLS
  (`8883`) bila lewat jaringan publik.
- Kalibrasi sensor tanah per lokasi; nilai ADC sangat bergantung pada jenis tanah.

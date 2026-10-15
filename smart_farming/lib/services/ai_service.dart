import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Asisten chatbot AI untuk smart farming.
///
/// MVP ini berjalan **offline** memakai mesin aturan (rule-based) yang
/// membaca data sensor langsung dari [Farm], jadi tidak butuh API key.
///
/// Untuk memakai model LLM sungguhan, isi [endpoint] (mis. Ollama lokal
/// `http://10.0.2.2:11434/api/generate` untuk emulator Android, atau
/// endpoint penyedia gratis pilihan Anda). Bila panggilan gagal, otomatis
/// kembali ke mesin aturan sehingga UI tidak pernah kosong.
class AiAssistantService {
  AiAssistantService({this.endpoint, this.model = 'llama3.2'});

  /// Contoh: `http://10.0.2.2:11434/api/generate` (Ollama dari emulator Android).
  final String? endpoint;
  final String model;

  List<String> get suggestions => const <String>[
        'Bagaimana kondisi kebun saya sekarang?',
        'Apakah tanahnya perlu disiram?',
        'Ringkas kondisi cuaca mikro hari ini',
        'Apa jadwal perawatan terdekat?',
        'Tips meningkatkan hasil panen tomat',
      ];

  Future<String> reply(String prompt, {required Farm farm}) async {
    // Jeda kecil supaya terasa seperti menunggu balasan asisten.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return 'Silakan tulis pertanyaan Anda.';

    if (endpoint != null && endpoint!.isNotEmpty) {
      try {
        final remote = await _callRemote(trimmed, farm);
        if (remote != null && remote.trim().isNotEmpty) return remote.trim();
      } catch (_) {
        // Abaikan dan pakai mesin aturan lokal.
      }
    }
    return _localAnswer(trimmed, farm);
  }

  Future<String?> _callRemote(String prompt, Farm farm) async {
    final response = await http
        .post(
          Uri.parse(endpoint!),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'prompt': '$prompt\n\nKonteks sensor: $context',
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body is Map && body['response'] is String) return body['response'] as String;
    return null;
  }

  /// Ringkasan data sensor yang bisa dipakai model eksternal sebagai konteks.
  String context(Farm farm) {
    final parts = kSensorOrder
        .map((t) => '${t.label}=${farm.value(t).toStringAsFixed(1)}${t.unit}')
        .toList();
    return '${farm.name} (${farm.crop}) — ${parts.join(', ')}';
  }

  String _localAnswer(String prompt, Farm farm) {
    final q = prompt.toLowerCase();

    bool has(List<String> words) => words.any(q.contains);

    if (has(['halo', 'hai', 'hi', 'pagi', 'siang', 'malam'])) {
      return 'Halo! Saya asisten smart farming Anda. Saat ini saya memantau '
          '${farm.name} (${farm.crop}). Tanya apa saja soal kelembapan, irigasi, '
          'hama, atau jadwal perawatan.';
    }

    if (has(['siram', 'air', 'kelembapan tanah', 'soil', 'kering', 'irigasi'])) {
      final m = farm.soilMoisture;
      final gap = m - farm.moistureThreshold;
      final status = gap < 0
          ? 'di bawah ambang (${farm.moistureThreshold.toStringAsFixed(0)}%), jadi penyiraman disarankan.'
          : 'masih aman ${gap.toStringAsFixed(0)} poin di atas ambang (${farm.moistureThreshold.toStringAsFixed(0)}%).';
      final pump = farm.pumpOn ? 'Pompa saat ini MENYALA.' : 'Pompa saat ini mati.';
      return 'Kelembapan tanah ${m.toStringAsFixed(1)}% — $status $pump '
          'Untuk tanaman ${farm.crop}, jaga rentang ideal 55–75% pada fase generatif.';
    }

    if (has(['suhu', 'panas', 'temperatur', 'dingin'])) {
      final t = farm.temperature;
      final advice = t > 33
          ? 'Suhu cukup tinggi; pertimbangkan naungan atau penyiraman pagi lebih awal.'
          : t < 18
              ? 'Suhu relatif rendah; pertumbuhan bisa melambat, kurangi penyiraman.'
              : 'Suhu berada pada rentang nyaman untuk fotosintesis.';
      return 'Suhu udara ${t.toStringAsFixed(1)}°C dan kelembapan ${farm.humidity.toStringAsFixed(0)}%. $advice';
    }

    if (has(['hujan', 'rain', 'cuaca', 'aw an', 'mendung'])) {
      return 'Curah hujan terdeteksi ${farm.rain.toStringAsFixed(1)} mm, tekanan udara '
          '${farm.pressure.toStringAsFixed(0)} hPa. '
          '${farm.rain > 1 ? 'Ada indikasi hujan — tunda irigasi terjadwal.' : 'Cenderung kering — irigasi terjadwal tetap jalan.'}';
    }

    if (has(['pompa', 'pump', 'nyala'])) {
      return 'Status pompa ${farm.name}: ${farm.pumpOn ? 'MENYALA' : 'MATI'}. '
          'Mode irigasi ${farm.autoIrrigation ? 'otomatis (ambang ${farm.moistureThreshold.toStringAsFixed(0)}%)' : 'manual'}. '
          'Jadwal aktif: ${farm.irrigationDurationMinutes} menit per siklus.';
    }

    if (has(['jadwal', 'tugas', 'perawatan', 'reminder', 'pengingat'])) {
      return 'Perawatan rutin ${farm.crop} mencakup pemupukan tiap 10–14 hari, '
          'pemangkasan tunas air mingguan, dan pengamatan hama 2× seminggu. '
          'Buka tab Jadwal untuk menambah atau menandai tugas selesai.';
    }

    if (has(['pupuk', 'nutrisi', 'npk'])) {
      return 'Untuk ${farm.crop}, pemupukan berimbang disarankan: NPK 16-16-16 '
          'saat vegetatif, lalu KCl + P saat pembentukan buah. '
          'Hindari memupuk saat tanah sangat kering — siram tipis dulu.';
    }

    if (has(['hama', 'penyakit', 'ulat', 'wereng', 'jamur'])) {
      return 'Langkah awal pengendalian hama: monitoring mingguan, pasang perangkap, '
          'dan jaga kelembapan kanopi agar tidak terlalu lembap (>85%) karena '
          'memicu jamur. Saat ini kelembapan ${farm.humidity.toStringAsFixed(0)}%.';
    }

    if (has(['panen', 'hasil', 'produksi', 'buah'])) {
      return 'Tomat biasanya siap panen 60–75 hari setelah tanam; padi IR64 sekitar '
          '105 hari. Kualitas panen naik bila kelembapan tanah stabil dan tidak ada '
          'cekaman air mendadak. Skor kesehatan lahan saat ini ${farm.healthScore}/100.';
    }

    if (has(['ringkas', 'kondisi', 'status', 'kesehatan', 'bagaimana'])) {
      return 'Ringkasan ${farm.name} (${farm.crop}):\n'
          '• Kelembapan tanah ${farm.soilMoisture.toStringAsFixed(1)}%\n'
          '• Suhu ${farm.temperature.toStringAsFixed(1)}°C, kelembapan udara ${farm.humidity.toStringAsFixed(0)}%\n'
          '• Tekanan ${farm.pressure.toStringAsFixed(0)} hPa, hujan ${farm.rain.toStringAsFixed(1)} mm\n'
          '• Skor kesehatan ${farm.healthScore}/100\n'
          '${farm.soilMoisture < farm.moistureThreshold ? 'Rekomendasi: segera siram, tanah di bawah ambang.' : 'Kondisi umum baik, lanjutkan jadwal rutin.'}';
    }

    return 'Saya belum menangkap detail pertanyaannya, tapi ini kondisi terkini '
        '${farm.name}: kelembapan tanah ${farm.soilMoisture.toStringAsFixed(1)}%, '
        'suhu ${farm.temperature.toStringAsFixed(1)}°C, skor kesehatan ${farm.healthScore}/100. '
        'Coba tanyakan soal irigasi, hama, pemupukan, atau jadwal perawatan.';
  }
}

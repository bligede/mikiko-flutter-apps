/// Periodic portable measurements; never used as an automatic irrigation input.
class SoilMeasurement {
  const SoilMeasurement({
    required this.id,
    required this.farmId,
    required this.plot,
    required this.point,
    required this.time,
    required this.moisture,
    required this.temperature,
    required this.ph,
    required this.ec,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    this.notes = '',
  });

  final String id;
  final String farmId;
  final String plot;
  final String point;
  final DateTime time;
  final double moisture;
  final double temperature;
  final double ph;
  final double ec;
  final int nitrogen;
  final int phosphorus;
  final int potassium;
  final String notes;

  Map<String, dynamic> toJson() => {
        'measurement_id': id,
        'farm_id': farmId,
        'plot_id': plot,
        'point_id': point,
        'timestamp': time.toIso8601String(),
        'soil_moisture': moisture,
        'soil_temperature': temperature,
        'ph': ph,
        'ec_us_cm': ec,
        'n_mg_kg': nitrogen,
        'p_mg_kg': phosphorus,
        'k_mg_kg': potassium,
        'notes': notes,
        'device_id': 'soil-tester-01',
        'quality': 'simulated',
        'protocol_version': 1,
      };

  factory SoilMeasurement.fromJson(Map<String, dynamic> j) => SoilMeasurement(
        id: j['measurement_id'] as String,
        farmId: j['farm_id'] as String,
        plot: j['plot_id'] as String,
        point: j['point_id'] as String,
        time: DateTime.parse(j['timestamp'] as String),
        moisture: (j['soil_moisture'] as num).toDouble(),
        temperature: (j['soil_temperature'] as num).toDouble(),
        ph: (j['ph'] as num).toDouble(),
        ec: (j['ec_us_cm'] as num).toDouble(),
        nitrogen: j['n_mg_kg'] as int,
        phosphorus: j['p_mg_kg'] as int,
        potassium: j['k_mg_kg'] as int,
        notes: j['notes'] as String? ?? '',
      );
}

enum DemoScenario { normal, dry, rain, offline }

extension DemoScenarioInfo on DemoScenario {
  String get label => switch (this) {
        DemoScenario.normal => 'Normal',
        DemoScenario.dry => 'Tanah kering',
        DemoScenario.rain => 'Hujan',
        DemoScenario.offline => 'Node offline',
      };
}

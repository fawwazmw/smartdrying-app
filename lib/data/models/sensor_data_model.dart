// lib/data/models/sensor_data_model.dart

class SensorData {
  final double temperature;
  final double humidity;
  final String rackStatus;
  final DateTime recordedAt;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.rackStatus,
    required this.recordedAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    double parseDoubleSafe(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return SensorData(
      temperature: parseDoubleSafe(json['temperature']),
      humidity: parseDoubleSafe(json['humidity']),
      rackStatus: json['rack_status'] as String? ?? 'unknown',
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : DateTime.now(),
    );
  }
}
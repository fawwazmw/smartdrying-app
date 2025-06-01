// lib/data/models/device_model.dart

class Device {
  final int id;
  final String name;
  final String location;
  // final int userId; // Tambahkan jika diperlukan dan ada di API

  Device({
    required this.id,
    required this.name,
    required this.location,
    // required this.userId,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: int.parse(json['id'] as String? ?? '0'),
      name: json['device_name'] as String? ?? 'N/A',
      location: json['location'] as String? ?? 'N/A',
      // userId: int.parse(json['user_id'] as String? ?? '0'),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import model yang sudah dipisah
import '../../data/models/device_model.dart';
import '../../data/models/sensor_data_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State untuk data dinamis
  String _location = "Memuat...";
  String _temperature = "--°C";
  String _weatherCondition = "Cerah"; // Masih statis, perlu API cuaca jika ingin dinamis
  IconData _weatherIcon = Icons.wb_sunny_outlined; // Ikon cuaca default
  String _rackStatus = "Memuat...";
  String _rackStatusDescription = "Status Jemuran";
  IconData _rackIcon = Icons.help_outline; // Ikon status jemuran default
  String _humidity = "--%";
  String _humidityDescription = "Memuat...";
  String _deviceOnlineStatus = "Online"; // Masih statis, perlu logika/API status device
  String _lastActivity = "Memuat...";

  bool _isLoading = true;
  Timer? _timer; // Untuk auto-refresh (opsional)

  final String _apiUrl = 'http://192.168.0.136:8081/api'; // Pastikan URL ini benar
  static const String _tokenKey = 'jwt_token';
  int? _deviceIdForDashboard;

  @override
  void initState() {
    super.initState();
    // _debugPrint("initState called"); // Hapus atau komentari print debug
    _initializeDashboard();
    // _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _fetchDashboardData(showLoadingIndicator: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fungsi untuk mencetak pesan debug hanya dalam mode debug
  // void _debugPrint(String message) {
  //   assert(() {
  //     print("DashboardScreen: $message");
  //     return true;
  //   }());
  // }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_tokenKey);
    // _debugPrint("Token retrieved from SharedPreferences: $token");
    return token;
  }

  static Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    // print('DashboardScreen: Token deleted from SharedPreferences.'); // Bisa dipertahankan jika penting untuk log
  }

  Future<void> _initializeDashboard() async {
    // _debugPrint("_initializeDashboard called");
    if (!mounted) return;

    if (!_isLoading) { // Hanya set isLoading jika belum true
      setState(() { _isLoading = true; });
    }

    final String? token = await _getToken();

    if (token == null || token.isEmpty) {
      // _debugPrint("Token is null or empty, redirecting to login.");
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }

    // _debugPrint("Token found, attempting to fetch devices.");
    try {
      final devicesResponse = await http.get(
        Uri.parse('$_apiUrl/devices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15)); // Timeout sedikit lebih lama

      // _debugPrint("Devices API Response Status: ${devicesResponse.statusCode}");
      // _debugPrint("Devices API Response Body: ${devicesResponse.body}");

      if (mounted) {
        if (devicesResponse.statusCode == 200) {
          final responseBody = jsonDecode(devicesResponse.body);
          final List<dynamic>? devicesList = responseBody['data'] as List<dynamic>? ?? (responseBody is List ? responseBody : null);

          if (devicesList != null && devicesList.isNotEmpty) {
            final firstDevice = Device.fromJson(devicesList[0] as Map<String, dynamic>);
            _deviceIdForDashboard = firstDevice.id;
            setState(() {
              _location = firstDevice.location;
            });
            // _debugPrint("Device ID $_deviceIdForDashboard selected. Location: $_location. Fetching sensor data...");
            await _fetchDashboardData(showLoadingIndicator: false);
          } else {
            // _debugPrint("No devices found for this user.");
            setState(() {
              _location = "Device tidak ada";
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anda belum memiliki device terdaftar.'), backgroundColor: Colors.orange),
              );
            }
          }
        } else {
          // _debugPrint("Failed to load devices, status: ${devicesResponse.statusCode}");
          String errorMessage = 'Gagal memuat daftar device.';
          try {
            final responseData = jsonDecode(devicesResponse.body);
            errorMessage = responseData['message'] as String? ?? errorMessage;
            if (devicesResponse.statusCode == 401) {
              errorMessage = "Sesi Anda telah berakhir. Silakan login kembali.";
              await _deleteToken();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            }
          } catch (_) { /* Gagal parse JSON error, gunakan pesan default */ }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
            setState(() { _isLoading = false; _location = "Gagal Memuat"; });
          }
        }
      }
    } catch (e) {
      // _debugPrint("Error in _initializeDashboard: ${e.toString()}");
      if (mounted) {
        setState(() { _isLoading = false; _location = "Error Koneksi"; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mendapatkan device: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchDashboardData({bool showLoadingIndicator = true}) async {
    // _debugPrint("_fetchDashboardData called for device ID: $_deviceIdForDashboard");
    if (_deviceIdForDashboard == null) {
      // _debugPrint("No device ID available for fetching sensor data.");
      if (mounted && showLoadingIndicator) {
        await _initializeDashboard(); // Coba inisialisasi ulang jika device ID tidak ada
        if(_deviceIdForDashboard == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada device yang dipilih.'), backgroundColor: Colors.orange),
          );
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    if (!mounted) return;
    if (showLoadingIndicator && !_isLoading) {
      setState(() { _isLoading = true; });
    }

    final String? token = await _getToken();
    if (token == null || token.isEmpty) {
      // _debugPrint("Token missing during sensor data fetch, redirecting.");
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }

    // _debugPrint("Fetching sensor data with token.");
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/devices/$_deviceIdForDashboard/sensor-data?limit=1&orderBy=recorded_at&direction=desc'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      // _debugPrint("Sensor Data API Response Status: ${response.statusCode}");
      // _debugPrint("Sensor Data API Response Body: ${response.body}");

      if (mounted) {
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final List<dynamic>? sensorDataList = responseBody['data'] as List<dynamic>? ?? (responseBody is List ? responseBody : null);

          if (sensorDataList != null && sensorDataList.isNotEmpty) {
            final latestSensorData = SensorData.fromJson(sensorDataList[0] as Map<String, dynamic>);
            setState(() {
              _temperature = "${latestSensorData.temperature.toStringAsFixed(1)}°C";
              _rackStatus = latestSensorData.rackStatus == 'open' ? 'Terbuka' : 'Tertutup';
              _rackStatusDescription = _rackStatus == "Terbuka" ? "Jemuran sedang terbuka" : "Jemuran sedang tertutup";
              _rackIcon = _rackStatus == "Terbuka" ? Icons.check_circle_outline : Icons.highlight_off_outlined;
              _humidity = "${latestSensorData.humidity.toStringAsFixed(1)}%";
              _humidityDescription = "Kelembaban udara saat ini";
              _lastActivity = "Update: ${DateFormat('dd MMM yy, HH:mm', 'id_ID').format(latestSensorData.recordedAt.toLocal())}";
            });
          } else {
            // _debugPrint("No sensor data found for device $_deviceIdForDashboard.");
            setState(() {
              _temperature = "--°C"; _rackStatus = "Data Kosong"; _humidity = "--%";
              _lastActivity = "Belum ada data sensor";
            });
          }
        } else {
          String errorMessage = 'Gagal memuat data sensor.';
          try {
            final responseData = jsonDecode(response.body);
            errorMessage = responseData['message'] as String? ?? errorMessage;
            if (response.statusCode == 401) {
              errorMessage = "Sesi Anda telah berakhir. Silakan login kembali.";
              await _deleteToken();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            }
          } catch (_) { /* Gagal parse JSON error, gunakan pesan default */ }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      // _debugPrint("Error in _fetchDashboardData: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat data sensor: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    Color? iconColor,
    Color? cardColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: cardColor ?? theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: iconColor ?? theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("SmartDrying App"),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _isLoading ? null : () => _fetchDashboardData(showLoadingIndicator: true),
            tooltip: "Segarkan Data",
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined, color: theme.colorScheme.primary),
            onPressed: () async {
              await _DashboardScreenState._deleteToken();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
            tooltip: "Logout",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchDashboardData(showLoadingIndicator: true),
        color: theme.colorScheme.primary,
        child: _isLoading && _location == "Memuat..."
            ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ))
            : ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildInfoCard(
              title: _location,
              value: _temperature,
              description: _weatherCondition,
              icon: _weatherIcon,
              iconColor: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildInfoCard(
                  title: "Jemuran",
                  value: _rackStatus,
                  description: _rackStatusDescription,
                  icon: _rackIcon,
                  iconColor: _rackStatus == "Terbuka" ? Colors.green.shade600 : Colors.redAccent.shade400,
                ),
                _buildInfoCard(
                  title: "Kelembaban",
                  value: _humidity,
                  description: _humidityDescription,
                  icon: Icons.water_drop_outlined,
                  iconColor: Colors.blue.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              color: theme.colorScheme.secondaryContainer.withOpacity(0.8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Icon(
                  _deviceOnlineStatus == "Online" ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                  color: _deviceOnlineStatus == "Online" ? theme.colorScheme.primary : Colors.grey.shade600,
                  size: 32,
                ),
                title: Text(
                  "Status Perangkat: $_deviceOnlineStatus",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                subtitle: Text(
                  _lastActivity,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer.withAlpha(200),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

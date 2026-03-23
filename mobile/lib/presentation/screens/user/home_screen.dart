import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/esp32_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  
  int _devicesOnline = 0;
  int _totalDevices = 8;
  int _activeSchedules = 0;
  int _activeAlerts = 0;
  bool _esp32Connected = false;
  final ESP32Service _esp32Service = ESP32Service();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      // Load sensor data
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );
      await sensorProvider.fetchLatestData();

      if (!mounted) return;
      // Load device status
      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );
      await deviceProvider.fetchDeviceStatus();
      if (!mounted) return;
      final devices = deviceProvider.devices;
      setState(() {
        _devicesOnline = devices
            .where((d) => d['status'] == 'ON' || d['status'] == 'AUTO')
            .length;
        _totalDevices = devices.length;
      });

      if (!mounted) return;
      // Load ESP32 status
      final esp32Result = await _esp32Service.getESP32Status();
      if (!mounted) return;
      if (esp32Result['success'] == true && esp32Result['data'] != null) {
        final esp32Data = esp32Result['data'];
        setState(() {
          _esp32Connected = esp32Data['isOnline'] ?? false;
        });
      } else {
        setState(() {
          _esp32Connected = false;
        });
      }

      if (!mounted) return;
      // Load schedules
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );
      await scheduleProvider.fetchSchedules(limit: 1000);
      if (!mounted) return;
      setState(() {
        _activeSchedules = scheduleProvider.schedules
            .where((s) => s['enabled'] == true)
            .length;
      });

      if (!mounted) return;
      // Load alerts
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      await alertProvider.fetchAlerts(status: 'active', limit: 1000);
      if (!mounted) return;
      setState(() {
        _activeAlerts = alertProvider.alerts.length;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
      setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          if (sensorProvider.isLoading &&
              sensorProvider.latestData == null &&
              _loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sensorData = sensorProvider.latestData;
          final hasError = sensorProvider.errorMessage != null;

          if (hasError && sensorData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(sensorProvider.errorMessage ?? 'Có lỗi xảy ra'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // System Stats
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Thống kê hệ thống',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Tính số cột dựa trên chiều rộng màn hình
                          final screenWidth = MediaQuery.of(context).size.width;
                          int crossAxisCount = 2; // Mặc định 2 cột

                          if (screenWidth > 600) {
                            crossAxisCount = 3; // Tablet: 3 cột
                          }
                          if (screenWidth > 900) {
                            crossAxisCount = 4; // Desktop: 4 cột
                          }

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                            childAspectRatio: crossAxisCount == 2 ? 0.75 : 0.8,
                        children: [
                              _buildStatCard(
                                icon: Icons.devices,
                                value: _loading ? '...' : '$_devicesOnline/8',
                                label: 'Thiết bị đang hoạt động',
                                color: Colors.cyan,
                              ),
                              _buildStatCard(
                                icon: Icons.calendar_today,
                                value: _loading ? '...' : '$_activeSchedules',
                                label: 'Lịch trình',
                            color: Colors.green,
                          ),
                              _buildStatCard(
                                icon: Icons.warning,
                                value: _loading ? '...' : '$_activeAlerts',
                                label: 'Cảnh báo',
                            color: Colors.orange,
                          ),
                        ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Environment Data
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông số môi trường',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tất cả thông số hiển thị 1 dòng
                      _buildEnvCard(
                        icon: Icons.water_drop,
                        label: 'Độ ẩm không khí',
                        value:
                            sensorData != null &&
                                sensorData['humidity'] != null
                                ? '${(sensorData['humidity']['value'] as num).toStringAsFixed(1)}%'
                                : '...',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildEnvCard(
                        icon: Icons.thermostat,
                        label: 'Nhiệt độ',
                        value:
                            sensorData != null &&
                                sensorData['temperature'] != null
                                ? '${(sensorData['temperature']['value'] as num).toStringAsFixed(1)}°C'
                                : '...',
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildEnvCard(
                        icon: Icons.wb_sunny,
                        label: 'Ánh sáng',
                        value:
                            sensorData != null &&
                                sensorData['light'] != null
                                ? '${(sensorData['light']['value'] as num).toStringAsFixed(1)}%'
                                : '...',
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      _buildEnvCard(
                        icon: Icons.grass,
                        label: 'Độ ẩm đất',
                        value:
                            sensorData != null &&
                                sensorData['soil_moisture'] != null
                                ? '${(sensorData['soil_moisture']['value'] as num).toStringAsFixed(1)}%'
                                : '...',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildEnvCard(
                        icon: Icons.water,
                        label: 'Mực nước',
                        value:
                            sensorData != null &&
                                sensorData['water_level'] != null
                                ? '${(sensorData['water_level']['value'] as num).toStringAsFixed(1)} cm'
                                : '...',
                        color: Colors.cyan,
                      ),
                  ],
                  ),
                ),
                const SizedBox(height: 16),

                // ESP32 Status Card
                _buildEsp32StatusCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsp32StatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _esp32Connected ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _esp32Connected ? Icons.wifi : Icons.wifi_off,
                  color: _esp32Connected ? Colors.green[600] : Colors.red[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái kết nối',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ESP32',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _esp32Connected ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _esp32Connected
                        ? Colors.green[600]
                        : Colors.red[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _esp32Connected ? 'Trực tuyến' : 'Ngoại tuyến',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _esp32Connected
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.devices, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Thiết bị: $_devicesOnline/$_totalDevices',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

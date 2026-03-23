import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/esp32_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;

  int _totalUsers = 0;
  int _totalAdmins = 0;
  int _activeAlerts = 0;
  int _activeSchedules = 0;
  int _devicesOnline = 0;

  double? _temperature;
  double? _humidity;
  double? _soilMoisture;
  double? _waterLevel;
  double? _light;

  bool _esp32Connected = false;
  final ESP32Service _esp32Service = ESP32Service();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadSensorData() async {
    try {
      final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
      await sensorProvider.fetchLatestData();
      
      if (sensorProvider.latestData != null) {
        final data = sensorProvider.latestData!;
        setState(() {
          _temperature = (data['temperature']?['value'] as num?)?.toDouble();
          _humidity = (data['humidity']?['value'] as num?)?.toDouble();
          _soilMoisture = (data['soil_moisture']?['value'] as num?)?.toDouble();
          _waterLevel = (data['water_level']?['value'] as num?)?.toDouble();
          _light = (data['light']?['value'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error loading sensor data: $e');
    }
  }

  Future<void> _loadOtherData() async {
    if (!mounted) return;
    try {
      // Load users
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUsers(limit: 1000);
      
      if (!mounted) return;
      final users = userProvider.users;
      setState(() {
        _totalUsers = users.length;
        _totalAdmins = users.where((u) => u['role'] == 'admin').length;
      });

      // Load alerts
      if (!mounted) return;
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      await alertProvider.fetchAlerts(status: 'active', limit: 1000);
      if (!mounted) return;
      setState(() {
        _activeAlerts = alertProvider.alerts.length;
      });

      // Load schedules
      if (!mounted) return;
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      await scheduleProvider.fetchSchedules(limit: 1000);
      if (!mounted) return;
      setState(() {
        _activeSchedules = scheduleProvider.schedules.where((s) => s['enabled'] == true).length;
      });

      // Load device status
      if (!mounted) return;
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.fetchDeviceStatus();
      if (!mounted) return;
      final devices = deviceProvider.devices;
      setState(() {
        _devicesOnline = devices.where((d) => 
          d['status'] == 'ON' || d['status'] == 'AUTO'
        ).length;
      });

      // Load ESP32 status
      if (!mounted) return;
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
    } catch (e) {
      debugPrint('Error loading other data: $e');
    } finally {
      if (mounted) {
      setState(() {
        _loading = false;
      });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    await Future.wait([_loadSensorData(), _loadOtherData()]);
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản trị hệ thống'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              Icon(Icons.analytics, color: AppColors.primary, size: 24),
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
                                crossAxisCount = 5; // Desktop: 5 cột
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
                                icon: Icons.people,
                                value: _loading ? '...' : '$_totalUsers',
                                label: 'Người dùng',
                                color: Colors.blue,
                              ),
                              _buildStatCard(
                                icon: Icons.shield,
                                value: _loading ? '...' : '$_totalAdmins',
                                label: 'Quản trị viên',
                                color: AppColors.primary,
                              ),
                              _buildStatCard(
                                icon: Icons.warning,
                                value: _loading ? '...' : '$_activeAlerts',
                                label: 'Cảnh báo',
                                color: Colors.orange,
                              ),
                              _buildStatCard(
                                icon: Icons.calendar_today,
                                value: _loading ? '...' : '$_activeSchedules',
                                label: 'Lịch trình',
                                color: Colors.green,
                              ),
                              _buildStatCard(
                                icon: Icons.devices,
                                value: _loading ? '...' : '$_devicesOnline/8',
                                    label: 'Thiết bị đang hoạt động',
                                color: Colors.cyan,
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
                            value: _loading || _humidity == null
                                ? '...'
                                : '${_humidity!.toStringAsFixed(1)}%',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                              _buildEnvCard(
                                icon: Icons.thermostat,
                                label: 'Nhiệt độ',
                            value: _loading || _temperature == null
                                    ? '...'
                                : '${_temperature!.toStringAsFixed(1)}°C',
                                color: Colors.red,
                              ),
                          const SizedBox(height: 12),
                              _buildEnvCard(
                            icon: Icons.wb_sunny,
                            label: 'Ánh sáng',
                            value: _loading || _light == null
                                    ? '...'
                                : '${_light!.toStringAsFixed(1)}%',
                            color: Colors.amber,
                              ),
                          const SizedBox(height: 12),
                              _buildEnvCard(
                                icon: Icons.grass,
                                label: 'Độ ẩm đất',
                            value: _loading || _soilMoisture == null
                                    ? '...'
                                : '${_soilMoisture!.toStringAsFixed(1)}%',
                                color: Colors.green,
                              ),
                          const SizedBox(height: 12),
                              _buildEnvCard(
                                icon: Icons.water,
                                label: 'Mực nước',
                            value: _loading || _waterLevel == null
                                    ? '...'
                                : '${_waterLevel!.toStringAsFixed(1)} cm',
                                color: Colors.cyan,
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ESP32 Status Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _esp32Connected 
                                          ? Colors.green[50] 
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _esp32Connected ? Icons.wifi : Icons.wifi_off,
                                      color: _esp32Connected 
                                          ? Colors.green[600] 
                                          : Colors.red[600],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Trạng thái kết nối',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'ESP32',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: _handleRefresh,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _esp32Connected 
                                  ? Colors.green[100] 
                                  : Colors.red[100],
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.signal_cellular_alt, size: 20, color: Colors.grey[400]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Trạng thái kết nối',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _esp32Connected 
                                          ? 'Hoạt động bình thường' 
                                          : 'Mất kết nối',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.devices, size: 20, color: Colors.grey[400]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thiết bị đang hoạt động',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_devicesOnline/8',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!_esp32Connected) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                border: Border.all(color: Colors.red[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ESP32 đang ngoại tuyến. Không thể điều khiển thiết bị.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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


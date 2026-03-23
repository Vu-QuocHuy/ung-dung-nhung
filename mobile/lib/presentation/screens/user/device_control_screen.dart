import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  final Map<String, Map<String, dynamic>> _deviceConfig = {
    'pump': {
      'displayName': 'Bơm nước',
      'icon': Icons.water_drop,
      'color': 'blue',
    },
    'fan': {'displayName': 'Quạt', 'icon': Icons.air, 'color': 'cyan'},
    'light': {
      'displayName': 'Đèn (Tất cả)',
      'icon': Icons.lightbulb,
      'color': 'yellow',
    },
    'servo_door': {
      'displayName': 'Cửa ra vào (Servo)',
      'icon': Icons.rotate_90_degrees_ccw,
      'color': 'purple',
    },
    'servo_feed': {
      'displayName': 'Cho ăn (Servo)',
      'icon': Icons.rotate_90_degrees_ccw,
      'color': 'purple',
    },
    'led_farm': {
      'displayName': 'Đèn trồng cây',
      'icon': Icons.flash_on,
      'color': 'green',
    },
    'led_animal': {
      'displayName': 'Đèn khu vật nuôi',
      'icon': Icons.flash_on,
      'color': 'orange',
    },
    'led_hallway': {
      'displayName': 'Đèn hành lang',
      'icon': Icons.flash_on,
      'color': 'pink',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    await deviceProvider.fetchDeviceStatus();
  }

  Future<void> _setDeviceStatus(String deviceName, String targetStatus) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    // Convert targetStatus to action
    String action;
    if (targetStatus == 'ON') {
      action = 'on';
    } else if (targetStatus == 'OFF') {
      action = 'off';
    } else {
      action = 'auto';
    }

    final success = await deviceProvider.controlDevice(deviceName, action);

    if (!mounted) return;

    if (success) {
      // Refresh device status after successful control
      await deviceProvider.fetchDeviceStatus();

      if (!mounted) return;

      final actionLabel = targetStatus == 'ON'
          ? 'bật'
          : targetStatus == 'OFF'
          ? 'tắt'
          : 'chuyển sang tự động';
      final config = _deviceConfig[deviceName];
      final displayName = config?['displayName'] ?? deviceName;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName đã được $actionLabel'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deviceProvider.errorMessage ?? 'Điều khiển thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getColor(String? colorName, bool isActive) {
    if (!isActive) return Colors.grey[400]!;

    switch (colorName) {
      case 'blue':
        return Colors.blue[600]!;
      case 'cyan':
        return Colors.cyan[600]!;
      case 'yellow':
      case 'amber':
        return Colors.amber[600]!;
      case 'purple':
        return Colors.purple[600]!;
      case 'green':
        return Colors.green[600]!;
      case 'orange':
        return Colors.orange[600]!;
      case 'pink':
        return Colors.pink[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Điều khiển thiết bị'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: Consumer<DeviceProvider>(
              builder: (context, deviceProvider, child) {
                if (deviceProvider.isLoading &&
                    deviceProvider.devices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải...'),
                      ],
                    ),
                  );
                }

                if (deviceProvider.errorMessage != null &&
                    deviceProvider.devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(deviceProvider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDevices,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final devices = deviceProvider.devices;

                return RefreshIndicator(
                  onRefresh: _loadDevices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final deviceName = device['deviceName'] ?? '';
                      final status = (device['status'] ?? '')
                          .toString()
                          .toUpperCase();
                      final isActive = status == 'ON' || status == 'AUTO';
                      final isServo =
                          deviceName == 'servo_door' ||
                          deviceName == 'servo_feed';

                      final config =
                          _deviceConfig[deviceName] ??
                          {
                            'displayName': deviceName,
                            'icon': Icons.power,
                            'color': 'gray',
                          };

                      final icon = config['icon'] as IconData;
                      final displayName = config['displayName'] as String;

                      // Safely get color name - handle both String and Color types
                      String colorName = 'gray';
                      final colorValue = config['color'];
                      if (colorValue is String) {
                        colorName = colorValue;
                      } else if (colorValue is Color) {
                        // Fallback for old code that might have Color objects
                        colorName = 'gray';
                      }

                      final color = _getColor(colorName, isActive);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? color : Colors.grey[200]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon and Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? color.withValues(alpha: 0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isActive ? color : Colors.grey[400],
                                    size: 32,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status == 'AUTO'
                                        ? Colors.yellow[100]
                                        : status == 'ON'
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: status == 'AUTO'
                                        ? Border.all(
                                            color: Colors.yellow[300]!,
                                            width: 1,
                                          )
                                        : status == 'ON'
                                        ? Border.all(
                                            color: Colors.green[300]!,
                                            width: 1,
                                          )
                                        : Border.all(
                                            color: Colors.red[300]!,
                                            width: 1,
                                          ),
                                  ),
                                  child: Text(
                                    isServo
                                        ? (status == 'AUTO'
                                              ? 'Tự động'
                                              : 'Sẵn sàng')
                                        : (status == 'AUTO'
                                              ? 'Tự động'
                                              : status == 'ON'
                                              ? 'Hoạt động'
                                              : 'Tắt'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: status == 'AUTO'
                                          ? Colors.amber[800]
                                          : status == 'ON'
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Device Name
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Control Buttons
                            if (isServo)
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _setDeviceStatus(deviceName, 'ON'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100],
                                        foregroundColor: Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Thực hiện',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _setDeviceStatus(
                                        deviceName,
                                        status == 'AUTO' ? 'OFF' : 'AUTO',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status == 'AUTO'
                                            ? Colors.white
                                            : Colors.grey[100],
                                        foregroundColor: status == 'AUTO'
                                            ? Colors.amber[700]
                                            : Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: status == 'AUTO'
                                              ? BorderSide(
                                                  color: Colors.amber[400]!,
                                                  width: 1.5,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                      child: Text(
                                        status == 'AUTO'
                                            ? 'Tắt tự động'
                                            : 'Bật tự động',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: status == 'ON'
                                          ? null
                                          : () => _setDeviceStatus(
                                              deviceName,
                                              'ON',
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status == 'ON'
                                            ? Colors.green[50]
                                            : Colors.grey[100],
                                        foregroundColor: status == 'ON'
                                            ? Colors.green[700]
                                            : Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: status == 'ON'
                                              ? BorderSide(
                                                  color: Colors.green[400]!,
                                                  width: 1.5,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                      child: const Text(
                                        'Bật',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: status == 'OFF'
                                          ? null
                                          : () => _setDeviceStatus(
                                              deviceName,
                                              'OFF',
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status == 'OFF'
                                            ? Colors.red[50]
                                            : Colors.grey[100],
                                        foregroundColor: status == 'OFF'
                                            ? Colors.red[700]
                                            : Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: status == 'OFF'
                                              ? BorderSide(
                                                  color: Colors.red[400]!,
                                                  width: 1.5,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                      child: const Text(
                                        'Tắt',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: status == 'AUTO'
                                          ? null
                                          : () => _setDeviceStatus(
                                              deviceName,
                                              'AUTO',
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status == 'AUTO'
                                            ? Colors.white
                                            : Colors.grey[100],
                                        foregroundColor: status == 'AUTO'
                                            ? Colors.amber[700]
                                            : Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: status == 'AUTO'
                                              ? BorderSide(
                                                  color: Colors.amber[400]!,
                                                  width: 1.5,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                      child: const Text(
                                        'Tự động',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class ThresholdSettingsScreen extends StatefulWidget {
  const ThresholdSettingsScreen({super.key});

  @override
  State<ThresholdSettingsScreen> createState() =>
      _ThresholdSettingsScreenState();
}

class _ThresholdSettingsScreenState extends State<ThresholdSettingsScreen> {
  bool _loading = true;

  final Map<String, Map<String, dynamic>> _sensorConfig = {
    'temperature': {
      'displayName': 'Nhiệt độ',
      'icon': Icons.thermostat,
      'unit': '°C',
      'color': Colors.red,
    },
    'soil_moisture': {
      'displayName': 'Độ ẩm đất',
      'icon': Icons.grass,
      'unit': '%',
      'color': Colors.green,
    },
    'light': {
      'displayName': 'Ánh sáng',
      'icon': Icons.wb_sunny,
      'unit': '%',
      'color': Colors.amber,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    setState(() {
      _loading = true;
    });
    final provider = Provider.of<ThresholdProvider>(context, listen: false);
    await provider.fetchThresholds();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _toggleThreshold(String sensorType, bool currentStatus) async {
    final provider = Provider.of<ThresholdProvider>(context, listen: false);
    final success = await provider.toggleThreshold(sensorType, !currentStatus);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật trạng thái ngưỡng'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadThresholds();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'info':
        return 'Thông tin';
      case 'warning':
        return 'Cảnh báo';
      case 'critical':
        return 'Nghiêm trọng';
      default:
        return severity;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài đặt ngưỡng'),
                ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: Consumer<ThresholdProvider>(
              builder: (context, provider, child) {
                if (_loading && provider.thresholds.isEmpty) {
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

                if (provider.errorMessage != null && provider.thresholds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadThresholds,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final thresholds = provider.thresholds;

                if (thresholds.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có cài đặt ngưỡng nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadThresholds,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: thresholds.map((threshold) {
                      if (threshold == null) {
                        return const SizedBox.shrink();
                      }
                      
                      final thresholdMap = _convertToMap(threshold);
                      if (thresholdMap.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      final sensorType = thresholdMap['sensorType']?.toString();
                      if (sensorType == null || sensorType.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      if (!_sensorConfig.containsKey(sensorType)) {
                        return const SizedBox.shrink();
                      }
                      
                      final config = _sensorConfig[sensorType];
                      if (config == null) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildThresholdCard(thresholdMap, config);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      return <String, dynamic>{};
    }
  }

  Widget _buildThresholdCard(
    Map<String, dynamic> threshold,
    Map<String, dynamic> config,
  ) {
    final sensorType = threshold['sensorType']?.toString() ?? '';
    final thresholdValue = threshold['thresholdValue'];
    final severity = threshold['severity']?.toString() ?? 'warning';
    final isActive = threshold['isActive'] ?? false;
    final displayName = config['displayName']?.toString() ?? '';
    final icon = config['icon'] as IconData? ?? Icons.info;
    final color = config['color'] as Color? ?? Colors.grey;
    final unit = config['unit']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[200]! : Colors.grey[200]!,
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? color : Colors.grey[400],
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(severity).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getSeverityLabel(severity),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getSeverityColor(severity),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green[100]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Đang bật' : 'Tắt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Threshold Value
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ngưỡng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thresholdValue != null
                            ? '${(thresholdValue is num ? thresholdValue : double.tryParse(thresholdValue.toString()) ?? 0).toStringAsFixed(1)} $unit'
                            : '--',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mức độ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSeverityLabel(severity),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getSeverityColor(severity),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _toggleThreshold(sensorType, isActive),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.orange[50]
                        : Colors.green[50],
                    foregroundColor: isActive
                        ? Colors.orange[700]
                        : Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isActive ? 'Tắt' : 'Bật'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(context, threshold, config),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDelete(context, sensorType),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> threshold,
    Map<String, dynamic> config,
  ) {
    if (threshold.isEmpty || config.isEmpty) {
      return;
    }
    
    final provider = Provider.of<ThresholdProvider>(context, listen: false);
    final sensorType = threshold['sensorType']?.toString() ?? '';
    
    if (sensorType.isEmpty) {
      return;
    }
    
    final thresholdController = TextEditingController(
      text: threshold['thresholdValue']?.toString() ?? '',
    );
    String severity = threshold['severity']?.toString() ?? 'warning';
    bool isActive = threshold['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chỉnh sửa ngưỡng: ${config['displayName']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Giá trị ngưỡng',
                    suffixText: config['unit']?.toString() ?? '',
                    prefixIcon: const Icon(Icons.trending_up),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: thresholdController,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(
                    labelText: 'Mức độ cảnh báo',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Thông tin')),
                    DropdownMenuItem(value: 'warning', child: Text('Cảnh báo')),
                    DropdownMenuItem(value: 'critical', child: Text('Nghiêm trọng')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => severity = v);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Kích hoạt cảnh báo'),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final thresholdValue = double.tryParse(thresholdController.text);
                
                if (thresholdValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập giá trị ngưỡng hợp lệ')),
                  );
                  return;
                }

                final payload = {
                  'sensorType': sensorType,
                  'thresholdValue': thresholdValue,
                  'severity': severity,
                  'isActive': isActive,
                };

                final ok = await provider.updateThreshold(sensorType, payload);

                if (context.mounted) {
                  if (ok) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật ngưỡng thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadThresholds();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage ?? 'Cập nhật thất bại'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String sensorType) {
    final provider = Provider.of<ThresholdProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ngưỡng'),
        content: Text('Bạn có chắc chắn muốn xóa cài đặt ngưỡng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final ok = await provider.deleteThreshold(sensorType);
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã xóa ngưỡng'
                        : provider.errorMessage ?? 'Xóa thất bại'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
              if (ok) await _loadThresholds();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

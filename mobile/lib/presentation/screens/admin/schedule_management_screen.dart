import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  bool _loading = true;
  Map<String, dynamic>? _selectedSchedule;

  final Map<String, String> _deviceNames = {
    'pump': 'Bơm nước',
    'fan': 'Quạt',
    'servo_door': 'Cửa ra vào (servo)',
    'servo_feed': 'Cho ăn (servo)',
    'led_farm': 'Đèn khu trồng trọt',
    'led_animal': 'Đèn khu chuồng trại',
    'led_hallway': 'Đèn hành lang',
  };

  final List<Map<String, dynamic>> _daysOfWeek = [
    {'id': 0, 'label': 'CN'},
    {'id': 1, 'label': 'T2'},
    {'id': 2, 'label': 'T3'},
    {'id': 3, 'label': 'T4'},
    {'id': 4, 'label': 'T5'},
    {'id': 5, 'label': 'T6'},
    {'id': 6, 'label': 'T7'},
  ];

  final List<Map<String, dynamic>> _devices = [
    {'id': 'pump', 'name': 'Bơm nước'},
    {'id': 'fan', 'name': 'Quạt'},
    {'id': 'servo_door', 'name': 'Cửa ra vào (servo)'},
    {'id': 'servo_feed', 'name': 'Cho ăn (servo)'},
    {'id': 'led_farm', 'name': 'Đèn khu trồng trọt'},
    {'id': 'led_animal', 'name': 'Đèn khu chuồng trại'},
    {'id': 'led_hallway', 'name': 'Đèn hành lang'},
  ];

  Map<String, dynamic> _newSchedule = {
    'name': '',
    'deviceName': 'pump',
    'action': 'ON',
    'startTime': '',
    'endTime': '',
    'daysOfWeek': <int>[],
  };

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _loading = true;
    });
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    await provider.fetchSchedules();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _toggleSchedule(String scheduleId, bool currentStatus) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final success = await provider.toggleScheduleStatus(scheduleId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật trạng thái lịch trình'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý lịch trình'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _newSchedule = {
                  'name': '',
                  'deviceName': 'pump',
                  'action': 'ON',
                  'startTime': '',
                  'endTime': '',
                  'daysOfWeek': <int>[],
                };
              });
              _showAddScheduleDialog();
            },
            tooltip: 'Thêm lịch trình',
          ),
        ],
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (context, provider, child) {
                if (_loading && provider.schedules.isEmpty) {
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

                if (provider.errorMessage != null &&
                    provider.schedules.isEmpty) {
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
                        Text(provider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSchedules,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final schedules = provider.schedules;

                if (schedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có lịch trình nào',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _newSchedule = {
                                'name': '',
                                'deviceName': 'pump',
                                'action': 'ON',
                                'startTime': '',
                                'endTime': '',
                                'daysOfWeek': <int>[],
                              };
                            });
                            _showAddScheduleDialog();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo lịch trình đầu tiên'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadSchedules,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = _convertToMap(schedules[index]);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildScheduleCard(schedule),
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

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final scheduleId = schedule['_id']?.toString() ?? '';
    final name = schedule['name']?.toString() ?? '';
    final deviceName = schedule['deviceName']?.toString() ?? '';
    final deviceDisplayName = _deviceNames[deviceName] ?? deviceName;
    final enabled = schedule['enabled'] ?? false;
    final startTime = schedule['startTime']?.toString() ?? '';
    final endTime = schedule['endTime']?.toString() ?? '';
    final daysOfWeek = schedule['daysOfWeek'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.purple[200]! : Colors.grey[200]!,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: enabled ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  enabled ? 'Hoạt động' : 'Tắt',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời gian',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$startTime - $endTime',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Days of week
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ngày trong tuần',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _daysOfWeek.map((day) {
                    final isSelected = daysOfWeek.contains(day['id']);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        day['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.purple[700]
                              : Colors.grey[500],
                        ),
                      ),
                    );
                  }).toList(),
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
                  onPressed: () => _toggleSchedule(scheduleId, enabled),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enabled
                        ? Colors.orange[50]
                        : Colors.green[50],
                    foregroundColor: enabled
                        ? Colors.orange[700]
                        : Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    enabled ? 'Tắt' : 'Bật',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedSchedule = Map<String, dynamic>.from(schedule);
                  });
                  _showEditScheduleDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.edit, size: 18),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => _confirmDelete(scheduleId, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm lịch trình mới'),
          content: SingleChildScrollView(
            child: _buildScheduleForm(_newSchedule, (key, value) {
              setDialogState(() {
                _newSchedule[key] = value;
              });
            }, true),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _newSchedule = {
                    'name': '',
                    'deviceName': 'pump',
                    'action': 'ON',
                    'startTime': '',
                    'endTime': '',
                    'daysOfWeek': <int>[],
                  };
                });
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_newSchedule['name']?.toString().isEmpty ?? true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ thông tin'),
                    ),
                  );
                  return;
                }
                if ((_newSchedule['daysOfWeek'] as List).isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn ít nhất một ngày'),
                    ),
                  );
                  return;
                }
                if (_newSchedule['startTime'] >= _newSchedule['endTime']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thời gian bắt đầu phải nhỏ hơn thời gian kết thúc',
                      ),
                    ),
                  );
                  return;
                }

                final provider = Provider.of<ScheduleProvider>(
                  context,
                  listen: false,
                );
                final payload = {
                  'name': _newSchedule['name'],
                  'deviceName': _newSchedule['deviceName'],
                  'action': _newSchedule['action'],
                  'startTime': _newSchedule['startTime'],
                  'endTime': _newSchedule['endTime'],
                  'daysOfWeek': _newSchedule['daysOfWeek'],
                  'enabled': true,
                };

                final success = await provider.createSchedule(payload);

                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context);
                    setState(() {
                      _newSchedule = {
                        'name': '',
                        'deviceName': 'pump',
                        'action': 'ON',
                        'startTime': '',
                        'endTime': '',
                        'daysOfWeek': <int>[],
                      };
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thêm lịch trình thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadSchedules();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? 'Thêm lịch trình thất bại',
                        ),
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
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditScheduleDialog() {
    if (_selectedSchedule == null) return;

    final schedule = Map<String, dynamic>.from(_selectedSchedule!);

    showDialog(
      context: context,
      builder: (context) {
        final editSchedule = Map<String, dynamic>.from(schedule);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Chỉnh sửa lịch trình'),
            content: SingleChildScrollView(
              child: _buildScheduleForm(editSchedule, (key, value) {
                setDialogState(() {
                  editSchedule[key] = value;
                });
              }, false),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSchedule = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = Provider.of<ScheduleProvider>(
                    context,
                    listen: false,
                  );
                  final scheduleId = editSchedule['_id']?.toString() ?? '';

                  final payload = {
                    'name': editSchedule['name'],
                    'deviceName': editSchedule['deviceName'],
                    'action': editSchedule['action'],
                    'startTime': editSchedule['startTime'],
                    'endTime': editSchedule['endTime'],
                    'daysOfWeek': editSchedule['daysOfWeek'],
                    'enabled': editSchedule['enabled'] ?? true,
                  };

                  final success = await provider.updateSchedule(
                    scheduleId,
                    payload,
                  );

                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedSchedule = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật lịch trình thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      await _loadSchedules();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.errorMessage ?? 'Cập nhật thất bại',
                          ),
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
        );
      },
    );
  }

  Widget _buildScheduleForm(
    Map<String, dynamic> schedule,
    Function(String, dynamic) onUpdate,
    bool isNew,
  ) {
    final nameController = TextEditingController(
      text: schedule['name']?.toString() ?? '',
    );
    nameController.addListener(() {
      onUpdate('name', nameController.text);
    });

    String deviceName = schedule['deviceName']?.toString() ?? 'pump';
    String action = schedule['action']?.toString() ?? 'ON';
    String startTime = schedule['startTime']?.toString() ?? '';
    String endTime = schedule['endTime']?.toString() ?? '';
    List<int> daysOfWeek =
        (schedule['daysOfWeek'] as List<dynamic>?)
            ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .toList() ??
        [];
    bool enabled = schedule['enabled'] ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên lịch trình',
            hintText: 'Ví dụ: Tưới sáng',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: deviceName,
          decoration: const InputDecoration(labelText: 'Thiết bị'),
          items: _devices.map((device) {
            return DropdownMenuItem(
              value: device['id'] as String,
              child: Text(device['name'] as String),
            );
          }).toList(),
          onChanged: isNew
              ? (value) {
                  if (value != null) onUpdate('deviceName', value);
                }
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: action,
          decoration: const InputDecoration(labelText: 'Hành động'),
          items: const [
            DropdownMenuItem(value: 'ON', child: Text('Bật')),
            DropdownMenuItem(value: 'OFF', child: Text('Tắt')),
            DropdownMenuItem(value: 'AUTO', child: Text('Tự động')),
          ],
          onChanged: (value) {
            if (value != null) onUpdate('action', value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian bắt đầu',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await _showTimePicker(context, startTime);
                      if (time != null) {
                        onUpdate('startTime', time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            startTime.isEmpty ? 'Chọn thời gian' : startTime,
                            style: TextStyle(
                              color: startTime.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian kết thúc',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await _showTimePicker(context, endTime);
                      if (time != null) {
                        onUpdate('endTime', time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            endTime.isEmpty ? 'Chọn thời gian' : endTime,
                            style: TextStyle(
                              color: endTime.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Ngày trong tuần',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daysOfWeek.map((day) {
            final isSelected = daysOfWeek.contains(day['id']);
            return InkWell(
              onTap: () {
                final dayId = day['id'] as int;
                final newDays = List<int>.from(daysOfWeek);
                if (isSelected) {
                  newDays.remove(dayId);
                } else {
                  newDays.add(dayId);
                }
                onUpdate('daysOfWeek', newDays);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng chọn ít nhất một ngày',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        if (!isNew) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Kích hoạt lịch trình'),
              const Spacer(),
              Switch(
                value: enabled,
                onChanged: (value) => onUpdate('enabled', value),
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<String?> _showTimePicker(
    BuildContext context,
    String initialTime,
  ) async {
    TimeOfDay? initial;
    if (initialTime.isNotEmpty) {
      try {
        final parts = initialTime.split(':');
        initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {
        initial = TimeOfDay.now();
      }
    } else {
      initial = TimeOfDay.now();
    }

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  void _confirmDelete(String scheduleId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch trình'),
        content: Text('Bạn có chắc chắn muốn xóa lịch trình này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final provider = Provider.of<ScheduleProvider>(
                context,
                listen: false,
              );
              final success = await provider.deleteSchedule(scheduleId);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa lịch trình'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadSchedules();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Xóa thất bại'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

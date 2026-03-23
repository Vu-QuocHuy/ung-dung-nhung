import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final List<String> _daysOfWeekLabels = [
    'CN',
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final scheduleProvider = Provider.of<ScheduleProvider>(
      context,
      listen: false,
    );
    await scheduleProvider.fetchSchedules(isActive: 'true');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch trình của tôi'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showScheduleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm lịch'),
            )
          : null,
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, child) {
          if (scheduleProvider.isLoading &&
              scheduleProvider.schedules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (scheduleProvider.errorMessage != null &&
              scheduleProvider.schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(scheduleProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSchedules,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final schedules = scheduleProvider.schedules;
          final total = schedules.length;
          final activeCount = schedules
              .where((s) => (s['enabled'] ?? s['isActive']) == true)
              .length;

          return RefreshIndicator(
            onRefresh: _loadSchedules,
            child: schedules.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có lịch trình nào',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Admin sẽ tạo lịch trình cho bạn',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStats(total: total, active: activeCount),
                      const SizedBox(height: 16),
                      ..._buildGroupedSchedules(schedules),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildStats({required int total, required int active}) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Tổng lịch',
            value: '$total',
            icon: Icons.event_note,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Đang hoạt động',
            value: '$active',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSchedules(List<dynamic> schedules) {
    final groupedSchedules = <String, List<dynamic>>{};

    for (var schedule in schedules) {
      final deviceName = schedule['deviceName'] ?? 'Unknown';
      if (!groupedSchedules.containsKey(deviceName)) {
        groupedSchedules[deviceName] = [];
      }
      groupedSchedules[deviceName]!.add(schedule);
    }

    final widgets = <Widget>[];
    groupedSchedules.forEach((deviceName, deviceSchedules) {
      widgets.add(_buildDeviceSection(deviceName, deviceSchedules));
      widgets.add(const SizedBox(height: 12));
    });

    return widgets;
  }

  Widget _buildDeviceSection(String deviceName, List<dynamic> schedules) {
    IconData deviceIcon;
    Color deviceColor;
    String displayName;

    switch (deviceName) {
      case 'pump':
        deviceIcon = Icons.water_drop;
        deviceColor = AppColors.waterLevel;
        displayName = 'Bơm nước';
        break;
      case 'fan':
        deviceIcon = Icons.air;
        deviceColor = AppColors.humidity;
        displayName = 'Quạt';
        break;
      case 'light':
        deviceIcon = Icons.lightbulb;
        deviceColor = AppColors.light;
        displayName = 'Đèn';
        break;
      default:
        deviceIcon = Icons.power;
        deviceColor = AppColors.primary;
        displayName = deviceName;
    }

    return Card(
      child: ExpansionTile(
        leading: Icon(deviceIcon, color: deviceColor),
        title: Text(
          displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${schedules.length} lịch',
          style: TextStyle(
            fontSize: 12,
            color: deviceColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: schedules
            .map((schedule) => Column(
                  children: [
                    _buildScheduleItem(schedule),
                    const Divider(height: 1),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildScheduleItem(dynamic schedule) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final scheduleProvider = context.read<ScheduleProvider>();
    final action = schedule['action'] ?? 'on';
    final time = schedule['time'] ?? '--:--';
    final daysOfWeek = schedule['daysOfWeek'] as List<dynamic>? ?? [];
    final isActive = (schedule['enabled'] ?? schedule['isActive']) as bool? ?? true;
    final id = schedule['_id'] as String?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: action == 'on'
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          action == 'on' ? Icons.power_settings_new : Icons.power_off,
          color: action == 'on' ? AppColors.success : AppColors.error,
        ),
      ),
      title: Row(
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: action == 'on' ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              action == 'on' ? 'BẬT' : 'TẮT',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: daysOfWeek.contains(i)
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _daysOfWeekLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: daysOfWeek.contains(i)
                          ? Colors.white
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin && id != null)
            Switch(
              value: isActive,
              activeThumbColor: AppColors.success,
              onChanged: (val) async {
                final ok = await scheduleProvider.toggleScheduleStatus(id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (val ? 'Đã bật lịch' : 'Đã tắt lịch')
                        : scheduleProvider.errorMessage ?? 'Thao tác thất bại'),
                  ),
                );
                if (ok && mounted) {
                  await _loadSchedules(); // Refresh list to stay in sync
                }
              },
            )
          else
            Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: isActive ? AppColors.success : AppColors.textTertiary,
            ),
          if (isAdmin && id != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Chỉnh sửa lịch',
              onPressed: () {
                _showScheduleDialog(schedule: schedule);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
              tooltip: 'Xóa lịch',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xóa lịch'),
                    content: const Text('Bạn có chắc muốn xóa lịch trình này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final ok = await scheduleProvider.deleteSchedule(id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                            ? 'Đã xóa lịch'
                            : scheduleProvider.errorMessage ?? 'Xóa thất bại'),
                      ),
                    );
                  if (ok) {
                    await _loadSchedules(); // Refresh list after delete
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showScheduleDialog({Map<String, dynamic>? schedule}) {
    final isEdit = schedule != null;
    final scheduleProvider = context.read<ScheduleProvider>();

    final nameCtrl = TextEditingController(text: schedule?['name'] ?? '');
    String deviceName = schedule?['deviceName'] ?? 'pump';
    String action = schedule?['action'] ?? 'on';
    bool enabled = (schedule?['enabled'] ?? schedule?['isActive']) ?? true;

    TimeOfDay selectedTime;
    try {
      if (schedule != null && schedule['time'] != null) {
        final parts = schedule['time'].toString().split(':');
        selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else {
        selectedTime = const TimeOfDay(hour: 6, minute: 0);
      }
    } catch (_) {
      selectedTime = const TimeOfDay(hour: 6, minute: 0);
    }

    Set<int> selectedDays =
        schedule != null && schedule['daysOfWeek'] != null
            ? Set<int>.from(schedule['daysOfWeek'] as List)
            : <int>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit ? 'Chỉnh sửa lịch trình' : 'Thêm lịch trình'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên lịch trình',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: deviceName,
                    decoration: const InputDecoration(
                      labelText: 'Thiết bị',
                      prefixIcon: Icon(Icons.devices),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pump', child: Text('Bơm')),
                      DropdownMenuItem(value: 'fan', child: Text('Quạt')),
                      DropdownMenuItem(value: 'light', child: Text('Đèn')),
                      DropdownMenuItem(value: 'servo', child: Text('Servo')),
                    ],
                    onChanged: isEdit
                        ? null
                        : (val) {
                            if (val != null) {
                              setStateDialog(() => deviceName = val);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: action,
                    decoration: const InputDecoration(
                      labelText: 'Hành động',
                      prefixIcon: Icon(Icons.settings),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'on', child: Text('Bật')),
                      DropdownMenuItem(value: 'off', child: Text('Tắt')),
                      DropdownMenuItem(value: 'auto', child: Text('Tự động')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => action = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Thời gian'),
                    subtitle: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ngày trong tuần',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      final selected = selectedDays.contains(i);
                      return ChoiceChip(
                        label: Text(_daysOfWeekLabels[i]),
                        selected: selected,
                        onSelected: (_) {
                          setStateDialog(() {
                            if (selected) {
                              selectedDays.remove(i);
                            } else {
                              selectedDays.add(i);
                            }
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Kích hoạt'),
                      const SizedBox(width: 8),
                      Switch(
                        value: enabled,
                        onChanged: (v) => setStateDialog(() => enabled = v),
                        activeThumbColor: AppColors.success,
                      )
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
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên lịch trình')),
                    );
                    return;
                  }
                  if (selectedDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chọn ít nhất một ngày')),
                    );
                    return;
                  }

                  final timeStr =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  final payload = {
                    'name': nameCtrl.text.trim(),
                    'deviceName': deviceName,
                    'action': action,
                    'time': timeStr,
                    'daysOfWeek': selectedDays.toList(),
                    'enabled': enabled,
                  };

                  bool ok;
                  if (isEdit && schedule['_id'] != null) {
                    ok = await scheduleProvider.updateSchedule(
                      schedule['_id'],
                      payload,
                    );
                  } else {
                    ok = await scheduleProvider.createSchedule(payload);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? (isEdit ? 'Đã cập nhật lịch' : 'Đã tạo lịch')
                            : scheduleProvider.errorMessage ??
                                'Thao tác thất bại'),
                      ),
                    );
                  }

                  if (ok && context.mounted) {
                    Navigator.pop(context);
                    await _loadSchedules();
                  }
                },
                child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }
}

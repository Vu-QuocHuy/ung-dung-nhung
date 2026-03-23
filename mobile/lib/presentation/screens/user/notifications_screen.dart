import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/services.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filterMode = 'status'; // 'status' | 'severity'
  String _statusFilter = 'all'; // 'all' | 'resolved' | 'unresolved'
  String _severityFilter = 'all'; // 'all' | 'critical' | 'warning' | 'info'
  bool _showTypeDropdown = false;
  bool _showValueDropdown = false;
  int _currentPage = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts(resetPage: true);
  }

  Future<void> _loadAlerts({bool resetPage = false, bool loadMore = false}) async {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    
    if (resetPage) {
      _currentPage = 1;
    } else if (loadMore) {
      _currentPage++;
    }
    
    if (loadMore) {
      setState(() => _loadingMore = true);
    }
    
    // Build filter params
    String? status;
    String? severity;
    
    if (_filterMode == 'status') {
      if (_statusFilter == 'unresolved') {
        status = 'active';
      } else if (_statusFilter == 'resolved') {
        status = 'resolved';
      }
    } else {
      if (_severityFilter != 'all') {
        severity = _severityFilter;
      }
    }
    
    await alertProvider.fetchAlerts(
      page: _currentPage,
      limit: 20,
      status: status,
      severity: severity,
      append: loadMore,
    );
    
    if (loadMore && mounted) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateAlertDialog(context),
              tooltip: 'Tạo thông báo',
            ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          if (alertProvider.isLoading && alertProvider.alerts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (alertProvider.errorMessage != null &&
              alertProvider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(alertProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAlerts,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final all = alertProvider.alerts;
          final pagination = alertProvider.pagination;
          final totalPages = (pagination['pages'] as int?) ?? 1;
          final hasMore = _currentPage < totalPages;
          
          // Use alerts directly from server (already filtered)
          final filtered = all;

          String getCurrentValueLabel() {
            if (_filterMode == 'status') {
              if (_statusFilter == 'all') return 'Tất cả';
              if (_statusFilter == 'unresolved') return 'Chưa xử lý';
              if (_statusFilter == 'resolved') return 'Đã xử lý';
            } else {
              if (_severityFilter == 'all') return 'Tất cả';
              if (_severityFilter == 'critical') return 'Nghiêm trọng';
              if (_severityFilter == 'warning') return 'Cảnh báo';
              if (_severityFilter == 'info') return 'Thông tin';
            }
            return 'Tất cả';
          }

          return Stack(
            children: [
              // Background gesture detector (đặt trước để không chặn dropdown)
              if (_showTypeDropdown || _showValueDropdown)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _showTypeDropdown = false;
                          _showValueDropdown = false;
                        });
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              RefreshIndicator(
            onRefresh: () => _loadAlerts(resetPage: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                // Filters
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      // Type Dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showTypeDropdown = !_showTypeDropdown;
                              _showValueDropdown = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                                  child: Text(
                                    _filterMode == 'status' ? 'Trạng thái' : 'Mức độ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                      ),
                    ),
                    const SizedBox(width: 8),
                      // Value Dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showValueDropdown = !_showValueDropdown;
                              _showTypeDropdown = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                    Expanded(
                                  child: Text(
                                    getCurrentValueLabel(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                      ),
                    ),
                  ],
                  ),
                ),
                const SizedBox(height: 16),
                // List
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: Column(
                      children: const [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: AppColors.textTertiary),
                        SizedBox(height: 8),
                        Text('Không có thông báo'),
                      ],
                    ),
                  )
                else
                  ...filtered.map<Widget>((notification) {
                    final status =
                        (notification['status'] ?? 'active').toString();
                    final severity =
                        (notification['severity'] ?? 'info').toString();
                    final createdAt =
                        notification['createdAt'] ?? notification['timestamp'];
                    final title = notification['title'] as String?;
                    final message = notification['message'] as String? ?? '';

                    // Get severity config
                    Color borderColor;
                    Color iconBgColor;
                    Color iconColor;
                    IconData icon;
                    String severityLabel;
                    
                    if (severity == 'critical') {
                      borderColor = Colors.red[500]!;
                      iconBgColor = Colors.red[50]!;
                      iconColor = Colors.red[600]!;
                      icon = Icons.error;
                      severityLabel = 'Nghiêm trọng';
                    } else if (severity == 'warning') {
                      borderColor = Colors.orange[500]!;
                      iconBgColor = Colors.orange[50]!;
                      iconColor = Colors.orange[600]!;
                      icon = Icons.warning;
                      severityLabel = 'Cảnh báo';
                    } else {
                      borderColor = Colors.blue[500]!;
                      iconBgColor = Colors.blue[50]!;
                      iconColor = Colors.blue[600]!;
                      icon = Icons.info;
                      severityLabel = 'Thông tin';
                    }

                    // Format message
                    String formattedMessage = message
                        .replaceAll(RegExp(r'water_level', caseSensitive: false), 'mực nước')
                        .replaceAll(RegExp(r'soil_moisture', caseSensitive: false), 'độ ẩm đất')
                        .replaceAll(RegExp(r'temperature', caseSensitive: false), 'nhiệt độ')
                        .replaceAll(RegExp(r'humidity', caseSensitive: false), 'độ ẩm không khí')
                        .replaceAll(RegExp(r'light', caseSensitive: false), 'ánh sáng');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: iconBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: iconColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title ?? (formattedMessage.isNotEmpty 
                                              ? formattedMessage 
                                              : severityLabel),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                                          vertical: 4,
                        ),
                          decoration: BoxDecoration(
                                          color: status == 'resolved'
                                              ? Colors.green[100]
                                              : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                                        child: Text(
                                          status == 'resolved' ? 'Đã xử lý' : 'Chưa xử lý',
                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: status == 'resolved'
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 4),
                            Text(
                                    _formatTime(createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  if (title != null && formattedMessage.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      formattedMessage,
                              style: const TextStyle(
                                        fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                                  ],
                                  const SizedBox(height: 12),
                            Row(
                              children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: severity == 'critical'
                                              ? Colors.red[100]
                                              : severity == 'warning'
                                                  ? Colors.orange[100]
                                                  : Colors.blue[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          severityLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: severity == 'critical'
                                                ? Colors.red[700]
                                                : severity == 'warning'
                                                    ? Colors.orange[700]
                                                    : Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                      if (status == 'active' && isAdmin) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () async {
                                            final alertService = AlertService();
                                            final result = await alertService.resolveAlert(notification['_id'].toString());
                                            if (result['success'] == true) {
                                              _loadAlerts();
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Xử lý',
                                              style: TextStyle(
                                    fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                    );
                  }),
                  // Pagination - Load More button
                  if (hasMore && !_loadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _loadAlerts(loadMore: true),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Xem thêm'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  // Pagination info
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'Trang $_currentPage / $totalPages',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
              // Dropdown menus overlay (đặt sau background để nhận tap events)
              if (_showTypeDropdown)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: false,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDropdownItem(
                              'Trạng thái',
                              _filterMode == 'status',
                              () {
                                debugPrint('Selected filter mode: status');
                                if (mounted) {
                                  setState(() {
                                    _filterMode = 'status';
                                    _statusFilter = 'all';
                                    _showTypeDropdown = false;
                                  });
                                  _loadAlerts(resetPage: true);
                                }
                              },
                            ),
                            _buildDropdownItem(
                              'Mức độ',
                              _filterMode == 'severity',
                              () {
                                debugPrint('Selected filter mode: severity');
                                if (mounted) {
                                  setState(() {
                                    _filterMode = 'severity';
                                    _severityFilter = 'all';
                                    _showTypeDropdown = false;
                                  });
                                  _loadAlerts(resetPage: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showValueDropdown)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: false,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: _filterMode == 'status'
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDropdownItem(
                                  'Tất cả',
                                  _statusFilter == 'all',
                                  () {
                                    debugPrint('Selected status filter: all');
                                    if (mounted) {
                                      setState(() {
                                        _statusFilter = 'all';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                                _buildDropdownItem(
                                  'Đã xử lý',
                                  _statusFilter == 'resolved',
                                  () {
                                    debugPrint('Selected status filter: resolved');
                                    if (mounted) {
                                      setState(() {
                                        _statusFilter = 'resolved';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                                _buildDropdownItem(
                                  'Chưa xử lý',
                                  _statusFilter == 'unresolved',
                                  () {
                                    debugPrint('Selected status filter: unresolved');
                                    if (mounted) {
                                      setState(() {
                                        _statusFilter = 'unresolved';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDropdownItem(
                                  'Tất cả',
                                  _severityFilter == 'all',
                                  () {
                                    debugPrint('Selected severity filter: all');
                                    if (mounted) {
                                      setState(() {
                                        _severityFilter = 'all';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                                _buildDropdownItem(
                                  'Nghiêm trọng',
                                  _severityFilter == 'critical',
                                  () {
                                    debugPrint('Selected severity filter: critical');
                                    if (mounted) {
                                      setState(() {
                                        _severityFilter = 'critical';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                                _buildDropdownItem(
                                  'Cảnh báo',
                                  _severityFilter == 'warning',
                                  () {
                                    debugPrint('Selected severity filter: warning');
                                    if (mounted) {
                                      setState(() {
                                        _severityFilter = 'warning';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                                _buildDropdownItem(
                                  'Thông tin',
                                  _severityFilter == 'info',
                                  () {
                                    debugPrint('Selected severity filter: info');
                                    if (mounted) {
                                      setState(() {
                                        _severityFilter = 'info';
                                        _showValueDropdown = false;
                                      });
                                      _loadAlerts(resetPage: true);
                                    }
                                  },
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final DateTime dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${difference.inDays} ngày trước';
      }
    } catch (e) {
      return '';
    }
  }

  void _showCreateAlertDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String severity = 'info';
    bool targetAll = true;
    List<String> selectedUserIds = [];
    bool loadingUsers = false;
    List<dynamic> users = [];
    bool usersFetched = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          // Fetch users when dialog first opens
          if (!usersFetched && !loadingUsers) {
            setDialogState(() {
              loadingUsers = true;
              usersFetched = true;
            });
            Provider.of<UserProvider>(builderContext, listen: false)
                .fetchUsers(limit: 100)
                .then((_) {
              if (dialogContext.mounted) {
                final userProvider =
                    Provider.of<UserProvider>(builderContext, listen: false);
                setDialogState(() {
                  users = List.from(userProvider.users);
                  loadingUsers = false;
                });
              }
            }).catchError((e) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  loadingUsers = false;
                });
              }
            });
          }

          return AlertDialog(
            title: const Text('Tạo thông báo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: severity,
                    decoration: const InputDecoration(
                      labelText: 'Mức độ',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'info',
                        child: Text('Thông tin'),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('Cảnh báo'),
                      ),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Nghiêm trọng'),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        severity = val ?? 'info';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Người nhận',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<bool>(
                    title: const Text('Gửi cho tất cả người dùng'),
                    value: true,
                    groupValue: targetAll,
                    onChanged: (val) {
                      setDialogState(() {
                        targetAll = val ?? true;
                        if (targetAll) {
                          selectedUserIds = [];
                        }
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Chọn người dùng cụ thể'),
                    value: false,
                    groupValue: targetAll,
                    onChanged: (val) {
                      setDialogState(() {
                        targetAll = false;
                      });
                    },
                  ),
                  if (!targetAll) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: loadingUsers
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : users.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Không có người dùng nào',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: users.map((user) {
                                    final userId = user['_id']?.toString() ??
                                        user['id']?.toString() ??
                                        '';
                                    final username = user['username']?.toString() ?? '';
                                    final email = user['email']?.toString() ?? '';
                                    final role = user['role']?.toString() ?? '';
                                    final isSelected =
                                        selectedUserIds.contains(userId);

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                      value: isSelected,
                                      onChanged: (checked) {
                                        setDialogState(() {
                                                  final newList = List<String>.from(selectedUserIds);
                                          if (checked == true) {
                                                    if (!newList.contains(userId)) {
                                                      newList.add(userId);
                                                    }
                                                  } else {
                                                    newList.remove(userId);
                                                  }
                                                  selectedUserIds = newList;
                                                });
                                              },
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setDialogState(() {
                                                    final newList = List<String>.from(selectedUserIds);
                                                    if (!isSelected) {
                                                      if (!newList.contains(userId)) {
                                                        newList.add(userId);
                                            }
                                          } else {
                                                      newList.remove(userId);
                                          }
                                                    selectedUserIds = newList;
                                        });
                                      },
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          username,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        if (role == 'admin') ...[
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primary.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Text(
                                                              'Admin',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: AppColors.primary,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    Text(
                                                      email,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    );
                                    }).toList(),
                                  ),
                                ),
                    ),
                    if (!targetAll && selectedUserIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Vui lòng chọn ít nhất một người dùng',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final message = messageController.text.trim();

                  if (title.isEmpty || message.isEmpty) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tiêu đề và nội dung'),
                        ),
                      );
                    }
                    return;
                  }

                  if (!targetAll && selectedUserIds.isEmpty) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng chọn ít nhất một người dùng',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  final provider =
                      Provider.of<AlertProvider>(builderContext, listen: false);
                  final ok = await provider.createAlert(
                    title: title,
                    message: message,
                    severity: severity,
                    targetAll: targetAll,
                    targetUsers: targetAll ? [] : selectedUserIds,
                    type: 'manual_notice',
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    if (ok) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Đã tạo thông báo')),
                      );
                      // Refresh alerts list
                      _loadAlerts();
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.errorMessage ?? 'Tạo thông báo thất bại',
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tạo'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownItem(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  String _selectedFilter = 'all'; // 'all', 'user', 'device', 'threshold', 'schedule'
  String _searchQuery = '';
  bool _initialized = false;
  int _currentPage = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadLogs(resetPage: true);
  }

  Future<void> _loadLogs({bool resetPage = false, bool loadMore = false}) async {
    final provider = Provider.of<ActivityLogProvider>(context, listen: false);
    
    if (resetPage) {
      _currentPage = 1;
    } else if (loadMore) {
      _currentPage++;
    }
    
    if (loadMore) {
      setState(() => _loadingMore = true);
    }
    
    await provider.fetchActivityLogs(
      page: _currentPage,
      limit: 20,
      append: loadMore,
    );
    
    if (loadMore && mounted) {
      setState(() => _loadingMore = false);
    }
    
    if (mounted && !_initialized) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lịch sử hoạt động'),
      ),
      body: Consumer<ActivityLogProvider>(
        builder: (context, provider, child) {
          final logs = provider.logs;

          if (provider.isLoading && !_initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLogs,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final filteredLogs = logs.where((log) {
            final action = (log['action'] ?? '').toString().toLowerCase();
            final resourceType = (log['resourceType'] ?? '').toString();
            final userName =
                (log['userId']?['username'] ?? '').toString().toLowerCase();
            final details =
                (log['details'] ?? '').toString().toLowerCase();

            // Filter by resourceType if available, otherwise fallback to action-based filtering
            bool matchesFilter = true;
            if (_selectedFilter != 'all') {
              if (resourceType.isNotEmpty) {
                matchesFilter = resourceType == _selectedFilter;
              } else {
                // Fallback: filter by action pattern
                if (_selectedFilter == 'user') {
                  matchesFilter = action.contains('user');
                } else if (_selectedFilter == 'device') {
                  matchesFilter = action.contains('device');
                } else if (_selectedFilter == 'threshold') {
                  matchesFilter = action.contains('threshold');
                } else if (_selectedFilter == 'schedule') {
                  matchesFilter = action.contains('schedule');
                }
              }
            }

            final q = _searchQuery.toLowerCase();
            final matchesSearch =
                q.isEmpty || userName.contains(q) || details.contains(q);

            return matchesFilter && matchesSearch;
          }).toList();

          final total = filteredLogs.length;
          final successCount = filteredLogs
              .where((l) => l['status']?.toString() == 'success')
              .length;
          final failedCount = filteredLogs
              .where((l) => l['status']?.toString() == 'failed')
              .length;

          final pagination = provider.pagination;
          final totalPages = (pagination['pages'] as int?) ?? 1;
          final hasMore = _currentPage < totalPages;
          
          return RefreshIndicator(
            onRefresh: () => _loadLogs(resetPage: true),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm log...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Filter buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Lọc theo:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterButton('all', 'Tất cả'),
                              const SizedBox(width: 8),
                              _buildFilterButton('user', 'Người dùng'),
                              const SizedBox(width: 8),
                              _buildFilterButton('device', 'Thiết bị'),
                              const SizedBox(width: 8),
                              _buildFilterButton('threshold', 'Ngưỡng'),
                              const SizedBox(width: 8),
                              _buildFilterButton('schedule', 'Lịch trình'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tổng số',
                          '$total',
                          Icons.history,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Thành công',
                          '$successCount',
                          Icons.check_circle,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Thất bại',
                          '$failedCount',
                          Icons.error,
                          AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Logs list
                Expanded(
                  child: filteredLogs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không tìm thấy log',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...filteredLogs.map<Widget>((log) => _buildLogCard(log)),
                            // Pagination - Load More button
                            if (hasMore && !_loadingMore)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _loadLogs(loadMore: true),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedFilter = value);
        // Reset to page 1 when filter changes
        _loadLogs(resetPage: true);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  Widget _buildLogCard(Map<String, dynamic> log) {
    IconData actionIcon;
    Color actionColor;

    final action = (log['action'] ?? '').toString();

    switch (action) {
      case 'control_device':
        actionIcon = Icons.power;
        actionColor = AppColors.primary;
        break;
      case 'register_user':
      case 'update_user':
      case 'delete_user':
      case 'toggle_user_status':
        actionIcon = Icons.people;
        actionColor = AppColors.warning;
        break;
      case 'create_threshold':
      case 'update_threshold':
      case 'delete_threshold':
        actionIcon = Icons.tune;
        actionColor = AppColors.soilMoisture;
        break;
      case 'create_schedule':
      case 'update_schedule':
      case 'delete_schedule':
        actionIcon = Icons.event_note;
        actionColor = AppColors.humidity;
        break;
      default:
        actionIcon = Icons.info;
        actionColor = AppColors.textSecondary;
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final createdAt = DateTime.tryParse(
          (log['createdAt'] ?? '').toString(),
        ) ??
        DateTime.now();

    final username =
        (log['userId']?['username'] ?? 'Unknown').toString();
    final status = (log['status'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(actionIcon, color: actionColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _buildDescription(action, log),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'success'
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'success'
                        ? Icons.check_circle
                        : Icons.error,
                    size: 12,
                    color: status == 'success'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status == 'success' ? 'OK' : 'FAIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: log['status'] == 'success'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (log['userId']?['role'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (log['userId']?['role'] == 'admin')
                          ? AppColors.warning.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log['userId']?['role'] == 'admin' ? 'Admin' : 'User',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: (log['userId']?['role'] == 'admin')
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildDescription(String action, Map<String, dynamic> log) {
    final resourceType = (log['resourceType'] ?? '').toString();
    switch (action) {
      case 'register_user':
        return 'Tạo người dùng mới';
      case 'update_user':
        return 'Cập nhật thông tin người dùng';
      case 'delete_user':
        return 'Xóa người dùng';
      case 'toggle_user_status':
        return 'Khóa/Mở khóa người dùng';
      case 'control_device':
        return 'Điều khiển thiết bị';
      case 'create_schedule':
        return 'Tạo lịch trình mới';
      case 'update_schedule':
        return 'Cập nhật lịch trình';
      case 'delete_schedule':
        return 'Xóa lịch trình';
      case 'create_threshold':
        return 'Tạo cài đặt ngưỡng';
      case 'update_threshold':
        return 'Cập nhật cài đặt ngưỡng';
      case 'delete_threshold':
        return 'Xóa cài đặt ngưỡng';
      default:
        return 'Hành động: $action (${resourceType.isNotEmpty ? resourceType : 'không rõ'})';
    }
  }

}

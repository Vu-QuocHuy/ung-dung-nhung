import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String _roleFilter = '';
  bool _loading = true;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUsers();
    setState(() {
      _loading = false;
    });
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
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddUserDialog();
            },
            tooltip: 'Thêm người dùng',
          ),
        ],
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (_loading && userProvider.users.isEmpty) {
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

                if (userProvider.errorMessage != null && userProvider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(userProvider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final users = userProvider.users;
                final filteredUsers = users.where((user) {
                  final userMap = _convertToMap(user);
                  final query = _searchQuery.toLowerCase();
                  final username = (userMap['username'] ?? '').toString().toLowerCase();
                  final email = (userMap['email'] ?? '').toString().toLowerCase();
                  final phone = (userMap['phone'] ?? '').toString().toLowerCase();
                  
                  final matchesSearch = username.contains(query) ||
                      email.contains(query) ||
                      phone.contains(query);
                  
                  final matchesRole = _roleFilter.isEmpty ||
                      (userMap['role']?.toString() == _roleFilter);
                  
                  return matchesSearch && matchesRole;
                }).toList();

                final stats = {
                  'total': users.length,
                  'active': users.where((u) => _convertToMap(u)['isActive'] == true).length,
                  'admins': users.where((u) => _convertToMap(u)['role'] == 'admin').length,
                  'users': users.where((u) => _convertToMap(u)['role'] == 'user').length,
                };

                return RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            'Tổng số người dùng',
                            '${stats['total']}',
                            Icons.people,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Đang hoạt động',
                            '${stats['active']}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Quản trị viên',
                            '${stats['admins']}',
                            Icons.admin_panel_settings,
                            AppColors.primary,
                          ),
                          _buildStatCard(
                            'Người dùng',
                            '${stats['users']}',
                            Icons.person,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search and Filter
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm theo tên, email, số điện thoại...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _roleFilter.isEmpty ? null : _roleFilter,
                              decoration: InputDecoration(
                                labelText: 'Vai trò',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Tất cả vai trò')),
                                DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                                DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                              ],
                              onChanged: (value) {
                                setState(() => _roleFilter = value ?? '');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Users List
                      if (filteredUsers.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'Không có người dùng nào',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredUsers.map((user) {
                          final userMap = _convertToMap(user);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildUserCard(userMap),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';
    final address = user['address']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'user';
    final isActive = user['isActive'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with username and badges
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (role == 'admin')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Khóa',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Email:', email),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow('Số điện thoại:', phone),
              ],
              if (address.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow('Địa chỉ:', address),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedUser = Map<String, dynamic>.from(user);
                    });
                    _showEditUserDialog();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleUserStatus(user['_id']?.toString() ?? ''),
                  icon: Icon(
                    isActive ? Icons.lock : Icons.lock_open,
                    size: 18,
                  ),
                  label: Text(isActive ? 'Khóa' : 'Mở'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.orange[50]
                        : Colors.green[50],
                    foregroundColor: isActive
                        ? Colors.orange[700]
                        : Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showDeleteDialog(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(50, 50),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Thêm người dùng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                    labelText: 'Tên người dùng *',
                  prefixIcon: Icon(Icons.person),
                    hintText: 'Tối thiểu 3 ký tự',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                  prefixIcon: Icon(Icons.lock),
                    hintText: 'Tối thiểu 6 ký tự',
                ),
                obscureText: true,
              ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('Người dùng'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Quản trị viên'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value ?? 'user';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '10 chữ số',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: Icon(Icons.home),
                  ),
                  maxLines: 2,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc')),
                  );
                  return;
                }

                if (usernameController.text.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tên người dùng phải có ít nhất 3 ký tự')),
                  );
                  return;
                }

                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
                );
                return;
              }

              final userProvider = Provider.of<UserProvider>(context, listen: false);
                final userData = <String, dynamic>{
                'username': usernameController.text.trim(),
                'email': emailController.text.trim(),
                'password': passwordController.text.trim(),
                  'role': selectedRole,
                };

                // Thêm phone và address nếu có
                final phone = phoneController.text.trim();
                if (phone.isNotEmpty) {
                  userData['phone'] = phone;
                }

                final address = addressController.text.trim();
                if (address.isNotEmpty) {
                  userData['address'] = address;
                }

                final success = await userProvider.createUser(userData);

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm người dùng thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userProvider.errorMessage ?? 'Thêm người dùng thất bại'),
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

  void _showEditUserDialog() {
    if (_selectedUser == null) return;

    final user = Map<String, dynamic>.from(_selectedUser!);
    final usernameController = TextEditingController(text: user['username']?.toString() ?? '');
    final emailController = TextEditingController(text: user['email']?.toString() ?? '');
    final phoneController = TextEditingController(text: user['phone']?.toString() ?? '');
    final addressController = TextEditingController(text: user['address']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa người dùng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên người dùng',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.home),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedUser = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final userId = user['_id']?.toString() ?? '';

              final success = await userProvider.updateUser(userId, {
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
              });

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  setState(() {
                    _selectedUser = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật người dùng thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userProvider.errorMessage ?? 'Cập nhật thất bại'),
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
  }

  void _toggleUserStatus(String userId) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.toggleUserStatus(userId).then((ok) async {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Đã cập nhật trạng thái người dùng'
                : userProvider.errorMessage ?? 'Thao tác thất bại'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        if (ok) await _loadUsers();
    });
  }

  void _showDeleteDialog(Map<String, dynamic> user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await userProvider.deleteUser(user['_id']?.toString() ?? '');
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã xóa người dùng'
                        : userProvider.errorMessage ?? 'Xóa thất bại'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
                if (ok) await _loadUsers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/services.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  Map<String, dynamic>? _userInfo;
  
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoadingData = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null || currentUser['id'] == null) {
        if (mounted) {
          setState(() => _isLoadingData = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy thông tin người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Gọi API để lấy thông tin đầy đủ từ server
      final userService = UserService();
      final result = await userService.getUserById(currentUser['id']!);
      
      if (mounted) {
        if (result['success'] == true && result['user'] != null) {
          _userInfo = Map<String, dynamic>.from(result['user']);
          _usernameController.text = _userInfo?['username']?.toString() ?? '';
          _emailController.text = _userInfo?['email']?.toString() ?? '';
          _phoneController.text = _userInfo?['phone']?.toString() ?? '';
          _addressController.text = _userInfo?['address']?.toString() ?? '';
        } else {
          // Fallback: dùng thông tin từ AuthProvider nếu API fail
          _userInfo = Map<String, dynamic>.from(currentUser);
          _usernameController.text = currentUser['username']?.toString() ?? '';
          _emailController.text = currentUser['email']?.toString() ?? '';
          _phoneController.text = '';
          _addressController.text = '';
        }
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      if (mounted) {
        // Fallback: dùng thông tin từ AuthProvider nếu có lỗi
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        if (currentUser != null) {
          _userInfo = Map<String, dynamic>.from(currentUser);
          _usernameController.text = currentUser['username']?.toString() ?? '';
          _emailController.text = currentUser['email']?.toString() ?? '';
          _phoneController.text = '';
          _addressController.text = '';
        }
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thông tin: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null || currentUser['_id'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy thông tin người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.updateUser(
        currentUser['_id'].toString(),
        {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        },
      );

      if (mounted) {
        if (success) {
          // Refresh user info from API
          await _loadUserInfo();
          
          if (!mounted) return;
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật thông tin thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.errorMessage ?? 'Cập nhật thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    _loadUserInfo();
    setState(() => _isEditing = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý thông tin cá nhân'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final currentUser = authProvider.currentUser;
                final displayUser = _userInfo ?? currentUser;
                
                return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayUser?['username']?.toString() ?? 'Người dùng',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayUser?['email']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.verified, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Người dùng',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                              
                        // Username
                        _buildInfoRow(
                          label: 'Tên người dùng',
                          value: _usernameController.text,
                          icon: Icons.person,
                          isEditable: _isEditing,
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _buildInfoRow(
                          label: 'Email',
                          value: _emailController.text,
                          icon: Icons.email,
                          isEditable: _isEditing,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        _buildInfoRow(
                          label: 'Số điện thoại',
                          value: _phoneController.text,
                          icon: Icons.phone,
                          isEditable: _isEditing,
                          controller: _phoneController,
                        ),
                        const SizedBox(height: 16),

                        // Address
                        _buildInfoRow(
                          label: 'Địa chỉ',
                          value: _addressController.text,
                          icon: Icons.home,
                          isEditable: _isEditing,
                          controller: _addressController,
                        ),
                        
                        // Action buttons - moved to bottom
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isLoading ? null : _cancelEdit,
                                child: const Text('Hủy'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Lưu'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isEditable,
    TextEditingController? controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: isEditable && controller != null
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (val) {
                    if (label == 'Tên người dùng' && val != null && val.isNotEmpty) {
                      if (val.length < 3) {
                        return 'Tên người dùng phải có ít nhất 3 ký tự';
                      }
                      if (val.length > 30) {
                        return 'Tên người dùng không được quá 30 ký tự';
                      }
                    }
                    if (label == 'Email' && val != null && val.isNotEmpty) {
                      if (!val.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                    }
                    return null;
                  },
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.isEmpty ? '--' : value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}


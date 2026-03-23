import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        children: [
          // Profile Header Card
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final currentUser = authProvider.currentUser;
              return Container(
                margin: const EdgeInsets.all(16),
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
                      child: Icon(
                        currentUser?['role'] == 'admin'
                            ? Icons.admin_panel_settings
                            : Icons.person,
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
                      currentUser?['username'] ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                              color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                              color: Colors.white70,
                      ),
                    ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.white,
                      ),
                              const SizedBox(width: 4),
                              Text(
                        currentUser?['role'] == 'admin'
                            ? 'Quản trị viên'
                            : 'Người dùng',
                        style: const TextStyle(
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
              );
            },
          ),

          // Menu Items
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'Quản lý thông tin cá nhân',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: () {
              _showChangePasswordDialog(context);
            },
          ),
          const Divider(),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Đăng xuất',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận'),
                      content: const Text('Bạn có chắc muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(120, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? AppColors.textPrimary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu xác nhận không khớp'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final success = await authProvider.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đổi mật khẩu thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authProvider.errorMessage ?? 'Đổi mật khẩu thất bại',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }
}

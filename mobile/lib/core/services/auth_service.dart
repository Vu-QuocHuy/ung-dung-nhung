import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Logging in with email: $email');
      final response = await _apiClient.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Save tokens and user info
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(AppConstants.accessTokenKey, data['accessToken']);
        await prefs.setString(
          AppConstants.refreshTokenKey,
          data['refreshToken'],
        );
        await prefs.setString(AppConstants.userIdKey, data['user']['id']);
        await prefs.setString(AppConstants.userRoleKey, data['user']['role']);
        await prefs.setString(
          AppConstants.usernameKey,
          data['user']['username'],
        );
        await prefs.setString(AppConstants.emailKey, data['user']['email']);

        return {
          'success': true,
          'message': 'Đăng nhập thành công',
          'user': data['user'],
        };
      }

      // Handle error responses
      String errorMessage = 'Đăng nhập thất bại';
      if (response.data != null) {
        if (response.data is Map && response.data.containsKey('message')) {
          errorMessage = response.data['message'];
        } else if (response.data is String) {
          errorMessage = response.data;
        }
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      debugPrint('Login error: $e');
      debugPrint('Login error type: ${e.runtimeType}');
      
      // Extract error message from DioException
      String errorMessage = 'Đăng nhập thất bại';
      if (e is DioException) {
        debugPrint('DioException - response: ${e.response?.data}');
        debugPrint('DioException - statusCode: ${e.response?.statusCode}');
        debugPrint('DioException - type: ${e.type}');
        
        if (e.response != null && e.response?.data != null) {
          // Server returned error response
          final responseData = e.response?.data;
          debugPrint('Response data type: ${responseData.runtimeType}');
          debugPrint('Response data: $responseData');
          
          if (responseData is Map) {
            if (responseData.containsKey('message')) {
              errorMessage = responseData['message'].toString();
              debugPrint('Extracted message: $errorMessage');
            } else if (responseData.containsKey('error')) {
              errorMessage = responseData['error'].toString();
            }
          } else if (responseData is String) {
            errorMessage = responseData;
          }
          
          // If still default message, try status code
          if (errorMessage == 'Đăng nhập thất bại') {
            final statusCode = e.response?.statusCode;
            if (statusCode == 401) {
              errorMessage = 'Email hoặc mật khẩu không đúng';
            } else if (statusCode == 404) {
              errorMessage = 'Không tìm thấy tài khoản';
            } else if (statusCode != null) {
              errorMessage = 'Lỗi đăng nhập (Mã lỗi: $statusCode)';
            }
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Kết nối quá lâu. Vui lòng thử lại';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng';
        } else {
          errorMessage = 'Lỗi kết nối: ${e.message ?? e.toString()}';
        }
      } else {
        errorMessage = 'Lỗi: ${e.toString()}';
      }
      
      debugPrint('Final error message: $errorMessage');
      return {'success': false, 'message': errorMessage};
    }
  }

  // Register (Admin only)
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post(
        AppConstants.registerEndpoint,
        data: userData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Đăng ký thành công',
          'user': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Đăng ký thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

      if (refreshToken != null) {
        await _apiClient.post(
          AppConstants.logoutEndpoint,
          data: {'refreshToken': refreshToken},
        );
      }

      // Clear local storage
      await prefs.clear();

      return {'success': true, 'message': 'Đăng xuất thành công'};
    } catch (e) {
      // Clear local storage even if API fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return {'success': true, 'message': 'Đăng xuất thành công'};
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _apiClient.post(
        AppConstants.changePasswordEndpoint,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': 'Đổi mật khẩu thành công'};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Đổi mật khẩu thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null;
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  // Get current user info from local storage
  Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(AppConstants.userIdKey),
      'username': prefs.getString(AppConstants.usernameKey),
      'email': prefs.getString(AppConstants.emailKey),
      'role': prefs.getString(AppConstants.userRoleKey),
    };
  }
}

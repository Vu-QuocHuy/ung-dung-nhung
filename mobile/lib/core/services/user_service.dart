import '../constants/app_constants.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  // Register user (Admin only)
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post(
        AppConstants.registerEndpoint,
        data: userData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return {
          'success': true,
          'user': response.data['user'] ?? response.data['data'],
          'message': response.data['message'] ?? 'Tạo user thành công',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Tạo user thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get all users (Admin only)
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final response = await _apiClient.get(
        AppConstants.usersEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // API response can be:
        // { data: [...], pagination: {...} }
        // or { data: { users: [...], pagination: {...} } }
        final data = response.data['data'];
        final pagination = response.data['pagination'] ??
            (data is Map ? data['pagination'] : null) ??
            {};

        List<dynamic> users = [];
        if (data is List) {
          users = List<dynamic>.from(data);
        } else if (data is Map && data['users'] is List) {
          users = List<dynamic>.from(data['users']);
        }

        return {
          'success': true,
          'users': users,
          'pagination': Map<String, dynamic>.from(pagination),
        };
      }

      return {
        'success': false,
        'message':
            response.data['message'] ?? 'Không thể tải danh sách người dùng',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await _apiClient.get(
        '${AppConstants.usersEndpoint}/$userId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'user': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không tìm thấy người dùng',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Update user
  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.usersEndpoint}/$userId',
        data: userData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Cập nhật thành công',
          'user': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Cập nhật thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Toggle user status (Admin only)
  Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.usersEndpoint}/$userId/toggle-status',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'],
          'user': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Thao tác thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Delete user (Admin only)
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await _apiClient.delete(
        '${AppConstants.usersEndpoint}/$userId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': response.data['message']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Xóa thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }
}

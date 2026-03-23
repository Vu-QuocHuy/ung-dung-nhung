import '../constants/app_constants.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _apiClient = ApiClient();

  // Get all alerts
  Future<Map<String, dynamic>> getAlerts({
    int page = 1,
    int limit = 20,
    String? status,
    String? severity,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (severity != null && severity.isNotEmpty) {
        queryParams['severity'] = severity;
      }

      final response = await _apiClient.get(
        AppConstants.alertsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'alerts': response.data['data'], // data is an array directly
          'count': response.data['total'] ?? response.data['count'] ?? 0,
          'pagination': {
            'total': response.data['total'] ?? 0,
            'page': response.data['page'] ?? page,
            'pages': response.data['pages'] ?? 1,
            'limit': response.data['limit'] ?? limit,
          },
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tải cảnh báo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get unread alerts count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        AppConstants.alertsEndpoint,
        queryParameters: {'status': 'active', 'limit': '1'},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final total = response.data['total'] ?? response.data['count'] ?? 0;
        return {'success': true, 'count': total};
      }

      return {'success': false, 'count': 0};
    } catch (e) {
      return {'success': false, 'count': 0};
    }
  }

  // Create alert (admin)
  Future<Map<String, dynamic>> createAlert({
    required String title,
    required String message,
    String type = 'manual_notice',
    String severity = 'info',
    bool targetAll = true,
    List<String>? targetUsers,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.alertsEndpoint,
        data: {
          'title': title,
          'message': message,
          'type': type,
          'severity': severity,
          'targetAll': targetAll,
          'targetUsers': targetUsers ?? [],
          'data': data ?? {},
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {
          'success': true,
          'alert': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tạo thông báo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Resolve alert
  Future<Map<String, dynamic>> resolveAlert(String alertId) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.alertsEndpoint}/$alertId/resolve',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'alert': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Xử lý thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Delete alert (Admin only)
  Future<Map<String, dynamic>> deleteAlert(String alertId) async {
    try {
      final response = await _apiClient.delete(
        '${AppConstants.alertsEndpoint}/$alertId',
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

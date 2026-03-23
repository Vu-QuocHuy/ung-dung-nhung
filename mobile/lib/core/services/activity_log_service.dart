import '../constants/app_constants.dart';
import 'api_client.dart';

class ActivityLogService {
  final ApiClient _apiClient = ApiClient();

  // Get all activity logs (Admin: all logs, User: own logs)
  Future<Map<String, dynamic>> getActivityLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    String? action,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (action != null && action.isNotEmpty) {
        queryParams['action'] = action;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate;
      }

      final response = await _apiClient.get(
        AppConstants.activityLogsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'logs': response.data['data']['logs'],
          'pagination': response.data['data']['pagination'],
        };
      }

      return {
        'success': false,
        'message':
            response.data['message'] ?? 'Không thể tải nhật ký hoạt động',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

}

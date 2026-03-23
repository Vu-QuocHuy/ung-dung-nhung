import '../constants/app_constants.dart';
import 'api_client.dart';

class SensorService {
  final ApiClient _apiClient = ApiClient();

  // Get latest sensor data
  Future<Map<String, dynamic>> getLatestData() async {
    try {
      final response = await _apiClient.get(
        AppConstants.sensorDataLatestEndpoint,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tải dữ liệu cảm biến',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get sensor history with date range
  Future<Map<String, dynamic>> getHistory({
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (startDate != null) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate;
      }

      final response = await _apiClient.get(
        AppConstants.sensorDataHistoryEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data']['sensorData'],
          'pagination': response.data['data']['pagination'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tải lịch sử',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get sensor data by type and time range (for charts)
  Future<Map<String, dynamic>> getDataByType(
    String sensorType, {
    int? hours,
    int? days,
  }) async {
    try {
      final queryParams = <String, String>{
        'type': sensorType,
      };

      if (hours != null) {
        queryParams['hours'] = hours.toString();
      } else if (days != null) {
        queryParams['days'] = days.toString();
      }

      final response = await _apiClient.get(
        AppConstants.sensorDataHistoryEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'count': response.data['count'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tải dữ liệu',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }
}

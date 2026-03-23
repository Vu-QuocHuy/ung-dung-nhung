import '../constants/app_constants.dart';
import 'api_client.dart';

class ESP32Service {
  final ApiClient _apiClient = ApiClient();

  // Get ESP32 status
  Future<Map<String, dynamic>> getESP32Status() async {
    try {
      final response = await _apiClient.get(AppConstants.esp32StatusEndpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }

      return {
        'success': false,
        'message':
            response.data['message'] ?? 'Không thể tải trạng thái ESP32',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }
}


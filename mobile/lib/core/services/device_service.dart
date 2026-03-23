import '../constants/app_constants.dart';
import 'api_client.dart';

class DeviceService {
  final ApiClient _apiClient = ApiClient();

  // Get device status
  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await _apiClient.get(AppConstants.deviceStatusEndpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Convert object to array of devices
        final Map<String, dynamic> deviceData = response.data['data'];
        final List<Map<String, dynamic>> devices = deviceData.entries.map((entry) {
          return {
            'deviceName': entry.key,
            'status': entry.value,
          };
        }).toList();
        
        return {'success': true, 'devices': devices};
      }

      return {
        'success': false,
        'message':
            response.data['message'] ?? 'Không thể tải trạng thái thiết bị',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Control device
  Future<Map<String, dynamic>> controlDevice(
    String deviceName,
    String action,
  ) async {
    try {
      final response = await _apiClient.post(
        AppConstants.deviceControlEndpoint,
        data: {'deviceName': deviceName, 'action': action},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'],
          'device': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Điều khiển thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get device control history
  Future<Map<String, dynamic>> getControlHistory({
    int page = 1,
    int limit = 20,
    String? deviceName,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (deviceName != null && deviceName.isNotEmpty) {
        queryParams['deviceName'] = deviceName;
      }

      final response = await _apiClient.get(
        AppConstants.deviceHistoryEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'history': response.data['data']['history'],
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
}

import '../constants/app_constants.dart';
import 'api_client.dart';

class ThresholdService {
  final ApiClient _apiClient = ApiClient();

  // Get all thresholds
  Future<Map<String, dynamic>> getAllThresholds({String? sensorType}) async {
    try {
      final queryParams = <String, String>{};

      if (sensorType != null && sensorType.isNotEmpty) {
        queryParams['sensorType'] = sensorType;
      }

      final response = await _apiClient.get(
        AppConstants.thresholdsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'thresholds': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tải ngưỡng cảnh báo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get threshold by sensor type
  Future<Map<String, dynamic>> getThresholdBySensorType(
    String sensorType,
  ) async {
    try {
      final response = await _apiClient.get(
        '${AppConstants.thresholdsEndpoint}/$sensorType',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'threshold': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không tìm thấy ngưỡng cảnh báo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Create threshold (Admin only)
  Future<Map<String, dynamic>> createThreshold(
    Map<String, dynamic> thresholdData,
  ) async {
    try {
      final response = await _apiClient.post(
        AppConstants.thresholdsEndpoint,
        data: thresholdData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Tạo ngưỡng cảnh báo thành công',
          'threshold': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Tạo ngưỡng cảnh báo thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Update threshold (Admin only)
  Future<Map<String, dynamic>> updateThreshold(
    String sensorType,
    Map<String, dynamic> thresholdData,
  ) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.thresholdsEndpoint}/$sensorType',
        data: thresholdData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Cập nhật thành công',
          'threshold': response.data['data'],
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

  // Delete threshold (Admin only)
  Future<Map<String, dynamic>> deleteThreshold(String sensorType) async {
    try {
      final response = await _apiClient.delete(
        '${AppConstants.thresholdsEndpoint}/$sensorType',
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

  // Toggle threshold (Admin only)
  Future<Map<String, dynamic>> toggleThreshold(
    String sensorType,
    bool isActive,
  ) async {
    try {
      final response = await _apiClient.patch(
        '${AppConstants.thresholdsEndpoint}/$sensorType/toggle',
        data: {'isActive': isActive},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Cập nhật trạng thái thành công',
          'threshold': response.data['data'],
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
}

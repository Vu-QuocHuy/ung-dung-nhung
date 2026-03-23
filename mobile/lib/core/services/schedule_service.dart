import '../constants/app_constants.dart';
import 'api_client.dart';

class ScheduleService {
  final ApiClient _apiClient = ApiClient();

  // Get all schedules
  Future<Map<String, dynamic>> getAllSchedules({
    int page = 1,
    int limit = 50,
    String? deviceName,
    String? isActive,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (deviceName != null && deviceName.isNotEmpty) {
        queryParams['deviceName'] = deviceName;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }

      final response = await _apiClient.get(
        AppConstants.schedulesEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        List<dynamic> schedules = [];
        Map<String, dynamic> pagination = {};

        // API hiện trả data là mảng (không bao bọc schedules/pagination)
        if (data is List) {
          schedules = List<dynamic>.from(data);
          pagination = {
            'total': response.data['count'] ?? data.length,
          };
        } else if (data is Map && data['schedules'] != null) {
          schedules = List<dynamic>.from(data['schedules'] as List);
          if (data['pagination'] != null) {
            pagination = Map<String, dynamic>.from(data['pagination']);
          }
        }

        return {
          'success': true,
          'schedules': schedules,
          'pagination': pagination,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không thể tải lịch trình',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Get schedule by ID
  Future<Map<String, dynamic>> getScheduleById(String scheduleId) async {
    try {
      final response = await _apiClient.get(
        '${AppConstants.schedulesEndpoint}/$scheduleId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'schedule': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Không tìm thấy lịch trình',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Create schedule (Admin only)
  Future<Map<String, dynamic>> createSchedule(
    Map<String, dynamic> scheduleData,
  ) async {
    try {
      final response = await _apiClient.post(
        AppConstants.schedulesEndpoint,
        data: scheduleData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Tạo lịch trình thành công',
          'schedule': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Tạo lịch trình thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Update schedule (Admin only)
  Future<Map<String, dynamic>> updateSchedule(
    String scheduleId,
    Map<String, dynamic> scheduleData,
  ) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.schedulesEndpoint}/$scheduleId',
        data: scheduleData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': 'Cập nhật thành công',
          'schedule': response.data['data'],
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

  // Toggle schedule status (Admin only)
  Future<Map<String, dynamic>> toggleScheduleStatus(String scheduleId) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.schedulesEndpoint}/$scheduleId/toggle',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'],
          'schedule': response.data['data'],
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

  // Delete schedule (Admin only)
  Future<Map<String, dynamic>> deleteSchedule(String scheduleId) async {
    try {
      final response = await _apiClient.delete(
        '${AppConstants.schedulesEndpoint}/$scheduleId',
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

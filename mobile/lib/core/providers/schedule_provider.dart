import 'package:flutter/foundation.dart';
import '../services/services.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _schedules = [];
  Map<String, dynamic> _pagination = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get schedules => _schedules;
  Map<String, dynamic> get pagination => _pagination;

  // Get all schedules
  Future<void> fetchSchedules({
    int page = 1,
    int limit = 50,
    String? deviceName,
    String? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _scheduleService.getAllSchedules(
        page: page,
        limit: limit,
        deviceName: deviceName,
        isActive: isActive,
      );

      if (result['success'] == true) {
        _schedules = result['schedules'];
        _pagination = result['pagination'];
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create schedule (Admin only)
  Future<bool> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final result = await _scheduleService.createSchedule(scheduleData);

      if (result['success'] == true) {
        _schedules.insert(0, result['schedule']);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update schedule (Admin only)
  Future<bool> updateSchedule(
    String scheduleId,
    Map<String, dynamic> scheduleData,
  ) async {
    try {
      final result = await _scheduleService.updateSchedule(
        scheduleId,
        scheduleData,
      );

      if (result['success'] == true) {
        final index = _schedules.indexWhere((s) => s['_id'] == scheduleId);
        if (index != -1) {
          _schedules[index] = result['schedule'];
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Toggle schedule status (Admin only)
  Future<bool> toggleScheduleStatus(String scheduleId) async {
    try {
      final result = await _scheduleService.toggleScheduleStatus(scheduleId);

      if (result['success'] == true) {
        final index = _schedules.indexWhere((s) => s['_id'] == scheduleId);
        if (index != -1) {
          _schedules[index] = result['schedule'];
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Delete schedule (Admin only)
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      final result = await _scheduleService.deleteSchedule(scheduleId);

      if (result['success'] == true) {
        _schedules.removeWhere((s) => s['_id'] == scheduleId);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../services/services.dart';

class ActivityLogProvider with ChangeNotifier {
  final ActivityLogService _activityLogService = ActivityLogService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _logs = [];
  Map<String, dynamic> _pagination = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get logs => _logs;
  Map<String, dynamic> get pagination => _pagination;

  // Get activity logs
  Future<void> fetchActivityLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    String? action,
    String? startDate,
    String? endDate,
    bool append = false,
  }) async {
    if (!append) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _activityLogService.getActivityLogs(
        page: page,
        limit: limit,
        userId: userId,
        action: action,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success'] == true) {
        final newLogs = result['logs'];
        if (append) {
          // Append new logs to existing list
          _logs.addAll(newLogs);
        } else {
          // Replace logs
          _logs = newLogs;
        }
        _pagination = result['pagination'];
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
    } finally {
      if (!append) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }


  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

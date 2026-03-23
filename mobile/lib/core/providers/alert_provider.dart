import 'package:flutter/foundation.dart';
import '../services/services.dart';

class AlertProvider with ChangeNotifier {
  final AlertService _alertService = AlertService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _alerts = [];
  int _unreadCount = 0;
  final Map<String, dynamic> _pagination = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get alerts => _alerts;
  int get unreadCount => _unreadCount;
  Map<String, dynamic> get pagination => _pagination;

  // Get all alerts
  Future<void> fetchAlerts({
    int page = 1,
    int limit = 20,
    String? status,
    String? severity,
    Map<String, dynamic>? params,
    bool append = false,
  }) async {
    if (!append) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      // Use params if provided, otherwise use individual parameters
      final result = await _alertService.getAlerts(
        page: page,
        limit: limit,
        status: params?['status'] ?? status,
        severity: params?['severity'] ?? severity,
      );

      if (result['success'] == true) {
        final newAlerts = result['alerts'] ?? [];
        if (append) {
          // Append new alerts to existing list
          _alerts.addAll(newAlerts);
        } else {
          // Replace alerts
          _alerts = newAlerts;
        }
        // Update pagination if available
        if (result['pagination'] != null) {
          _pagination.clear();
          _pagination.addAll(result['pagination'] as Map<String, dynamic>);
        }
        // Update unread count if available
        if (result['count'] != null) {
          _unreadCount = result['count'] as int? ?? 0;
        }
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

  // Get unread count
  Future<void> fetchUnreadCount() async {
    try {
      final result = await _alertService.getUnreadCount();
      if (result['success'] == true) {
        _unreadCount = result['count'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  // Create alert (admin)
  Future<bool> createAlert({
    required String title,
    required String message,
    String type = 'manual_notice',
    String severity = 'info',
    bool targetAll = true,
    List<String>? targetUsers,
    Map<String, dynamic>? data,
  }) async {
    try {
      final result = await _alertService.createAlert(
        title: title,
        message: message,
        type: type,
        severity: severity,
        targetAll: targetAll,
        targetUsers: targetUsers,
        data: data,
      );

      if (result['success'] == true) {
        // Thêm vào danh sách hiện tại (đầu danh sách)
        _alerts = [result['alert'], ..._alerts];
        // Nếu alert mới ở trạng thái active, cập nhật badge
        if ((result['alert']['status'] ?? 'active') == 'active') {
          _unreadCount += 1;
        }
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

  // Delete alert (Admin only)
  Future<bool> deleteAlert(String alertId) async {
    try {
      final result = await _alertService.deleteAlert(alertId);

      if (result['success'] == true) {
        _alerts.removeWhere((a) => a['_id'] == alertId);
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

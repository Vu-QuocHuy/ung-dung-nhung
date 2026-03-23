import 'package:flutter/foundation.dart';
import '../services/services.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceService _deviceService = DeviceService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _devices = [];
  List<dynamic> _controlHistory = [];
  Map<String, dynamic> _pagination = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get devices => _devices;
  List<dynamic> get controlHistory => _controlHistory;
  Map<String, dynamic> get pagination => _pagination;

  // Get device status
  Future<void> fetchDeviceStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _deviceService.getDeviceStatus();

      if (result['success'] == true) {
        _devices = result['devices'];
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

  // Control device
  Future<bool> controlDevice(String deviceName, String action) async {
    try {
      final result = await _deviceService.controlDevice(deviceName, action);

      if (result['success'] == true) {
        // Update device in local list
        final index = _devices.indexWhere((d) => d['deviceName'] == deviceName);
        if (index != -1) {
          _devices[index] = result['device'];
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

  // Get control history
  Future<void> fetchControlHistory({
    int page = 1,
    int limit = 20,
    String? deviceName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _deviceService.getControlHistory(
        page: page,
        limit: limit,
        deviceName: deviceName,
      );

      if (result['success'] == true) {
        _controlHistory = result['history'];
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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

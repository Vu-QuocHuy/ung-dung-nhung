import 'package:flutter/foundation.dart';
import '../services/services.dart';

class ThresholdProvider with ChangeNotifier {
  final ThresholdService _thresholdService = ThresholdService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _thresholds = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get thresholds => _thresholds;

  // Get all thresholds
  Future<void> fetchThresholds({String? sensorType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _thresholdService.getAllThresholds(
        sensorType: sensorType,
      );

      if (result['success'] == true) {
        _thresholds = result['thresholds'];
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

  // Create threshold (Admin only)
  Future<bool> createThreshold(Map<String, dynamic> thresholdData) async {
    try {
      final result = await _thresholdService.createThreshold(thresholdData);

      if (result['success'] == true) {
        _thresholds.add(result['threshold']);
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

  // Update threshold (Admin only)
  Future<bool> updateThreshold(
    String sensorType,
    Map<String, dynamic> thresholdData,
  ) async {
    try {
      final result = await _thresholdService.updateThreshold(
        sensorType,
        thresholdData,
      );

      if (result['success'] == true) {
        final index = _thresholds.indexWhere(
          (t) => t['sensorType'] == sensorType,
        );
        if (index != -1) {
          _thresholds[index] = result['threshold'];
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

  // Delete threshold (Admin only)
  Future<bool> deleteThreshold(String sensorType) async {
    try {
      final result = await _thresholdService.deleteThreshold(sensorType);

      if (result['success'] == true) {
        _thresholds.removeWhere((t) => t['sensorType'] == sensorType);
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

  // Toggle threshold (Admin only)
  Future<bool> toggleThreshold(String sensorType, bool isActive) async {
    try {
      final result = await _thresholdService.toggleThreshold(sensorType, isActive);

      if (result['success'] == true) {
        final index = _thresholds.indexWhere(
          (t) => t['sensorType'] == sensorType,
        );
        if (index != -1) {
          _thresholds[index] = result['threshold'];
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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

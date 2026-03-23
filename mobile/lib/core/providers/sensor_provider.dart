import 'package:flutter/foundation.dart';
import '../services/services.dart';

class SensorProvider with ChangeNotifier {
  final SensorService _sensorService = SensorService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _latestData;
  List<dynamic> _historyData = [];
  Map<String, dynamic> _pagination = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get latestData => _latestData;
  List<dynamic> get historyData => _historyData;
  Map<String, dynamic> get pagination => _pagination;

  // Get latest sensor data
  Future<void> fetchLatestData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _sensorService.getLatestData();

      if (result['success'] == true) {
        _latestData = result['data'];
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

  // Get sensor history
  Future<void> fetchHistory({
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 100,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _sensorService.getHistory(
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );

      if (result['success'] == true) {
        _historyData = result['data'];
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

  // Get data by sensor type for charts
  Future<List<dynamic>> fetchDataByType(
    String sensorType, {
    int? hours,
    int? days,
  }) async {
    try {
      final result = await _sensorService.getDataByType(
        sensorType,
        hours: hours,
        days: days,
      );

      if (result['success'] == true) {
        return result['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching data by type: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

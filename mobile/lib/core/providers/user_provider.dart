import 'package:flutter/foundation.dart';
import '../services/services.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _users = [];
  Map<String, dynamic> _pagination = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get users => _users;
  Map<String, dynamic> get pagination => _pagination;

  // Create user (Admin)
  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final result = await _userService.createUser(userData);

      if (result['success'] == true) {
        // Append newly created user if returned
        if (result['user'] != null) {
          _users.insert(0, result['user']);
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

  // Get all users (Admin only)
  Future<void> fetchUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _userService.getAllUsers(
        page: page,
        limit: limit,
        search: search,
        role: role,
      );

      if (result['success'] == true) {
        _users = result['users'];
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

  // Update user
  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final result = await _userService.updateUser(userId, userData);

      if (result['success'] == true) {
        // Update user in local list
        final index = _users.indexWhere((u) => u['_id'] == userId);
        if (index != -1) {
          _users[index] = result['user'];
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

  // Toggle user status (Admin only)
  Future<bool> toggleUserStatus(String userId) async {
    try {
      final result = await _userService.toggleUserStatus(userId);

      if (result['success'] == true) {
        // Update user in local list
        final index = _users.indexWhere((u) => u['_id'] == userId);
        if (index != -1) {
          _users[index] = result['user'];
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

  // Delete user (Admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      final result = await _userService.deleteUser(userId);

      if (result['success'] == true) {
        _users.removeWhere((u) => u['_id'] == userId);
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

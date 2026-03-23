import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  ApiClient._internal() {
    // Refresh state
    bool isRefreshing = false;
    final List<void Function(String)> refreshWaiters = [];

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Treat >=400 as errors so interceptor onError can handle 401 refresh
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to headers
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            // Debug log
            // ignore: avoid_print
            debugPrint('🔑 onRequest: attach token to ${options.path}');
          } else {
            // ignore: avoid_print
            debugPrint('🔑 onRequest: no token found for ${options.path}');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // ignore: avoid_print
          debugPrint('❗ onError status=${error.response?.statusCode} path=${error.requestOptions.path}');
          // Handle 401 (Unauthorized) - Try to refresh token
          if (error.response?.statusCode == 401) {
            // Don't retry refresh token endpoint to avoid infinite loop
            if (error.requestOptions.path.contains('/auth/refresh')) {
              debugPrint('🔄 Refresh token endpoint returned 401, clearing tokens');
              await _clearTokens();
              return handler.next(error);
            }
            
            // Don't refresh token for login/register endpoints - these are authentication errors
            if (error.requestOptions.path.contains('/auth/login') || 
                error.requestOptions.path.contains('/auth/register')) {
              debugPrint('🔐 Login/Register endpoint returned 401, skipping token refresh');
              return handler.next(error);
            }

            // If already refreshing, wait and retry after new token is ready
            final completer = Completer<Response<dynamic>?>();
            refreshWaiters.add((String newToken) async {
              try {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final response = await _dio.fetch(error.requestOptions);
                completer.complete(response);
              } catch (e) {
                completer.completeError(e);
              }
            });

            if (!isRefreshing) {
              isRefreshing = true;
              debugPrint('🔄 Access token expired, attempting to refresh...');
              try {
                final newToken = await _refreshToken();
                if (newToken != null) {
                  debugPrint('✅ Token refreshed, retrying queued requests');
                  // Retry queued
                  for (final waiter in List.of(refreshWaiters)) {
                    waiter(newToken);
                  }
                } else {
                  debugPrint('❌ Refresh token failed, clearing session');
                  await _clearTokens();
                  // Fail all queued
                  for (final waiter in List.of(refreshWaiters)) {
                    waiter('');
                  }
                }
              } catch (e) {
                debugPrint('❌ Exception during refresh: $e');
                await _clearTokens();
                for (final waiter in List.of(refreshWaiters)) {
                  waiter('');
                }
              } finally {
                refreshWaiters.clear();
                isRefreshing = false;
              }
            }

            try {
              final resp = await completer.future;
              if (resp != null) {
                return handler.resolve(resp);
              }
            } catch (_) {
              // will fall through to next
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

      if (refreshToken == null) return null;

      // Create a separate Dio instance for refresh token request
      // to avoid triggering the interceptor
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        AppConstants.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['accessToken'];
        
        // Save new access token
        await prefs.setString(AppConstants.accessTokenKey, newAccessToken);
        
        debugPrint('✅ Token refreshed successfully');
        return newAccessToken;
      } else {
        debugPrint('❌ Refresh token failed: ${response.data['message']}');
      }
    } catch (e) {
      debugPrint('❌ Refresh token error: $e');
    }
    return null;
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.emailKey);
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  // DELETE request
  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }
}

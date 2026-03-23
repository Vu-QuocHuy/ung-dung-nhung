class AppConstants {
  // API Configuration
  // API backend deploy trên Render
  static const String baseUrl =
      'https://smart-farm-backend-id2x.onrender.com/api';
  static const String localUrl =
      'https://smart-farm-backend-id2x.onrender.com/api';

  // Sử dụng apiUrl cho toàn bộ app
  static const String apiUrl = baseUrl;

  // API Endpoints

  // Authentication Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String changePasswordEndpoint = '/auth/change-password';

  // User Management Endpoints
  static const String usersEndpoint = '/users';
  static const String getUserByIdEndpoint = '/users'; // + /:id
  static const String updateUserEndpoint = '/users'; // + /:id
  static const String toggleUserStatusEndpoint =
      '/users'; // + /:id/toggle-status
  static const String deleteUserEndpoint = '/users'; // + /:id

  // Sensor Endpoints
  static const String sensorsEndpoint = '/sensors';
  static const String sensorDataLatestEndpoint = '/sensors/latest';
  static const String sensorDataHistoryEndpoint = '/sensors/history';
  static const String sensorCleanupEndpoint = '/sensors/cleanup';

  // Device Control Endpoints
  static const String devicesEndpoint = '/devices';
  static const String deviceControlEndpoint = '/devices/control';
  static const String deviceStatusEndpoint = '/devices/status';
  static const String deviceHistoryEndpoint = '/devices/history';

  // Alert Endpoints
  static const String alertsEndpoint = '/alerts';
  static const String unreadAlertsEndpoint = '/alerts/unread';
  static const String markAlertReadEndpoint = '/alerts'; // + /:id/read
  static const String resolveAlertEndpoint = '/alerts'; // + /:id/resolve
  static const String deleteAlertEndpoint = '/alerts'; // + /:id

  // Threshold Endpoints
  static const String thresholdsEndpoint = '/thresholds';
  static const String getThresholdByTypeEndpoint =
      '/thresholds'; // + /:sensorType
  static const String createThresholdEndpoint = '/thresholds';
  static const String updateThresholdEndpoint = '/thresholds'; // + /:sensorType
  static const String deleteThresholdEndpoint = '/thresholds'; // + /:sensorType
  static const String toggleThresholdEndpoint =
      '/thresholds'; // + /:sensorType/toggle

  // Schedule Endpoints
  static const String schedulesEndpoint = '/schedules';
  static const String createScheduleEndpoint = '/schedules';
  static const String updateScheduleEndpoint = '/schedules'; // + /:id
  static const String deleteScheduleEndpoint = '/schedules'; // + /:id
  static const String toggleScheduleEndpoint = '/schedules'; // + /:id/toggle

  // Activity Log Endpoints
  static const String activityLogsEndpoint = '/activity-logs';
  static const String activityStatsEndpoint = '/activity-logs/stats';

  // ESP32 Endpoints
  static const String esp32StatusEndpoint = '/esp32/status';

  // MQTT Configuration
  static const String mqttBroker =
      '4751c52846f948f2a1405c138c4e4dda.s1.eu.hivemq.cloud';
  static const int mqttPort = 8883;
  static const String mqttUsername = 'smartfarm_client';
  static const String mqttPassword = 'SmartFarmPassword2025';
  static const String mqttTopicPrefix = 'farm';

  // Local Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String usernameKey = 'username';
  static const String emailKey = 'email';

  // Sensor Types
  static const String temperatureSensor = 'temperature';
  static const String humiditySensor = 'humidity';
  static const String soilMoistureSensor = 'soil_moisture';
  static const String waterLevelSensor = 'water_level';
  static const String lightSensor = 'light';

  // Device Names
  static const String pumpDevice = 'pump';
  static const String fanDevice = 'fan';
  static const String lightDevice = 'light';

  // App Info
  static const String appName = 'Smart Farm';
  static const String appVersion = '1.0.0';
}

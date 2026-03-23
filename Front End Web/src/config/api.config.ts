// API Configuration
const API_BASE_URL =
  // Lấy từ biến môi trường Vite; dùng any để tránh lỗi type khi lint ngoài Vite
  (import.meta as any).env?.VITE_API_BASE_URL;

export const API_CONFIG = {
  // Base URL lấy từ biến môi trường Vite (.env/.env.production)
  BASE_URL: API_BASE_URL,
  TIMEOUT: 10000, // 10 seconds
};

// API Endpoints
export const API_ENDPOINTS = {
  // Authentication
  AUTH: {
    LOGIN: "/auth/login",
    REGISTER: "/auth/register",
    REFRESH: "/auth/refresh",
    LOGOUT: "/auth/logout",
    CHANGE_PASSWORD: "/auth/change-password",
  },
  // Users
  USERS: {
    BASE: "/users",
    BY_ID: (id: string) => `/users/${id}`,
    TOGGLE_STATUS: (id: string) => `/users/${id}/toggle-status`,
  },
  // Sensors
  SENSORS: {
    BASE: "/sensors",
    LATEST: "/sensors/latest",
    HISTORY: "/sensors/history",
    CLEANUP: "/sensors/cleanup",
  },
  // Devices
  DEVICES: {
    CONTROL: "/devices/control",
    STATUS: "/devices/status",
    HISTORY: "/devices/history",
  },
  // Alerts
  ALERTS: {
    BASE: "/alerts",
    UNREAD: "/alerts/unread",
    BY_ID: (id: string) => `/alerts/${id}`,
    READ: (id: string) => `/alerts/${id}/read`,
    RESOLVE: (id: string) => `/alerts/${id}/resolve`,
  },
  // Thresholds
  THRESHOLDS: {
    BASE: "/thresholds",
    BY_TYPE: (type: string) => `/thresholds/${type}`,
    TOGGLE: (type: string) => `/thresholds/${type}/toggle`,
  },
  // Schedules
  SCHEDULES: {
    BASE: "/schedules",
    BY_ID: (id: string) => `/schedules/${id}`,
    TOGGLE: (id: string) => `/schedules/${id}/toggle`,
  },
  // Activity Logs
  ACTIVITY_LOGS: {
    BASE: "/activity-logs",
    MY_LOGS: "/activity-logs/my-logs",
    STATS: "/activity-logs/stats",
  },
  // ESP32
  ESP32: {
    STATUS: "/esp32/status",
  },
};

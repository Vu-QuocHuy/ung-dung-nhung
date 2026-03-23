import apiClient from "./api.client";
import { API_ENDPOINTS } from "../config/api.config";

export interface DeviceControlRequest {
  deviceName:
    | "pump"
    | "fan"
    | "light"
    | "servo_door"
    | "servo_feed"
    | "led_farm"
    | "led_animal"
    | "led_hallway";
  action: "ON" | "OFF" | "AUTO";
  value?: number; // 0-255 for PWM, or 0-90/50 for servos
}

export interface DeviceStatusResponse {
  [key: string]: "ON" | "OFF" | "AUTO";
}

export interface DeviceHistoryParams {
  deviceName?: string;
  limit?: number;
  page?: number;
}

export const deviceService = {
  async controlDevice(
    data: DeviceControlRequest
  ): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.post<{
      success: boolean;
      message: string;
    }>(API_ENDPOINTS.DEVICES.CONTROL, data);
    return response.data;
  },

  async getStatus(): Promise<DeviceStatusResponse> {
    const response = await apiClient.get<{
      success: boolean;
      data: DeviceStatusResponse;
    }>(API_ENDPOINTS.DEVICES.STATUS);
    return response.data.data;
  },

  async getHistory(params?: DeviceHistoryParams): Promise<any> {
    const response = await apiClient.get(API_ENDPOINTS.DEVICES.HISTORY, {
      params,
    });
    return response.data;
  },
};

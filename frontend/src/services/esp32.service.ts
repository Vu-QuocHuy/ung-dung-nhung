import apiClient from "./api.client";
import { API_ENDPOINTS } from "../config/api.config";

export interface ESP32StatusResponse {
  deviceId: string;
  status: "online" | "offline";
  isOnline: boolean;
  lastSeen: string;
  lastSeenSeconds: number;
  ipAddress: string | null;
  updatedAt: string;
}

export const esp32Service = {
  async getStatus(): Promise<ESP32StatusResponse> {
    const response = await apiClient.get<{
      success: boolean;
      data: ESP32StatusResponse;
    }>(API_ENDPOINTS.ESP32.STATUS);
    return response.data.data;
  },
};

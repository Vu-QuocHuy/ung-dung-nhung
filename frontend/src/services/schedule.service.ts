import apiClient from "./api.client";
import { API_ENDPOINTS } from "../config/api.config";

export interface Schedule {
  _id: string;
  name: string;
  deviceName: string;
  action: "ON" | "OFF" | "RUN" | "AUTO";
  startTime: string; // HH:mm format
  endTime: string; // HH:mm format
  daysOfWeek: number[]; // [0=Sunday, 1=Monday, ..., 6=Saturday]
  enabled: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateScheduleData {
  name: string;
  deviceName: string;
  action: "ON" | "OFF" | "RUN" | "AUTO";
  startTime: string;
  endTime: string;
  daysOfWeek: number[];
  enabled: boolean;
}

export const scheduleService = {
  async getAll(): Promise<Schedule[]> {
    const response = await apiClient.get<{
      success: boolean;
      data: Schedule[];
    }>(API_ENDPOINTS.SCHEDULES.BASE);
    return response.data.data;
  },

  async create(
    data: CreateScheduleData
  ): Promise<{ success: boolean; data: Schedule }> {
    const response = await apiClient.post<{ success: boolean; data: Schedule }>(
      API_ENDPOINTS.SCHEDULES.BASE,
      data
    );
    return response.data;
  },

  async update(
    id: string,
    data: CreateScheduleData
  ): Promise<{ success: boolean; data: Schedule }> {
    const response = await apiClient.put<{ success: boolean; data: Schedule }>(
      API_ENDPOINTS.SCHEDULES.BY_ID(id),
      data
    );
    return response.data;
  },

  async delete(id: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.delete<{
      success: boolean;
      message: string;
    }>(API_ENDPOINTS.SCHEDULES.BY_ID(id));
    return response.data;
  },

  async toggle(id: string): Promise<{ success: boolean; data: Schedule }> {
    const response = await apiClient.put<{ success: boolean; data: Schedule }>(
      API_ENDPOINTS.SCHEDULES.TOGGLE(id)
    );
    return response.data;
  },
};

import apiClient from './api.client';
import { API_ENDPOINTS } from '../config/api.config';

export interface Threshold {
  sensorType: 'temperature' | 'soil_moisture' | 'light';
  thresholdValue: number;
  severity: 'info' | 'warning' | 'critical';
  isActive: boolean;
}

export interface CreateThresholdData {
  sensorType: string;
  thresholdValue: number;
  severity: 'info' | 'warning' | 'critical';
  isActive: boolean;
}

export const thresholdService = {
  async getAll(): Promise<Threshold[]> {
    const response = await apiClient.get<{ success: boolean; data: Threshold[] }>(
      API_ENDPOINTS.THRESHOLDS.BASE
    );
    return response.data.data;
  },

  async getByType(type: string): Promise<Threshold> {
    const response = await apiClient.get<{ success: boolean; data: Threshold }>(
      API_ENDPOINTS.THRESHOLDS.BY_TYPE(type)
    );
    return response.data.data;
  },

  async create(data: CreateThresholdData): Promise<{ success: boolean; data: Threshold }> {
    const response = await apiClient.post<{ success: boolean; data: Threshold }>(
      API_ENDPOINTS.THRESHOLDS.BASE,
      data
    );
    return response.data;
  },

  async update(type: string, data: CreateThresholdData): Promise<{ success: boolean; data: Threshold }> {
    const response = await apiClient.put<{ success: boolean; data: Threshold }>(
      API_ENDPOINTS.THRESHOLDS.BY_TYPE(type),
      data
    );
    return response.data;
  },

  async delete(type: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.delete<{ success: boolean; message: string }>(
      API_ENDPOINTS.THRESHOLDS.BY_TYPE(type)
    );
    return response.data;
  },

  async toggle(type: string, isActive: boolean): Promise<{ success: boolean; data: Threshold }> {
    const response = await apiClient.patch<{ success: boolean; data: Threshold }>(
      API_ENDPOINTS.THRESHOLDS.TOGGLE(type),
      { isActive }
    );
    return response.data;
  },
};


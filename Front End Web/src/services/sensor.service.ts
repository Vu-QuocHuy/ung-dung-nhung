import apiClient from './api.client';
import { API_ENDPOINTS } from '../config/api.config';

export interface SensorReading {
  _id: string;
  sensorType: string;
  value: number;
  unit: string;
  createdAt: string;
  updatedAt: string;
}

export interface SensorDataResponse {
  temperature?: SensorReading;
  humidity?: SensorReading;
  soil_moisture?: SensorReading;
  water_level?: SensorReading;
  light?: SensorReading;
}

export interface SensorData {
  temperature: number;
  humidity: number;
  soilMoisture: number;
  waterLevel: number;
  light: number;
  timestamp: string;
}

export interface SensorHistoryParams {
  type: 'temperature' | 'humidity' | 'soil_moisture' | 'water_level' | 'light';
  hours?: number;
  limit?: number;
}

export interface SensorHistoryPoint {
  _id: string;
  sensorType: string;
  value: number;
  unit: string;
  createdAt: string;
  updatedAt: string;
}

export interface SensorHistoryResponse {
  success: boolean;
  count: number;
  data: SensorHistoryPoint[];
  stats: {
    min: number | null;
    max: number | null;
    avg: number | null;
  };
  range: {
    start: string;
    end: string;
  };
}

export const sensorService = {
  async getLatest(): Promise<SensorData> {
    const response = await apiClient.get<{ success: boolean; data: SensorDataResponse }>(
      API_ENDPOINTS.SENSORS.LATEST
    );
    const data = response.data.data;
    
    // Get the latest timestamp from all sensors
    const timestamps = [
      data.temperature?.updatedAt,
      data.humidity?.updatedAt,
      data.soil_moisture?.updatedAt,
      data.water_level?.updatedAt,
      data.light?.updatedAt,
    ].filter(Boolean);
    const latestTimestamp = timestamps.length > 0 
      ? new Date(Math.max(...timestamps.map(t => new Date(t!).getTime()))).toISOString()
      : new Date().toISOString();
    
    return {
      temperature: data.temperature?.value || 0,
      humidity: data.humidity?.value || 0,
      soilMoisture: data.soil_moisture?.value || 0,
      waterLevel: data.water_level?.value || 0,
      light: data.light?.value || 0,
      timestamp: latestTimestamp,
    };
  },

  async getHistory(params: SensorHistoryParams): Promise<SensorHistoryResponse> {
    const response = await apiClient.get<SensorHistoryResponse>(
      API_ENDPOINTS.SENSORS.HISTORY,
      { params }
    );
    return response.data;
  },

  async getAll(params?: { limit?: number; page?: number }): Promise<any> {
    const response = await apiClient.get(API_ENDPOINTS.SENSORS.BASE, { params });
    return response.data;
  },

  async cleanup(days: number): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.delete<{ success: boolean; message: string }>(
      API_ENDPOINTS.SENSORS.CLEANUP,
      { params: { days } }
    );
    return response.data;
  },
};


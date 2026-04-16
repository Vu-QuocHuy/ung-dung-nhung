import apiClient from './api.client';
import { API_ENDPOINTS } from '../config/api.config';

export interface Alert {
  _id: string;
  type: 'info' | 'warning' | 'critical';
  message: string;
  isRead: boolean;
  timestamp?: string; // optional legacy
  status?: 'active' | 'resolved';
  severity?: string;
  title?: string;
  targetAll?: boolean;
  targetUsers?: string[];
  createdAt?: string;
  updatedAt?: string;
  resolvedAt?: string;
}

export interface AlertParams {
  status?: 'active' | 'resolved';
  level?: 'info' | 'warning' | 'critical'; // legacy
  severity?: 'info' | 'warning' | 'critical';
  isRead?: boolean;
  limit?: number;
  page?: number;
}

export const alertService = {
  async getAll(params?: AlertParams): Promise<{
    success: boolean;
    count: number;
    total: number;
    page: number;
    pages: number;
    data: Alert[];
  }> {
    const response = await apiClient.get<{
      success: boolean;
      count: number;
      total: number;
      page: number;
      pages: number;
      data: Alert[];
    }>(API_ENDPOINTS.ALERTS.BASE, { params });
    return response.data;
  },

  async create(payload: {
    title: string;
    message: string;
    severity?: 'info' | 'warning' | 'critical';
    type?: string;
    targetAll?: boolean;
    targetUsers?: string[];
    data?: any;
  }): Promise<{ success: boolean; data: Alert }> {
    const response = await apiClient.post<{ success: boolean; data: Alert }>(
      API_ENDPOINTS.ALERTS.BASE,
      payload
    );
    return response.data;
  },

  /**
   * Lấy danh sách cảnh báo chưa được xử lý cho user hiện tại.
   * Backend hiện tại không có route `/alerts/unread`, nên ta dùng
   * `/alerts?status=active` và coi các cảnh báo `active` là chưa đọc.
   */
  async getUnread(limit: number = 50): Promise<Alert[]> {
    const response = await apiClient.get<{
      success: boolean;
      count: number;
      total: number;
      data: Alert[];
    }>(API_ENDPOINTS.ALERTS.BASE, {
      params: {
        status: 'active',
        limit,
      },
    });

    return response.data.data;
  },

  async markAsRead(id: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.put<{ success: boolean; message: string }>(
      API_ENDPOINTS.ALERTS.READ(id)
    );
    return response.data;
  },

  async resolve(id: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.put<{ success: boolean; message: string }>(
      API_ENDPOINTS.ALERTS.RESOLVE(id)
    );
    return response.data;
  },

  async delete(id: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.delete<{ success: boolean; message: string }>(
      API_ENDPOINTS.ALERTS.BY_ID(id)
    );
    return response.data;
  },
};


import apiClient from './api.client';
import { API_ENDPOINTS } from '../config/api.config';

export interface ActivityLog {
  _id: string;
  userId: string | { _id: string; username?: string; email?: string; role?: string };
  username?: string;
  action: string;
  target?: string;
  resourceType?: string;
  resourceId?: string;
  resourceName?: string;
  status: 'success' | 'failed';
  timestamp?: string;
  createdAt?: string;
  updatedAt?: string;
  details?: any;
}

export interface ActivityLogParams {
  userId?: string;
  action?: string;
  status?: 'success' | 'failure';
  startDate?: string;
  endDate?: string;
  limit?: number;
  page?: number;
}

export const activityLogService = {
  async getMyLogs(params?: { limit?: number; page?: number }): Promise<ActivityLog[]> {
    const response = await apiClient.get<{ success: boolean; data: ActivityLog[] }>(
      API_ENDPOINTS.ACTIVITY_LOGS.MY_LOGS,
      { params }
    );
    return response.data.data;
  },

  async getAll(params?: ActivityLogParams): Promise<{
    success: boolean;
    data: ActivityLog[];
    pagination: {
      total: number;
      page: number;
      pages: number;
      limit: number;
    };
  }> {
    const response = await apiClient.get<{
      success: boolean;
      data: {
        logs: ActivityLog[];
        pagination: {
          total: number;
          page: number;
          pages: number;
          limit: number;
        };
      };
    }>(API_ENDPOINTS.ACTIVITY_LOGS.BASE, { params });
    return {
      success: response.data.success,
      data: response.data.data.logs || [],
      pagination: response.data.data.pagination,
    };
  },

  async getStats(params?: { startDate?: string; endDate?: string }): Promise<any> {
    const response = await apiClient.get(API_ENDPOINTS.ACTIVITY_LOGS.STATS, { params });
    return response.data;
  },
};


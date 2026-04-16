import apiClient from './api.client';
import { API_ENDPOINTS } from '../config/api.config';

export interface User {
  _id: string;
  username: string;
  email: string;
  phone?: string;
  address?: string;
  role: 'admin' | 'user';
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface UserParams {
  page?: number;
  limit?: number;
  role?: 'admin' | 'user';
  isActive?: boolean;
  search?: string;
}

export interface Pagination {
  currentPage: number;
  totalPages: number;
  totalUsers: number;
  limit: number;
}

export interface UpdateUserData {
  email?: string;
  phone?: string;
  address?: string;
  role?: 'admin' | 'user';
  isActive?: boolean;
}

export const userService = {
  async getAll(params?: UserParams): Promise<{ success: boolean; data: User[]; pagination: Pagination }> {
    const response = await apiClient.get<{ success: boolean; data: User[]; pagination: Pagination }>(
      API_ENDPOINTS.USERS.BASE,
      { params }
    );
    return response.data;
  },

  async getById(id: string): Promise<User> {
    const response = await apiClient.get<{ success: boolean; data: User }>(
      API_ENDPOINTS.USERS.BY_ID(id)
    );
    return response.data.data;
  },

  async update(id: string, data: UpdateUserData): Promise<{ success: boolean; data: User }> {
    const response = await apiClient.put<{ success: boolean; data: User }>(
      API_ENDPOINTS.USERS.BY_ID(id),
      data
    );
    return response.data;
  },

  async toggleStatus(id: string): Promise<{ success: boolean; data: User }> {
    const response = await apiClient.put<{ success: boolean; data: User }>(
      API_ENDPOINTS.USERS.TOGGLE_STATUS(id)
    );
    return response.data;
  },

  async delete(id: string): Promise<{ success: boolean; message: string }> {
    const response = await apiClient.delete<{ success: boolean; message: string }>(
      API_ENDPOINTS.USERS.BY_ID(id)
    );
    return response.data;
  },
};


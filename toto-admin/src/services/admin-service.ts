import api from '@/lib/api';
import type { 
  DashboardStats, 
  PaginatedResponse, 
  User, 
  Deliverer, 
  Delivery 
} from '@/types';

// Dashboard
export const getDashboardStats = async (): Promise<DashboardStats> => {
  const response = await api.get('/admin/dashboard');
  return response.data;
};

export const getRevenueAnalytics = async (period: string = 'week') => {
  const response = await api.get(`/admin/analytics/revenue?period=${period}`);
  return response.data;
};

export const getDeliveriesAnalytics = async (period: string = 'week', status?: string) => {
  const params = new URLSearchParams({ period });
  if (status) params.append('status', status);
  const response = await api.get(`/admin/analytics/deliveries?${params}`);
  return response.data;
};

// Users
export const getUsers = async (
  page: number = 1, 
  limit: number = 20, 
  search?: string, 
  isActive?: boolean
): Promise<PaginatedResponse<User>> => {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (search) params.append('search', search);
  if (isActive !== undefined) params.append('isActive', String(isActive));
  const response = await api.get(`/admin/users?${params}`);
  return response.data;
};

export const getUserById = async (id: string) => {
  const response = await api.get(`/admin/users/${id}`);
  return response.data;
};

export const updateUser = async (id: string, data: { is_active?: boolean }) => {
  const response = await api.patch(`/admin/users/${id}`, data);
  return response.data;
};

export const getUserTransactions = async (id: string) => {
  const response = await api.get(`/admin/users/${id}/transactions`);
  return response.data;
};

// Deliverers
export const getDeliverers = async (
  page: number = 1, 
  limit: number = 20, 
  kycStatus?: string, 
  isActive?: boolean,
  isAvailable?: boolean,
  search?: string
): Promise<PaginatedResponse<Deliverer>> => {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (search) params.append('search', search);
  if (kycStatus) params.append('kycStatus', kycStatus);
  if (isActive !== undefined) params.append('isActive', String(isActive));
  if (isAvailable !== undefined) params.append('isAvailable', String(isAvailable));
  const response = await api.get(`/admin/deliverers?${params}`);
  return response.data;
};

export const getDelivererById = async (id: string) => {
  const response = await api.get(`/admin/deliverers/${id}`);
  return response.data;
};

export const updateDeliverer = async (id: string, data: { is_active?: boolean; is_available?: boolean }) => {
  const response = await api.patch(`/admin/deliverers/${id}`, data);
  return response.data;
};

export const approveKyc = async (id: string, data: { kyc_status: 'approved' | 'rejected'; rejection_reason?: string }) => {
  const response = await api.post(`/admin/deliverers/${id}/kyc`, data);
  return response.data;
};

export const getDelivererEarnings = async (id: string, startDate?: string, endDate?: string) => {
  const params = new URLSearchParams();
  if (startDate) params.append('startDate', startDate);
  if (endDate) params.append('endDate', endDate);
  const response = await api.get(`/admin/deliverers/${id}/earnings?${params}`);
  return response.data;
};

// Deliveries
export const getDeliveries = async (
  page: number = 1, 
  limit: number = 20, 
  status?: string,
  startDate?: string,
  endDate?: string,
  search?: string
): Promise<PaginatedResponse<Delivery>> => {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (status) params.append('status', status);
  if (startDate) params.append('startDate', startDate);
  if (endDate) params.append('endDate', endDate);
  if (search) params.append('search', search);
  const response = await api.get(`/admin/deliveries?${params}`);
  return response.data;
};

export const getDeliveryById = async (id: string) => {
  const response = await api.get(`/admin/deliveries/${id}`);
  return response.data;
};

export const cancelDelivery = async (id: string, reason: string) => {
  const response = await api.post(`/admin/deliveries/${id}/cancel`, { reason });
  return response.data;
};

// Quotas
export const getQuotaPurchases = async (
  page: number = 1,
  limit: number = 20,
  startDate?: string,
  endDate?: string,
  userType?: 'client' | 'deliverer'
) => {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (startDate) params.append('startDate', startDate);
  if (endDate) params.append('endDate', endDate);
  if (userType) params.append('userType', userType);
  const response = await api.get(`/admin/quotas/purchases?${params}`);
  return response.data;
};

export const getQuotaRevenue = async (period: string = 'month') => {
  const response = await api.get(`/admin/quotas/revenue?period=${period}`);
  return response.data;
};



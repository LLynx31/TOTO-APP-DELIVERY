// Admin types
export interface Admin {
  id: string;
  email: string;
  full_name: string;
  role: 'super_admin' | 'admin' | 'moderator';
  is_active: boolean;
  created_at: string;
  updated_at: string;
  last_login_at: string | null;
}

// User types
export interface User {
  id: string;
  phone_number: string;
  full_name: string;
  email: string | null;
  is_verified: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Deliverer types
export interface Deliverer {
  id: string;
  phone_number: string;
  full_name: string;
  email: string | null;
  photo_url: string | null;
  vehicle_type: string | null;
  license_plate: string | null;
  id_card_front_url: string | null;
  id_card_back_url: string | null;
  driver_license_url: string | null;
  kyc_status: 'pending' | 'approved' | 'rejected';
  kyc_submitted_at: string | null;
  kyc_reviewed_at: string | null;
  is_available: boolean;
  is_active: boolean;
  is_verified: boolean;
  total_deliveries: number;
  rating: number;
  created_at: string;
  updated_at: string;
}

// Delivery types
export type DeliveryStatus = 
  | 'pending'
  | 'accepted'
  | 'pickupInProgress'
  | 'pickedUp'
  | 'deliveryInProgress'
  | 'delivered'
  | 'cancelled';

export interface Delivery {
  id: string;
  client_id: string;
  deliverer_id: string | null;
  pickup_address: string;
  pickup_latitude: number;
  pickup_longitude: number;
  pickup_phone: string | null;
  delivery_address: string;
  delivery_latitude: number;
  delivery_longitude: number;
  delivery_phone: string;
  receiver_name: string;
  package_description: string | null;
  package_weight: number | null;
  qr_code_pickup: string;
  qr_code_delivery: string;
  status: DeliveryStatus;
  price: number;
  distance_km: number | null;
  special_instructions: string | null;
  accepted_at: string | null;
  picked_up_at: string | null;
  delivered_at: string | null;
  cancelled_at: string | null;
  created_at: string;
  updated_at: string;
}

// Dashboard types
export interface DashboardStats {
  total_users: number;
  total_deliverers: number;
  active_deliveries: number;
  total_deliveries: number;
  total_revenue: number;
  new_users_today: number;
  deliveries_today: number;
}

// Paginated response
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Auth types
export interface LoginResponse {
  admin: Admin;
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}



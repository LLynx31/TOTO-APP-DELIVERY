import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import Cookies from 'js-cookie';
import api from '@/lib/api';
import type { Admin } from '@/types';

interface AuthState {
  admin: Admin | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
  checkAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      admin: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.post('/auth/admin/login', { email, password });
          const { admin, access_token, refresh_token } = response.data;

          Cookies.set('access_token', access_token, { expires: 1 });
          Cookies.set('refresh_token', refresh_token, { expires: 7 });

          set({ admin, isAuthenticated: true, isLoading: false });
          return true;
        } catch (error: any) {
          const message = error.response?.data?.message || 'Erreur de connexion';
          set({ error: message, isLoading: false });
          return false;
        }
      },

      logout: () => {
        Cookies.remove('access_token');
        Cookies.remove('refresh_token');
        set({ admin: null, isAuthenticated: false });
      },

      checkAuth: async () => {
        const token = Cookies.get('access_token');
        if (!token) {
          set({ isAuthenticated: false, admin: null });
          return;
        }

        try {
          // For now, just check if token exists
          // In production, you might want to validate with backend
          set({ isAuthenticated: true });
        } catch {
          set({ isAuthenticated: false, admin: null });
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ admin: state.admin, isAuthenticated: state.isAuthenticated }),
    }
  )
);



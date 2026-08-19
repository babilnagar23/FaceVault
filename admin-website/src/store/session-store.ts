import { create } from 'zustand';

type SessionState = {
  authenticated: boolean;
  role: 'Owner' | 'Admin' | 'HR' | 'Manager' | 'Supervisor';
  login: () => void;
  logout: () => void;
};

export const useSessionStore = create<SessionState>((set) => ({
  authenticated: false,
  role: 'Admin',
  login: () => set({ authenticated: true }),
  logout: () => set({ authenticated: false })
}));


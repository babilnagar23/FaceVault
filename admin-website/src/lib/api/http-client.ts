/**
 * FaceVault Admin — Typed HTTP API client
 * Replaces all mock functions in admin-api.ts with real fetch calls to FastAPI.
 *
 * Usage: Set NEXT_PUBLIC_API_URL in .env.local
 * Integration: Replace adminAuthApi, employeeApi, etc. in admin-api.ts imports
 */

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000/api/v1';

// ─── Token storage (replace with httpOnly cookie in production) ───────────────

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return sessionStorage.getItem('fv_access_token');
}

function setTokens(access: string, refresh: string) {
  sessionStorage.setItem('fv_access_token', access);
  sessionStorage.setItem('fv_refresh_token', refresh);
}

function clearTokens() {
  sessionStorage.removeItem('fv_access_token');
  sessionStorage.removeItem('fv_refresh_token');
}

// ─── HTTP Client ──────────────────────────────────────────────────────────────

async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> ?? {}),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, { ...options, headers });

  if (res.status === 401) {
    clearTokens();
    if (typeof window !== 'undefined') window.location.href = '/login';
    throw new Error('Session expired.');
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.error?.message ?? `HTTP ${res.status}`);
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

export const adminAuthApiHttp = {
  async login(input: { organisationCode: string; email: string; password: string }) {
    const data = await apiFetch<{ tokens: { access_token: string; refresh_token: string }; user: Record<string, unknown> }>(
      '/auth/admin/login',
      { method: 'POST', body: JSON.stringify({ organisation_code: input.organisationCode, email: input.email, password: input.password }) },
    );
    setTokens(data.tokens.access_token, data.tokens.refresh_token);
    return { mfaRequired: false };
  },
  async logout() {
    try { await apiFetch('/auth/logout', { method: 'POST' }); } finally { clearTokens(); }
  },
};

// ─── Employees ────────────────────────────────────────────────────────────────

export const employeeApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/employees'); },
  async detail(id: string) { return apiFetch<unknown>(`/admin/employees/${id}`); },
  async create(data: Record<string, unknown>) {
    return apiFetch<unknown>('/admin/employees', { method: 'POST', body: JSON.stringify(data) });
  },
  async update(id: string, data: Record<string, unknown>) {
    return apiFetch<unknown>(`/admin/employees/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  },
};

// ─── Attendance (Admin) ───────────────────────────────────────────────────────

export const attendanceAdminApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/attendance'); },
};

// ─── Verification ─────────────────────────────────────────────────────────────

export const verificationApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/verification'); },
  async detail(id: string) { return apiFetch<unknown>(`/admin/verification/${id}`); },
  async decide(id: string, decision: 'approve' | 'reject' | 'request_explanation', notes?: string) {
    return apiFetch<unknown>(`/admin/verification/${id}/${decision}`, {
      method: 'POST',
      body: JSON.stringify({ decision, notes }),
    });
  },
};

// ─── Help Desk ────────────────────────────────────────────────────────────────

export const helpDeskApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/help/tickets'); },
  async detail(id: string) { return apiFetch<unknown>(`/help/tickets/${id}`); },
  async resolve(id: string) {
    return apiFetch<unknown>(`/admin/help/tickets/${id}/resolve`, { method: 'POST' });
  },
  async postNote(id: string, note: string) {
    return apiFetch<unknown>(`/admin/help/tickets/${id}/notes`, {
      method: 'POST',
      body: JSON.stringify({ body: note }),
    });
  },
};

// ─── Locations ────────────────────────────────────────────────────────────────

export const locationAdminApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/locations'); },
  async detail(id: string) { return apiFetch<unknown>(`/admin/locations/${id}`); },
  async create(data: Record<string, unknown>) {
    return apiFetch<unknown>('/admin/locations', { method: 'POST', body: JSON.stringify(data) });
  },
  async update(id: string, data: Record<string, unknown>) {
    return apiFetch<unknown>(`/admin/locations/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  },
};

// ─── Announcements ────────────────────────────────────────────────────────────

export const announcementAdminApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/announcements'); },
  async detail(id: string) { return apiFetch<unknown>(`/announcements/${id}`); },
  async create(data: Record<string, unknown>) {
    return apiFetch<unknown>('/admin/announcements', { method: 'POST', body: JSON.stringify(data) });
  },
};

// ─── Reports ─────────────────────────────────────────────────────────────────

export const reportApiHttp = {
  async dashboard() { return apiFetch<unknown[]>('/admin/reports/dashboard'); },
  async departments() { return apiFetch<unknown[]>('/admin/reports/departments'); },
  async exportAttendance(params: { dateFrom: string; dateTo: string; format?: string }) {
    return apiFetch<{ task_id: string; download_url?: string }>(
      `/admin/reports/export/attendance?date_from=${params.dateFrom}&date_to=${params.dateTo}&format=${params.format ?? 'csv'}`,
    );
  },
};

// ─── Dashboard ────────────────────────────────────────────────────────────────

export const dashboardApiHttp = {
  async kpis() { return apiFetch<Record<string, unknown>>('/admin/dashboard/kpis'); },
  async recentActivity() { return apiFetch<unknown[]>('/admin/dashboard/activity'); },
};

// ─── Audit ───────────────────────────────────────────────────────────────────

export const auditApiHttp = {
  async list() { return apiFetch<unknown[]>('/admin/audit-logs'); },
};

// ─── Settings ────────────────────────────────────────────────────────────────

export const settingsApiHttp = {
  async get() { return apiFetch<Record<string, unknown>>('/admin/settings'); },
  async updateAttendance(data: Record<string, unknown>) {
    return apiFetch('/admin/settings/attendance', { method: 'PATCH', body: JSON.stringify(data) });
  },
  async updateBiometrics(data: Record<string, unknown>) {
    return apiFetch('/admin/settings/biometrics', { method: 'PATCH', body: JSON.stringify(data) });
  },
};

import type {
  ActivityItem,
  ActivityNote,
  Announcement,
  AuditLog,
  DepartmentAttendance,
  Employee,
  HelpTicket,
  LocationSite,
  ReportData,
  VerificationCase,
} from '@/types/domain';

export type AdminAuthApi = {
  login(input: { organisationCode: string; email: string; password: string }): Promise<{ mfaRequired: boolean }>;
  logout(): Promise<void>;
};

export const adminAuthApi: AdminAuthApi = {
  async login() {
    await wait(400);
    return { mfaRequired: false };
  },
  async logout() {
    await wait(150);
  },
};

// ─────────────────────────────────────────────────────────
// EMPLOYEES
// ─────────────────────────────────────────────────────────

export const employeeApi = {
  async list(): Promise<Employee[]> {
    await wait(250);
    return employees;
  },
  async detail(id: string): Promise<Employee> {
    await wait(200);
    return employees.find((e) => e.id === id) ?? employees[0];
  },
};

// ─────────────────────────────────────────────────────────
// ATTENDANCE
// ─────────────────────────────────────────────────────────

export const attendanceAdminApi = {
  async list() {
    await wait(250);
    return [
      { id: 'ATT-9001', employee: 'Aarav Mehta', employeeId: 'EMP-1042', status: 'Present', time: '09:02 AM', site: 'Sector 17', faceScore: 99.2, gpsAccuracy: '4m', date: 'Today' },
      { id: 'ATT-9002', employee: 'Nisha Rao', employeeId: 'EMP-1177', status: 'Location Error', time: '09:14 AM', site: 'Sector 17', faceScore: 94.1, gpsAccuracy: '18m', date: 'Today' },
      { id: 'ATT-9003', employee: 'Kabir Shah', employeeId: 'EMP-1320', status: 'Late', time: '09:24 AM', site: 'Depot 4', faceScore: 91.3, gpsAccuracy: '12m', date: 'Today' },
      { id: 'ATT-9004', employee: 'Priya Kumar', employeeId: 'EMP-1401', status: 'Present', time: '08:55 AM', site: 'Sector 17', faceScore: 97.8, gpsAccuracy: '3m', date: 'Today' },
      { id: 'ATT-9005', employee: 'Rohan Gupta', employeeId: 'EMP-1528', status: 'Absent', time: '--', site: 'Depot 4', faceScore: 0, gpsAccuracy: '--', date: 'Today' },
    ];
  },
};

// ─────────────────────────────────────────────────────────
// VERIFICATION QUEUE
// ─────────────────────────────────────────────────────────

export const verificationApi = {
  async list(): Promise<VerificationCase[]> {
    await wait(250);
    return verificationCases;
  },
  async detail(id: string): Promise<VerificationCase> {
    await wait(200);
    return verificationCases.find((v) => v.id === id) ?? verificationCases[0];
  },
  async decide(id: string, decision: 'approve' | 'reject' | 'request_explanation') {
    await wait(300);
    return { id, decision };
  },
};

// ─────────────────────────────────────────────────────────
// HELP DESK
// ─────────────────────────────────────────────────────────

export const helpDeskApi = {
  async list(): Promise<HelpTicket[]> {
    await wait(250);
    return tickets;
  },
  async detail(id: string): Promise<HelpTicket> {
    await wait(200);
    return tickets.find((t) => t.id === id) ?? tickets[0];
  },
  async resolve(id: string) {
    await wait(200);
    return { id, status: 'Resolved' };
  },
  async postNote(id: string, note: string) {
    await wait(200);
    return { id, note };
  },
};

// ─────────────────────────────────────────────────────────
// LOCATIONS
// ─────────────────────────────────────────────────────────

export const locationAdminApi = {
  async list(): Promise<LocationSite[]> {
    await wait(250);
    return locations;
  },
  async detail(id: string): Promise<LocationSite> {
    await wait(200);
    return locations.find((l) => l.id === id) ?? locations[0];
  },
  async create(data: Partial<LocationSite>): Promise<LocationSite> {
    await wait(400);
    return { id: `LOC-${Date.now()}`, active: true, assignedEmployees: 0, ...data } as LocationSite;
  },
};

// ─────────────────────────────────────────────────────────
// ANNOUNCEMENTS
// ─────────────────────────────────────────────────────────

export const announcementAdminApi = {
  async list(): Promise<Announcement[]> {
    await wait(200);
    return announcements;
  },
  async detail(id: string): Promise<Announcement> {
    await wait(200);
    return announcements.find((a) => a.id === id) ?? announcements[0];
  },
  async create(data: Partial<Announcement>): Promise<Announcement> {
    await wait(400);
    return { id: `ANN-${Date.now()}`, status: 'Published', pinned: false, ...data } as Announcement;
  },
};

// ─────────────────────────────────────────────────────────
// REPORTS
// ─────────────────────────────────────────────────────────

export const reportApi = {
  async dashboard(): Promise<ReportData[]> {
    await wait(200);
    return [
      { day: 'Mon', present: 430, absent: 22, late: 18 },
      { day: 'Tue', present: 448, absent: 15, late: 12 },
      { day: 'Wed', present: 441, absent: 19, late: 20 },
      { day: 'Thu', present: 459, absent: 10, late: 11 },
      { day: 'Fri', present: 452, absent: 14, late: 9 },
    ];
  },
  async departments(): Promise<DepartmentAttendance[]> {
    await wait(200);
    return [
      { department: 'Engineering', percent: 92, color: '#0F4C81' },
      { department: 'HR', percent: 95, color: '#1E88E5' },
      { department: 'Finance', percent: 98, color: '#2E7D32' },
      { department: 'Operations', percent: 88, color: '#ED6C02' },
      { department: 'Marketing', percent: 82, color: '#D32F2F' },
    ];
  },
};

// ─────────────────────────────────────────────────────────
// SETTINGS
// ─────────────────────────────────────────────────────────

export const settingsApi = {
  async sections() {
    await wait(150);
    return ['Organisation', 'Attendance', 'Biometrics', 'Offline', 'Notifications', 'Roles'];
  },
};

// ─────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────

export const dashboardApi = {
  async kpis() {
    await wait(200);
    return {
      totalEmployees: 1240,
      presentToday: 1102,
      presentTrend: '+4.8%',
      absentToday: 84,
      late: 54,
      pendingVerification: 12,
      activeLocations: 15,
    };
  },
  async recentActivity(): Promise<ActivityItem[]> {
    await wait(200);
    return [
      { id: '1', actor: 'Sarah Jenkins', action: 'clocked in.', context: 'Engineering HQ', time: '09:02 AM', type: 'checkin' },
      { id: '2', actor: 'Michael Chen', action: 'marked as Late.', context: 'Marketing Dept', time: '08:45 AM', type: 'late' },
      { id: '3', actor: 'AI Sync', action: 'completed successfully.', context: 'Processed 42 offline entries.', time: '08:30 AM', type: 'sync' },
      { id: '4', actor: 'Verification Failed', action: 'for Entry #882.', context: 'Face ID mismatch detected. Security Gate B', time: '08:15 AM', type: 'failed' },
      { id: '5', actor: 'Daily Report', action: 'generated.', context: 'System', time: '06:00 AM', type: 'report' },
    ];
  },
};

// ─────────────────────────────────────────────────────────
// AUDIT
// ─────────────────────────────────────────────────────────

export const auditApi = {
  async list(): Promise<AuditLog[]> {
    await wait(250);
    return [
      { id: 'AUD-1', event: 'Employee deactivated', actor: 'Admin (admin@facevault.io)', target: 'EMP-1320', timestamp: '2026-08-20 14:32', details: 'Employee voluntarily resigned.' },
      { id: 'AUD-2', event: 'Verification approved', actor: 'Admin (admin@facevault.io)', target: 'VER-3001', timestamp: '2026-08-20 09:14', details: 'GPS boundary override approved.' },
      { id: 'AUD-3', event: 'Face re-enrollment triggered', actor: 'System', target: 'EMP-1177', timestamp: '2026-08-19 17:00', details: 'Biometric quality fell below threshold.' },
      { id: 'AUD-4', event: 'Location added', actor: 'Admin (admin@facevault.io)', target: 'LOC-3', timestamp: '2026-08-18 11:20', details: 'New site: Depot 8.' },
    ];
  },
};

// ─────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────

const employees: Employee[] = [
  { id: 'EMP-1042', name: 'Aarav Mehta', department: 'Operations', role: 'Site Supervisor', project: 'Metro Expansion', location: 'Sector 17', shift: '09:00 - 18:00', faceStatus: 'Enrolled', deviceStatus: 'Registered', attendancePercent: 96, status: 'Active', joinDate: '2024-03-01', manager: 'K. Sharma', siteCode: 'DEL-MR-02' },
  { id: 'EMP-1177', name: 'Nisha Rao', department: 'Safety', role: 'Safety Officer', project: 'Metro Expansion', location: 'Sector 17', shift: '09:00 - 18:00', faceStatus: 'Enrolled', deviceStatus: 'Registered', attendancePercent: 92, status: 'Active', joinDate: '2023-08-15', manager: 'P. Singh' },
  { id: 'EMP-1320', name: 'Kabir Shah', department: 'Logistics', role: 'Logistics Coordinator', project: 'Depot Upgrade', location: 'Depot 4', shift: '10:00 - 19:00', faceStatus: 'Re-enroll', deviceStatus: 'Missing', attendancePercent: 84, status: 'Active', joinDate: '2022-11-20', manager: 'R. Verma' },
  { id: 'EMP-1401', name: 'Priya Kumar', department: 'Engineering', role: 'Field Engineer', project: 'Metro Expansion', location: 'Sector 17', shift: '08:00 - 17:00', faceStatus: 'Enrolled', deviceStatus: 'Registered', attendancePercent: 98, status: 'Active', joinDate: '2025-01-10', manager: 'K. Sharma' },
  { id: 'EMP-1528', name: 'Rohan Gupta', department: 'Logistics', role: 'Driver', project: 'Depot Upgrade', location: 'Depot 4', shift: '07:00 - 16:00', faceStatus: 'Pending', deviceStatus: 'Registered', attendancePercent: 79, status: 'Active', joinDate: '2025-04-22', manager: 'R. Verma' },
];

const verificationCases: VerificationCase[] = [
  { id: 'VER-3001', employee: 'Nisha Rao', employeeRole: 'Safety Officer', employeeDept: 'Engineering Dept', scanTime: '09:14 AM', assignedSite: 'Sector 17', currentCoordinates: '28.5912, 77.0489', distance: '1.4 km', gpsAccuracy: '18 m', faceScore: 0.94, livenessScore: 0.97, status: 'Needs Review' },
  { id: 'VER-3002', employee: 'Kabir Shah', employeeRole: 'Logistics Coordinator', employeeDept: 'Logistics Dept', scanTime: '10:12 AM', assignedSite: 'Depot 4', currentCoordinates: '28.6121, 77.0820', distance: '620 m', gpsAccuracy: '12 m', faceScore: 0.91, livenessScore: 0.95, status: 'Needs Review' },
];

const tickets: HelpTicket[] = [
  {
    id: '#TK-4092',
    employee: 'John Smith',
    issue: 'Authentication Failure - Loading Dock C',
    category: 'Face Recognition',
    status: 'In Progress',
    description: 'Employee repeatedly attempted to clock in at Terminal K-09. The system prompts "Face Not Recognized" despite multiple attempts. The employee states they are not wearing hats or glasses, and the lighting in Dock C appears normal. Requesting override or biometric reset.',
    deviceTerminal: 'Terminal K-09 (Dock C)',
    timeLogged: 'Oct 24, 07:15 AM',
    attachmentCount: 1,
    activityLog: [
      { author: 'System', time: '07:16 AM', body: 'Ticket auto-created from Terminal K-09 anomaly report.', isSystem: true },
      { author: 'SysAdmin', time: '07:45 AM', body: 'Checked terminal logs. Camera sensor might need recalibration. Sending a reset command now.' },
    ],
  },
  {
    id: '#TK-4091',
    employee: 'A. Lee',
    issue: 'Geofence Boundary Issue',
    category: 'Location Error',
    status: 'Open',
    description: 'Mobile app shows user outside geofence while physically in the main office.',
    deviceTerminal: 'Personal Mobile',
    timeLogged: 'Oct 24, 06:58 AM',
    attachmentCount: 0,
    activityLog: [],
  },
];

const locations: LocationSite[] = [
  { id: 'LOC-1', name: 'Sector 17', project: 'Metro Expansion', address: 'Sector 17 work site, Delhi NCR', latitude: 28.5901, longitude: 77.0479, radius: 150, active: true, assignedEmployees: 214 },
  { id: 'LOC-2', name: 'Depot 4', project: 'Depot Upgrade', address: 'Depot 4 maintenance yard, Delhi NCR', latitude: 28.6129, longitude: 77.0831, radius: 120, active: true, assignedEmployees: 88 },
  { id: 'LOC-3', name: 'HQ Office', project: 'Administration', address: 'Corporate headquarters, Gurugram', latitude: 28.4595, longitude: 77.0266, radius: 200, active: true, assignedEmployees: 52 },
];

const announcements: Announcement[] = [
  { id: 'ANN-1', title: 'Safety Update', category: 'Safety', target: 'All employees', status: 'Published', pinned: true, body: 'All personnel must wear safety helmets at work sites effective immediately.', publishedAt: '2026-08-21 08:00' },
  { id: 'ANN-2', title: 'Holiday Notice', category: 'Policy', target: 'Operations', status: 'Scheduled', pinned: false, body: 'Please review the updated holiday schedule for August.', publishedAt: '2026-08-22 09:00' },
  { id: 'ANN-3', title: 'Metro Phase II Update', category: 'Project', target: 'Metro Expansion team', status: 'Published', pinned: false, body: 'Phase II groundwork begins Monday. Updated geofence boundaries active.', publishedAt: '2026-08-20 14:00' },
];

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

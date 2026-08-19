import type { Employee, HelpTicket, LocationSite, VerificationCase } from '@/types/domain';

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
  }
};

export const employeeApi = {
  async list(): Promise<Employee[]> {
    await wait(250);
    return employees;
  },
  async detail(id: string): Promise<Employee> {
    await wait(200);
    return employees.find((employee) => employee.id === id) ?? employees[0];
  }
};

export const attendanceAdminApi = {
  async list() {
    await wait(250);
    return [
      { id: 'ATT-9001', employee: 'Aarav Mehta', status: 'Present', time: '09:02', site: 'Sector 17' },
      { id: 'ATT-9002', employee: 'Nisha Rao', status: 'Location Error', time: '09:14', site: 'Sector 17' },
      { id: 'ATT-9003', employee: 'Kabir Shah', status: 'Late', time: '09:24', site: 'Depot 4' }
    ];
  }
};

export const verificationApi = {
  async list(): Promise<VerificationCase[]> {
    await wait(250);
    return verificationCases;
  },
  async detail(id: string): Promise<VerificationCase> {
    await wait(200);
    return verificationCases.find((item) => item.id === id) ?? verificationCases[0];
  },
  async decide(id: string, decision: 'approve' | 'reject' | 'request_explanation') {
    await wait(200);
    return { id, decision };
  }
};

export const helpDeskApi = {
  async list(): Promise<HelpTicket[]> {
    await wait(250);
    return tickets;
  },
  async detail(id: string): Promise<HelpTicket> {
    await wait(200);
    return tickets.find((ticket) => ticket.id === id) ?? tickets[0];
  }
};

export const locationAdminApi = {
  async list(): Promise<LocationSite[]> {
    await wait(250);
    return locations;
  }
};

export const announcementAdminApi = {
  async list() {
    await wait(200);
    return [
      { id: 'ANN-1', title: 'Safety Update', target: 'All employees', status: 'Published', pinned: true },
      { id: 'ANN-2', title: 'Holiday Notice', target: 'Operations', status: 'Scheduled', pinned: false }
    ];
  }
};

export const reportApi = {
  async dashboard() {
    await wait(200);
    return [
      { day: 'Mon', present: 430, absent: 22, late: 18 },
      { day: 'Tue', present: 448, absent: 15, late: 12 },
      { day: 'Wed', present: 441, absent: 19, late: 20 },
      { day: 'Thu', present: 459, absent: 10, late: 11 },
      { day: 'Fri', present: 452, absent: 14, late: 9 }
    ];
  }
};

export const settingsApi = {
  async sections() {
    await wait(150);
    return ['Attendance', 'Biometrics', 'Offline', 'Organisation', 'Notifications', 'Roles'];
  }
};

const employees: Employee[] = [
  { id: 'EMP-1042', name: 'Aarav Mehta', department: 'Operations', project: 'Metro Expansion', location: 'Sector 17', shift: '09:00 - 18:00', faceStatus: 'Enrolled', deviceStatus: 'Registered', attendancePercent: 96, status: 'Active' },
  { id: 'EMP-1177', name: 'Nisha Rao', department: 'Safety', project: 'Metro Expansion', location: 'Sector 17', shift: '09:00 - 18:00', faceStatus: 'Enrolled', deviceStatus: 'Registered', attendancePercent: 92, status: 'Active' },
  { id: 'EMP-1320', name: 'Kabir Shah', department: 'Logistics', project: 'Depot Upgrade', location: 'Depot 4', shift: '10:00 - 19:00', faceStatus: 'Re-enroll', deviceStatus: 'Missing', attendancePercent: 84, status: 'Active' }
];

const verificationCases: VerificationCase[] = [
  { id: 'VER-3001', employee: 'Nisha Rao', scanTime: '09:14', assignedSite: 'Sector 17', currentCoordinates: '28.5912, 77.0489', distance: '1.4 km', gpsAccuracy: '18 m', faceScore: 0.94, livenessScore: 0.97, status: 'Needs Review' },
  { id: 'VER-3002', employee: 'Kabir Shah', scanTime: '10:12', assignedSite: 'Depot 4', currentCoordinates: '28.6121, 77.0820', distance: '620 m', gpsAccuracy: '12 m', faceScore: 0.91, livenessScore: 0.95, status: 'Needs Review' }
];

const tickets: HelpTicket[] = [
  { id: 'HELP-10382', employee: 'Aarav Mehta', issue: 'GPS Problem', status: 'Open', description: 'GPS accuracy is unstable near Gate 2.' },
  { id: 'HELP-10383', employee: 'Nisha Rao', issue: 'Wrong Assigned Location', status: 'Urgent', description: 'Assigned to Sector 17 but currently posted to Site A.' }
];

const locations: LocationSite[] = [
  { id: 'LOC-1', name: 'Sector 17', project: 'Metro Expansion', address: 'Sector 17 work site', latitude: 28.5901, longitude: 77.0479, radius: 150, active: true, assignedEmployees: 214 },
  { id: 'LOC-2', name: 'Depot 4', project: 'Depot Upgrade', address: 'Depot 4 maintenance yard', latitude: 28.6129, longitude: 77.0831, radius: 120, active: true, assignedEmployees: 88 }
];

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}


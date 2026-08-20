export type AttendanceStatus =
  | 'Present'
  | 'Absent'
  | 'Late'
  | 'Leave'
  | 'Location Error'
  | 'Face Failed'
  | 'Pending Review'
  | 'Pending Sync';

export type Employee = {
  id: string;
  name: string;
  department: string;
  role: string;
  project: string;
  location: string;
  shift: string;
  faceStatus: 'Enrolled' | 'Pending' | 'Re-enroll';
  deviceStatus: 'Registered' | 'Revoked' | 'Missing';
  attendancePercent: number;
  status: 'Active' | 'Inactive';
  joinDate?: string;
  manager?: string;
  siteCode?: string;
};

export type VerificationCase = {
  id: string;
  employee: string;
  employeeRole?: string;
  employeeDept?: string;
  scanTime: string;
  assignedSite: string;
  currentCoordinates: string;
  distance: string;
  gpsAccuracy: string;
  faceScore: number;
  livenessScore: number;
  status: 'Needs Review' | 'Approved' | 'Rejected';
};

export type HelpTicket = {
  id: string;
  employee: string;
  employeeAvatar?: string;
  issue: string;
  category: 'Face Recognition' | 'Location Error' | 'GPS' | 'App Error' | 'Other';
  status: 'Open' | 'In Progress' | 'Urgent' | 'Resolved' | 'Rejected';
  description: string;
  deviceTerminal?: string;
  timeLogged?: string;
  attachmentCount?: number;
  activityLog?: ActivityNote[];
};

export type ActivityNote = {
  author: string;
  time: string;
  body: string;
  isSystem?: boolean;
};

export type LocationSite = {
  id: string;
  name: string;
  project: string;
  address: string;
  latitude: number;
  longitude: number;
  radius: number;
  active: boolean;
  assignedEmployees: number;
};

export type Announcement = {
  id: string;
  title: string;
  category: string;
  target: string;
  status: 'Published' | 'Scheduled' | 'Draft';
  pinned: boolean;
  body?: string;
  publishedAt?: string;
};

export type AuditLog = {
  id: string;
  event: string;
  actor: string;
  target?: string;
  timestamp: string;
  details?: string;
};

export type DashboardKPI = {
  label: string;
  value: number | string;
  trend?: string;
  trendUp?: boolean;
  color: 'default' | 'success' | 'warning' | 'error' | 'info';
  icon: string;
};

export type ActivityItem = {
  id: string;
  actor: string;
  action: string;
  context?: string;
  time: string;
  type: 'checkin' | 'late' | 'sync' | 'failed' | 'report' | 'system';
};

export type DepartmentAttendance = {
  department: string;
  percent: number;
  color: string;
};

export type ReportData = {
  day: string;
  present: number;
  absent: number;
  late: number;
};

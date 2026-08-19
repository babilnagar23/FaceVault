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
  project: string;
  location: string;
  shift: string;
  faceStatus: 'Enrolled' | 'Pending' | 'Re-enroll';
  deviceStatus: 'Registered' | 'Revoked' | 'Missing';
  attendancePercent: number;
  status: 'Active' | 'Inactive';
};

export type VerificationCase = {
  id: string;
  employee: string;
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
  issue: string;
  status: 'Open' | 'In Progress' | 'Urgent' | 'Resolved' | 'Rejected';
  description: string;
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


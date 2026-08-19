'use client';

import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { Area, AreaChart, Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { CheckCircle2, CircleAlert, FileDown, MapPinned, Plus, ShieldCheck } from 'lucide-react';
import { AppShell } from './app-shell';
import { Badge, Button, Card, DataTable, EmptyState, ErrorState, Input, Select, Skeleton, StatusChip } from './ui';
import { announcementAdminApi, attendanceAdminApi, employeeApi, helpDeskApi, locationAdminApi, reportApi, settingsApi, verificationApi } from '@/lib/admin-api';
import type { Employee, HelpTicket, LocationSite, VerificationCase } from '@/types/domain';

export function DashboardPage() {
  const report = useQuery({ queryKey: ['dashboard-report'], queryFn: reportApi.dashboard });
  const kpis = [
    ['Total Employees', '502'],
    ['Present', '452'],
    ['Absent', '14'],
    ['Late', '9'],
    ['Pending Review', '12'],
    ['Location Exceptions', '7'],
    ['Open Help Requests', '18'],
    ['Pending Sync', '31']
  ];
  return (
    <AppShell>
      <div className="space-y-6">
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">{kpis.map(([label, value]) => <Card key={label}><p className="text-sm text-on-surface-variant">{label}</p><p className="text-3xl font-bold text-primary">{value}</p></Card>)}</div>
        <div className="grid gap-4 xl:grid-cols-2">
          <Card className="h-80">
            <h2 className="mb-3 font-semibold">Attendance Trend</h2>
            {report.isLoading ? <Skeleton /> : <ResponsiveContainer width="100%" height="85%"><AreaChart data={report.data}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="day" /><YAxis /><Tooltip /><Area dataKey="present" fill="#d2e4ff" stroke="#00355f" /></AreaChart></ResponsiveContainer>}
          </Card>
          <Card className="h-80">
            <h2 className="mb-3 font-semibold">Present vs Absent</h2>
            {report.isLoading ? <Skeleton /> : <ResponsiveContainer width="100%" height="85%"><BarChart data={report.data}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="day" /><YAxis /><Tooltip /><Bar dataKey="absent" fill="#D32F2F" /><Bar dataKey="late" fill="#ED6C02" /></BarChart></ResponsiveContainer>}
          </Card>
        </div>
        <Card>
          <h2 className="mb-3 font-semibold">Quick Actions</h2>
          <div className="flex flex-wrap gap-2"><Button><Plus size={16} /> Add Employee</Button><Button variant="secondary">Create Announcement</Button><Button variant="secondary">Add Location</Button><Button variant="secondary">Review Exceptions</Button><Button variant="secondary">View Help Requests</Button></div>
        </Card>
        <Card><h2 className="mb-3 font-semibold">Recent Activity</h2><div className="grid gap-2 text-sm text-on-surface-variant">{['Employee marked attendance', 'Location assignment changed', 'Help ticket opened', 'Announcement created', 'Attendance exception approved', 'Face enrollment updated'].map((item) => <p key={item}>{item}</p>)}</div></Card>
      </div>
    </AppShell>
  );
}

export function EmployeesPage() {
  const query = useQuery({ queryKey: ['employees'], queryFn: employeeApi.list });
  return (
    <AppShell>
      <SectionHeader title="Employees" action="Add Employee" />
      <div className="mb-4 grid gap-2 md:grid-cols-[1fr_180px_180px]"><Input placeholder="Search employees" /><Select><option>All departments</option></Select><Select><option>All statuses</option></Select></div>
      {query.isLoading && <Skeleton rows={6} />}
      {query.isError && <ErrorState message="Unable to load employees" onRetry={() => query.refetch()} />}
      {query.data && query.data.length === 0 && <EmptyState title="No employees found" message="Try adjusting search or filters." />}
      {query.data && <DataTable<Employee> getKey={(row) => row.id} rows={query.data} columns={[
        { key: 'id', header: 'Employee ID', render: (row) => <Link className="font-semibold text-primary" href={`/employees/${row.id}`}>{row.id}</Link> },
        { key: 'name', header: 'Name', render: (row) => row.name },
        { key: 'department', header: 'Department', render: (row) => row.department },
        { key: 'project', header: 'Project', render: (row) => row.project },
        { key: 'location', header: 'Location', render: (row) => row.location },
        { key: 'shift', header: 'Shift', render: (row) => row.shift },
        { key: 'face', header: 'Face Status', render: (row) => <Badge tone={row.faceStatus === 'Enrolled' ? 'success' : 'warning'}>{row.faceStatus}</Badge> },
        { key: 'device', header: 'Device', render: (row) => row.deviceStatus },
        { key: 'attendance', header: 'Attendance %', render: (row) => `${row.attendancePercent}%` },
        { key: 'status', header: 'Status', render: (row) => <Badge tone="success">{row.status}</Badge> }
      ]} />}
    </AppShell>
  );
}

export function EmployeeProfilePage({ id }: { id: string }) {
  const query = useQuery({ queryKey: ['employee', id], queryFn: () => employeeApi.detail(id) });
  return (
    <AppShell>
      {query.isLoading && <Skeleton rows={5} />}
      {query.data && <div className="space-y-4">
        <SectionHeader title={query.data.name} action="Edit Employee" />
        <div className="grid gap-4 xl:grid-cols-3">
          <Card><h2 className="font-semibold">Profile</h2><p>{query.data.id}</p><p>{query.data.department}</p><p>{query.data.project}</p></Card>
          <Card><h2 className="font-semibold">Face Enrollment</h2><p>Status: {query.data.faceStatus}</p><p>Quality Score: 0.94</p><p>Liveness Score: 0.97</p><p>Model Version: fv-face-v1</p></Card>
          <Card><h2 className="font-semibold">Device</h2><p>{query.data.deviceStatus}</p><Button variant="secondary">Revoke Device</Button></Card>
        </div>
        <Card><h2 className="mb-3 font-semibold">Admin Actions</h2><div className="flex flex-wrap gap-2">{['Assign Project', 'Assign Location', 'Assign Shift', 'Request Face Re-enrollment', 'Deactivate Employee'].map((item) => <Button key={item} variant="secondary">{item}</Button>)}</div></Card>
      </div>}
    </AppShell>
  );
}

export function AttendancePage() {
  const query = useQuery({ queryKey: ['attendance-admin'], queryFn: attendanceAdminApi.list });
  return (
    <AppShell>
      <SectionHeader title="Attendance" action="Export" />
      <Tabs items={['Today', 'History', 'Present', 'Absent', 'Late', 'Location Errors', 'Face Failures', 'Pending Review']} />
      {query.isLoading ? <Skeleton /> : <DataTable rows={query.data ?? []} getKey={(row) => row.id} columns={[
        { key: 'id', header: 'ID', render: (row) => row.id },
        { key: 'employee', header: 'Employee', render: (row) => row.employee },
        { key: 'status', header: 'Status', render: (row) => <StatusChip tone={row.status === 'Present' ? 'success' : row.status === 'Late' ? 'warning' : 'error'}>{row.status}</StatusChip> },
        { key: 'time', header: 'Time', render: (row) => row.time },
        { key: 'site', header: 'Site', render: (row) => row.site }
      ]} />}
    </AppShell>
  );
}

export function VerificationQueuePage() {
  const query = useQuery({ queryKey: ['verification'], queryFn: verificationApi.list });
  return (
    <AppShell>
      <SectionHeader title="Verification Queue" action="Review Exceptions" />
      <MapPreview />
      {query.isLoading ? <Skeleton /> : <DataTable<VerificationCase> rows={query.data ?? []} getKey={(row) => row.id} columns={[
        { key: 'employee', header: 'Employee', render: (row) => <Link className="font-semibold text-primary" href={`/verification-queue/${row.id}`}>{row.employee}</Link> },
        { key: 'scan', header: 'Scan Time', render: (row) => row.scanTime },
        { key: 'site', header: 'Assigned Site', render: (row) => row.assignedSite },
        { key: 'coords', header: 'Current Coordinates', render: (row) => row.currentCoordinates },
        { key: 'distance', header: 'Distance', render: (row) => row.distance },
        { key: 'accuracy', header: 'GPS Accuracy', render: (row) => row.gpsAccuracy },
        { key: 'face', header: 'Face Score', render: (row) => row.faceScore },
        { key: 'live', header: 'Liveness Score', render: (row) => row.livenessScore },
        { key: 'status', header: 'Status', render: (row) => <Badge tone="warning">{row.status}</Badge> }
      ]} />}
    </AppShell>
  );
}

export function VerificationDetailPage({ id }: { id: string }) {
  const query = useQuery({ queryKey: ['verification', id], queryFn: () => verificationApi.detail(id) });
  return (
    <AppShell>
      {query.data && <div className="space-y-4"><SectionHeader title={query.data.employee} action="Approve as Present" /><MapPreview /><Card><p>Assigned Site: {query.data.assignedSite}</p><p>Current Coordinates: {query.data.currentCoordinates}</p><p>Distance: {query.data.distance}</p><p>Face verified and liveness verified; location failed.</p><div className="mt-4 flex flex-wrap gap-2"><Button><CheckCircle2 size={16} /> Approve as Present</Button><Button variant="secondary"><CircleAlert size={16} /> Reject</Button><Button variant="secondary">Request Explanation</Button><Button variant="secondary">Correct Location Assignment</Button><Button variant="secondary">Open Help Ticket</Button></div></Card></div>}
    </AppShell>
  );
}

export function HelpDeskPage() {
  const query = useQuery({ queryKey: ['help-desk'], queryFn: helpDeskApi.list });
  return (
    <AppShell>
      <SectionHeader title="Help Desk" action="Assign" />
      <Tabs items={['All', 'Open', 'In Progress', 'Urgent', 'Resolved', 'Rejected']} />
      {query.isLoading ? <Skeleton /> : <DataTable<HelpTicket> rows={query.data ?? []} getKey={(row) => row.id} columns={[
        { key: 'id', header: 'Ticket', render: (row) => <Link className="font-semibold text-primary" href={`/help-desk/${row.id}`}>{row.id}</Link> },
        { key: 'employee', header: 'Employee', render: (row) => row.employee },
        { key: 'issue', header: 'Issue', render: (row) => row.issue },
        { key: 'status', header: 'Status', render: (row) => <Badge tone={row.status === 'Urgent' ? 'error' : 'warning'}>{row.status}</Badge> },
        { key: 'description', header: 'Description', render: (row) => row.description }
      ]} />}
    </AppShell>
  );
}

export function HelpDeskDetailPage({ id }: { id: string }) {
  const query = useQuery({ queryKey: ['ticket', id], queryFn: () => helpDeskApi.detail(id) });
  return <AppShell>{query.data && <div className="space-y-4"><SectionHeader title={query.data.id} action="Resolve" /><Card><p>Employee: {query.data.employee}</p><p>Issue: {query.data.issue}</p><p>{query.data.description}</p><div className="mt-4 flex flex-wrap gap-2"><Button>Assign</Button><Button variant="secondary">Reply</Button><Button variant="secondary">Escalate</Button><Button variant="secondary">Resolve</Button><Button variant="secondary">Reject</Button></div></Card></div>}</AppShell>;
}

export function LocationsPage() {
  const query = useQuery({ queryKey: ['locations'], queryFn: locationAdminApi.list });
  return <AppShell><SectionHeader title="Locations" action="Add Location" /><MapPreview />{query.isLoading ? <Skeleton /> : <DataTable<LocationSite> rows={query.data ?? []} getKey={(row) => row.id} columns={[
    { key: 'name', header: 'Location Name', render: (row) => row.name },
    { key: 'project', header: 'Project', render: (row) => row.project },
    { key: 'address', header: 'Address', render: (row) => row.address },
    { key: 'lat', header: 'Latitude', render: (row) => row.latitude },
    { key: 'lng', header: 'Longitude', render: (row) => row.longitude },
    { key: 'radius', header: 'Radius', render: (row) => `${row.radius} m` },
    { key: 'active', header: 'Active', render: (row) => <Badge tone={row.active ? 'success' : 'neutral'}>{row.active ? 'Active' : 'Disabled'}</Badge> },
    { key: 'employees', header: 'Assigned', render: (row) => row.assignedEmployees }
  ]} />}</AppShell>;
}

export function AnnouncementsPage() {
  const query = useQuery({ queryKey: ['announcements-admin'], queryFn: announcementAdminApi.list });
  return <AppShell><SectionHeader title="Announcements" action="Create Announcement" />{query.isLoading ? <Skeleton /> : <DataTable rows={query.data ?? []} getKey={(row) => row.id} columns={[
    { key: 'title', header: 'Title', render: (row) => row.title },
    { key: 'target', header: 'Target', render: (row) => row.target },
    { key: 'status', header: 'Status', render: (row) => <Badge tone="success">{row.status}</Badge> },
    { key: 'pinned', header: 'Pinned', render: (row) => row.pinned ? 'Yes' : 'No' }
  ]} />}</AppShell>;
}

export function ReportsPage() {
  return <AppShell><SectionHeader title="Reports" action="Export CSV" /><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{['Attendance Reports', 'Employee Reports', 'Project Reports', 'Location Reports', 'Exception Reports', 'Help Desk Reports', 'Offline Sync Reports'].map((item) => <Card key={item}><FileDown className="mb-3 text-primary" /><h2 className="font-semibold">{item}</h2><p className="text-sm text-on-surface-variant">Filters: Date, Department, Project, Location, Employee, Status. Exports: CSV, Excel, PDF.</p></Card>)}</div></AppShell>;
}

export function AuditLogsPage() {
  return <AppShell><SectionHeader title="Audit Logs" action="Export" /><DataTable rows={[{ id: 'AUD-1', event: 'Location assignment changed', actor: 'Admin', time: '10:42' }, { id: 'AUD-2', event: 'Attendance exception approved', actor: 'HR', time: '11:05' }]} getKey={(row) => row.id} columns={[
    { key: 'id', header: 'ID', render: (row) => row.id },
    { key: 'event', header: 'Event', render: (row) => row.event },
    { key: 'actor', header: 'Actor', render: (row) => row.actor },
    { key: 'time', header: 'Time', render: (row) => row.time }
  ]} /></AppShell>;
}

export function SettingsPage({ section }: { section?: string }) {
  const query = useQuery({ queryKey: ['settings'], queryFn: settingsApi.sections });
  const active = section ?? 'attendance';
  return <AppShell><SectionHeader title="Settings" action="Save Changes" /><Tabs items={query.data ?? ['Attendance', 'Biometrics', 'Offline', 'Organisation', 'Notifications', 'Roles']} /><div className="grid gap-4 lg:grid-cols-2">
    <SettingCard title="Attendance" active={active.includes('attendance')} items={['Check-in Window', 'Grace Period', 'Default GeoFence Radius', 'Late Rules', 'Check-out Rules']} />
    <SettingCard title="Biometrics" active={active.includes('biometric')} items={['Face Match Threshold', 'Liveness Threshold', 'Minimum Face Quality', 'Re-enrollment Policy']} />
    <SettingCard title="Offline" active={active.includes('offline')} items={['Offline Attendance Enabled', 'Sync Retry Count', 'Maximum Queue Size', 'Background Sync']} />
    <SettingCard title="Organisation" active={active.includes('organisation')} items={['Name', 'Logo', 'Timezone', 'Contact']} />
    <SettingCard title="Notifications" active={active.includes('notifications')} items={['Push', 'Email', 'System Alerts', 'Attendance Reminders']} />
    <SettingCard title="Roles" active={active.includes('roles')} items={['Owner', 'Admin', 'HR', 'Manager', 'Supervisor']} />
  </div></AppShell>;
}

function SettingCard({ title, items, active }: { title: string; items: string[]; active?: boolean }) {
  return <Card className={active ? 'ring-2 ring-secondary' : ''}><h2 className="mb-3 font-semibold">{title}</h2><div className="grid gap-3">{items.map((item) => <label key={item} className="grid gap-1 text-sm font-medium">{item}<Input defaultValue={item.includes('Threshold') ? '0.92' : item.includes('Radius') ? '150 m' : 'Enabled'} /></label>)}</div></Card>;
}

function SectionHeader({ title, action }: { title: string; action: string }) {
  return <div className="mb-4 flex flex-col justify-between gap-3 md:flex-row md:items-center"><div><h1 className="text-2xl font-semibold">{title}</h1><p className="text-sm text-on-surface-variant">Showing cached mock data through typed API interfaces.</p></div><Button><Plus size={16} /> {action}</Button></div>;
}

function Tabs({ items }: { items: string[] }) {
  return <div className="mb-4 flex gap-2 overflow-x-auto">{items.map((item, index) => <button key={item} className={`whitespace-nowrap rounded-full px-3 py-1.5 text-sm font-semibold ${index === 0 ? 'bg-primary text-white' : 'bg-white text-on-surface-variant'}`}>{item}</button>)}</div>;
}

function MapPreview() {
  return <Card className="mb-4 h-64 overflow-hidden"><div className="relative h-full rounded-lg bg-[linear-gradient(135deg,#d2e4ff,#f7f9fc)]"><div className="absolute left-1/2 top-1/2 h-36 w-36 -translate-x-1/2 -translate-y-1/2 rounded-full border-4 border-secondary/40 bg-blue-100/30" /><div className="absolute left-[52%] top-[46%] flex items-center gap-2 rounded-full bg-white px-3 py-2 text-sm font-semibold shadow-card"><MapPinned size={16} className="text-primary" /> Geofence Circle</div></div></Card>;
}


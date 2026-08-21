'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Pie, PieChart,
  ResponsiveContainer, Tooltip, XAxis, YAxis
} from 'recharts';
import {
  AlertCircle, ArrowUpRight, CalendarCheck, CheckCircle2, CircleAlert,
  Clock, FileDown, HelpCircle, MapPinned, Plus, ShieldCheck, TrendingUp, Users
} from 'lucide-react';
import { AppShell } from './app-shell';
import {
  Badge, Button, Card, ConfirmDialog, DataTable, EmptyState, ErrorState,
  FormField, Input, Modal, Select, Skeleton, StatusChip, Textarea, useToast
} from './ui';
import {
  announcementAdminApi, attendanceAdminApi, auditApi, dashboardApi,
  employeeApi, helpDeskApi, locationAdminApi, reportApi, settingsApi, verificationApi
} from '@/lib/admin-api';
import { announcementSchema, employeeSchema, locationSchema, type AnnouncementFormInput, type EmployeeFormInput, type LocationFormInput } from '@/validators/forms';
import type { Employee, HelpTicket, LocationSite, VerificationCase } from '@/types/domain';
import { useState } from 'react';

// ─────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────

export function DashboardPage() {
  const report = useQuery({ queryKey: ['dashboard-report'], queryFn: reportApi.dashboard });
  const kpisQuery = useQuery({ queryKey: ['dashboard-kpis'], queryFn: dashboardApi.kpis });
  const activityQuery = useQuery({ queryKey: ['dashboard-activity'], queryFn: dashboardApi.recentActivity });

  const kpiCards = kpisQuery.data
    ? [
        { label: 'Total Employees', value: kpisQuery.data.totalEmployees, trend: null, color: 'text-primary', icon: Users },
        { label: 'Present Today', value: kpisQuery.data.presentToday, trend: kpisQuery.data.presentTrend, color: 'text-success', icon: CheckCircle2 },
        { label: 'Absent Today', value: kpisQuery.data.absentToday, trend: null, color: 'text-error', icon: CircleAlert },
        { label: 'Late Arrivals', value: kpisQuery.data.late, trend: null, color: 'text-warning', icon: Clock },
        { label: 'Pending Verification', value: kpisQuery.data.pendingVerification, trend: null, color: 'text-secondary', icon: ShieldCheck },
        { label: 'Active Locations', value: kpisQuery.data.activeLocations, trend: null, color: 'text-on-surface', icon: MapPinned },
      ]
    : [];

  const activityTypeStyle = (type: string) => {
    return {
      checkin: { icon: CheckCircle2, color: 'text-success', bg: 'bg-green-50' },
      late: { icon: Clock, color: 'text-warning', bg: 'bg-orange-50' },
      sync: { icon: TrendingUp, color: 'text-secondary', bg: 'bg-blue-50' },
      failed: { icon: AlertCircle, color: 'text-error', bg: 'bg-red-50' },
      report: { icon: FileDown, color: 'text-on-surface-variant', bg: 'bg-surface-container' },
      system: { icon: CalendarCheck, color: 'text-on-surface-variant', bg: 'bg-surface-container' },
    }[type] ?? { icon: CalendarCheck, color: 'text-on-surface-variant', bg: 'bg-surface-container' };
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* KPI Grid */}
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {kpisQuery.isLoading
            ? Array.from({ length: 6 }).map((_, i) => (
                <Card key={i}><div className="h-16 animate-pulse rounded bg-surface-container" /></Card>
              ))
            : kpiCards.map(({ label, value, trend, color, icon: Icon }) => (
                <Card key={label}>
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="text-sm text-on-surface-variant">{label}</p>
                      <p className={`mt-1 text-3xl font-bold ${color}`}>{value.toLocaleString()}</p>
                      {trend && (
                        <p className="mt-1 flex items-center gap-1 text-xs font-semibold text-success">
                          <ArrowUpRight size={12} />{trend}
                        </p>
                      )}
                    </div>
                    <div className="rounded-lg bg-surface-container-low p-2">
                      <Icon size={20} className="text-on-surface-variant" />
                    </div>
                  </div>
                </Card>
              ))}
        </div>

        {/* Charts */}
        <div className="grid gap-4 xl:grid-cols-2">
          <Card className="h-80">
            <h2 className="mb-3 font-semibold">Attendance Trend — This Week</h2>
            {report.isLoading ? (
              <Skeleton rows={4} />
            ) : (
              <ResponsiveContainer width="100%" height="85%">
                <AreaChart data={report.data}>
                  <defs>
                    <linearGradient id="presentGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#0F4C81" stopOpacity={0.18} />
                      <stop offset="95%" stopColor="#0F4C81" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E0E5EB" />
                  <XAxis dataKey="day" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Area dataKey="present" fill="url(#presentGrad)" stroke="#00355f" strokeWidth={2} name="Present" />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </Card>
          <Card className="h-80">
            <h2 className="mb-3 font-semibold">Absent & Late</h2>
            {report.isLoading ? (
              <Skeleton rows={4} />
            ) : (
              <ResponsiveContainer width="100%" height="85%">
                <BarChart data={report.data}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E0E5EB" />
                  <XAxis dataKey="day" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Bar dataKey="absent" fill="#D32F2F" name="Absent" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="late" fill="#ED6C02" name="Late" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </Card>
        </div>

        {/* Quick Actions */}
        <Card>
          <h2 className="mb-3 font-semibold">Quick Actions</h2>
          <div className="flex flex-wrap gap-2">
            <Link href="/employees"><Button><Plus size={16} /> Add Employee</Button></Link>
            <Link href="/announcements/create"><Button variant="secondary">Create Announcement</Button></Link>
            <Link href="/locations/create"><Button variant="secondary">Add Location</Button></Link>
            <Link href="/verification-queue"><Button variant="secondary">Review Exceptions</Button></Link>
            <Link href="/help-desk"><Button variant="secondary">View Help Requests</Button></Link>
          </div>
        </Card>

        {/* Recent Activity */}
        <Card>
          <h2 className="mb-4 font-semibold">Recent Activity</h2>
          {activityQuery.isLoading ? (
            <Skeleton rows={4} />
          ) : (
            <div className="space-y-3">
              {(activityQuery.data ?? []).map((item) => {
                const { icon: Icon, color, bg } = activityTypeStyle(item.type);
                return (
                  <div key={item.id} className="flex items-start gap-3">
                    <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${bg}`}>
                      <Icon size={14} className={color} />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm">
                        <span className="font-semibold text-on-surface">{item.actor}</span>{' '}
                        <span className="text-on-surface-variant">{item.action}</span>
                      </p>
                      {item.context && <p className="text-xs text-on-surface-variant">{item.context}</p>}
                    </div>
                    <p className="shrink-0 text-xs text-on-surface-variant">{item.time}</p>
                  </div>
                );
              })}
            </div>
          )}
        </Card>
      </div>
    </AppShell>
  );
}

// ─────────────────────────────────────────
// EMPLOYEES PAGE
// ─────────────────────────────────────────

export function EmployeesPage() {
  const [search, setSearch] = useState('');
  const [dept, setDept] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const { showToast } = useToast();
  const queryClient = useQueryClient();

  const query = useQuery({ queryKey: ['employees'], queryFn: employeeApi.list });

  const filteredEmployees = (query.data ?? []).filter(
    (e) =>
      (!search || e.name.toLowerCase().includes(search.toLowerCase()) || e.id.includes(search)) &&
      (!dept || e.department === dept)
  );

  const departments = Array.from(new Set((query.data ?? []).map((e) => e.department)));

  const { register, handleSubmit, formState, reset } = useForm<EmployeeFormInput>({
    resolver: zodResolver(employeeSchema),
  });

  async function onAddEmployee(data: EmployeeFormInput) {
    await new Promise((resolve) => setTimeout(resolve, 600));
    await queryClient.invalidateQueries({ queryKey: ['employees'] });
    setShowAddModal(false);
    reset();
    showToast(`Employee ${data.name} added successfully.`);
  }

  return (
    <AppShell>
      <SectionHeader
        title="Employees"
        subtitle={`${filteredEmployees.length} employees`}
        action={<Button onClick={() => setShowAddModal(true)}><Plus size={16} /> Add Employee</Button>}
      />
      <div className="mb-4 grid gap-2 md:grid-cols-[1fr_200px_160px]">
        <Input placeholder="Search by name or ID..." value={search} onChange={(e) => setSearch(e.target.value)} />
        <Select value={dept} onChange={(e) => setDept(e.target.value)}>
          <option value="">All departments</option>
          {departments.map((d) => <option key={d} value={d}>{d}</option>)}
        </Select>
        <Select>
          <option>All statuses</option>
          <option>Active</option>
          <option>Inactive</option>
        </Select>
      </div>

      {query.isLoading && <Skeleton rows={6} />}
      {query.isError && <ErrorState message="Unable to load employees" onRetry={() => query.refetch()} />}
      {query.data && filteredEmployees.length === 0 && (
        <EmptyState title="No employees found" message="Try adjusting your search or filters." />
      )}
      {query.data && filteredEmployees.length > 0 && (
        <DataTable<Employee>
          getKey={(row) => row.id}
          rows={filteredEmployees}
          columns={[
            { key: 'id', header: 'Employee ID', render: (row) => <Link className="font-semibold text-primary hover:underline" href={`/employees/${row.id}`}>{row.id}</Link> },
            { key: 'name', header: 'Name', render: (row) => <span className="font-medium">{row.name}</span> },
            { key: 'department', header: 'Department', render: (row) => row.department },
            { key: 'project', header: 'Project', render: (row) => row.project },
            { key: 'location', header: 'Location', render: (row) => row.location },
            { key: 'shift', header: 'Shift', render: (row) => row.shift },
            { key: 'face', header: 'Face', render: (row) => <Badge tone={row.faceStatus === 'Enrolled' ? 'success' : row.faceStatus === 'Re-enroll' ? 'error' : 'warning'}>{row.faceStatus}</Badge> },
            { key: 'device', header: 'Device', render: (row) => <Badge tone={row.deviceStatus === 'Registered' ? 'success' : 'error'}>{row.deviceStatus}</Badge> },
            { key: 'attendance', header: 'Attendance %', render: (row) => <span className={row.attendancePercent < 85 ? 'font-bold text-warning' : 'text-on-surface'}>{row.attendancePercent}%</span> },
            { key: 'status', header: 'Status', render: (row) => <Badge tone="success">{row.status}</Badge> },
          ]}
        />
      )}

      {/* Add Employee Modal */}
      <Modal open={showAddModal} onClose={() => setShowAddModal(false)} title="Add Employee"
        footer={
          <>
            <Button variant="secondary" onClick={() => setShowAddModal(false)}>Cancel</Button>
            <Button onClick={handleSubmit(onAddEmployee)} disabled={formState.isSubmitting}>
              {formState.isSubmitting ? 'Saving...' : 'Add Employee'}
            </Button>
          </>
        }
      >
        <form className="grid gap-4">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Full Name" error={formState.errors.name?.message}>
              <Input {...register('name')} placeholder="Aarav Mehta" />
            </FormField>
            <FormField label="Email" error={formState.errors.email?.message}>
              <Input type="email" {...register('email')} placeholder="aarav@company.com" />
            </FormField>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Department" error={formState.errors.department?.message}>
              <Select {...register('department')}>
                <option value="">Select department</option>
                {['Operations', 'Engineering', 'Safety', 'Logistics', 'HR', 'Finance'].map((d) => <option key={d} value={d}>{d}</option>)}
              </Select>
            </FormField>
            <FormField label="Role" error={formState.errors.role?.message}>
              <Input {...register('role')} placeholder="Site Supervisor" />
            </FormField>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Project" error={formState.errors.project?.message}>
              <Input {...register('project')} placeholder="Metro Expansion" />
            </FormField>
            <FormField label="Location" error={formState.errors.location?.message}>
              <Input {...register('location')} placeholder="Sector 17" />
            </FormField>
          </div>
          <FormField label="Shift" error={formState.errors.shift?.message}>
            <Select {...register('shift')}>
              <option value="">Select shift</option>
              {['07:00 - 16:00', '08:00 - 17:00', '09:00 - 18:00', '10:00 - 19:00', '22:00 - 06:00'].map((s) => <option key={s} value={s}>{s}</option>)}
            </Select>
          </FormField>
        </form>
      </Modal>
    </AppShell>
  );
}

// ─────────────────────────────────────────
// EMPLOYEE PROFILE PAGE
// ─────────────────────────────────────────

export function EmployeeProfilePage({ id }: { id: string }) {
  const query = useQuery({ queryKey: ['employee', id], queryFn: () => employeeApi.detail(id) });
  const { showToast } = useToast();
  const [confirmDeactivate, setConfirmDeactivate] = useState(false);
  const [confirmRevokeDevice, setConfirmRevokeDevice] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<'overview' | 'biometric' | 'device'>('overview');

  async function handleDeactivate() {
    setActionLoading(true);
    await new Promise((r) => setTimeout(r, 800));
    setActionLoading(false);
    setConfirmDeactivate(false);
    showToast('Employee deactivated and audit event recorded.', 'warning');
  }

  async function handleRevokeDevice() {
    setActionLoading(true);
    await new Promise((r) => setTimeout(r, 600));
    setActionLoading(false);
    setConfirmRevokeDevice(false);
    showToast('Device registration revoked.', 'warning');
  }

  return (
    <AppShell>
      {query.isLoading && <Skeleton rows={6} />}
      {query.isError && <ErrorState message="Unable to load employee" onRetry={() => query.refetch()} />}
      {query.data && (
        <div className="space-y-5">
          {/* Header */}
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-4">
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-primary text-xl font-bold text-white">
                {query.data.name.split(' ').map((n) => n[0]).join('').slice(0, 2)}
              </div>
              <div>
                <h1 className="text-2xl font-semibold">{query.data.name}</h1>
                <p className="text-sm text-on-surface-variant">{query.data.id} · {query.data.role} · {query.data.department}</p>
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              <Button variant="secondary" onClick={() => showToast('Assignment updated.', 'info')}>Assign Project</Button>
              <Button variant="secondary" onClick={() => showToast('Location updated.', 'info')}>Assign Location</Button>
              <Button variant="secondary" onClick={() => showToast('Re-enrollment request sent.', 'info')}>Request Re-enrollment</Button>
              <Button variant="danger" onClick={() => setConfirmDeactivate(true)}>Deactivate</Button>
            </div>
          </div>

          {/* Tabs */}
          <div className="flex gap-2 border-b border-border-subtle">
            {(['overview', 'biometric', 'device'] as const).map((tab) => (
              <button key={tab} onClick={() => setActiveTab(tab)}
                className={`border-b-2 px-4 py-2 text-sm font-semibold capitalize transition ${
                  activeTab === tab ? 'border-primary text-primary' : 'border-transparent text-on-surface-variant hover:text-on-surface'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>

          {activeTab === 'overview' && (
            <div className="grid gap-4 xl:grid-cols-3">
              <Card>
                <h2 className="mb-3 font-semibold">Assignment</h2>
                <div className="space-y-2 text-sm">
                  <Row label="Project" value={query.data.project} />
                  <Row label="Location" value={query.data.location} />
                  <Row label="Shift" value={query.data.shift} />
                  <Row label="Manager" value={query.data.manager ?? '—'} />
                  <Row label="Join Date" value={query.data.joinDate ?? '—'} />
                </div>
              </Card>
              <Card>
                <h2 className="mb-3 font-semibold">Attendance</h2>
                <div className="space-y-2 text-sm">
                  <Row label="This Month" value={`${query.data.attendancePercent}%`} />
                  <Row label="Status" value={query.data.status} />
                </div>
              </Card>
              <Card>
                <h2 className="mb-3 font-semibold">Status</h2>
                <div className="space-y-2">
                  <Badge tone={query.data.faceStatus === 'Enrolled' ? 'success' : 'warning'}>Face: {query.data.faceStatus}</Badge>
                  <br /><Badge tone={query.data.deviceStatus === 'Registered' ? 'success' : 'error'}>Device: {query.data.deviceStatus}</Badge>
                  <br /><Badge tone="success">{query.data.status}</Badge>
                </div>
              </Card>
            </div>
          )}

          {activeTab === 'biometric' && (
            <Card>
              <h2 className="mb-4 font-semibold">Biometric Enrollment</h2>
              <div className="space-y-3 text-sm">
                <Row label="Enrollment Status" value={query.data.faceStatus} />
                <Row label="Quality Score" value="0.94" />
                <Row label="Liveness Score" value="0.97" />
                <Row label="Model Version" value="fv-face-v1" />
                <Row label="Enrolled On" value="2024-03-01" />
              </div>
              <div className="mt-4 flex gap-2">
                <Button variant="secondary" onClick={() => showToast('Re-enrollment request sent to employee device.', 'info')}>
                  Request Re-enrollment
                </Button>
                <Button variant="secondary" onClick={() => showToast('Biometric template disabled.', 'warning')}>
                  Disable Template
                </Button>
              </div>
              <p className="mt-3 text-xs text-on-surface-variant">
                ⚠ Biometric vectors are never displayed. Only aggregate quality and status metrics are shown.
              </p>
            </Card>
          )}

          {activeTab === 'device' && (
            <Card>
              <h2 className="mb-4 font-semibold">Registered Device</h2>
              <div className="space-y-3 text-sm">
                <Row label="Status" value={query.data.deviceStatus} />
                <Row label="Model" value="Pixel 8 (Android 15)" />
                <Row label="App Version" value="1.0.0" />
                <Row label="Registered On" value={query.data.joinDate ?? '2024-03-01'} />
              </div>
              <div className="mt-4">
                <Button variant="danger" onClick={() => setConfirmRevokeDevice(true)}>Revoke Device</Button>
              </div>
            </Card>
          )}
        </div>
      )}

      <ConfirmDialog
        open={confirmDeactivate}
        onClose={() => setConfirmDeactivate(false)}
        onConfirm={handleDeactivate}
        title="Deactivate Employee"
        description={`Are you sure you want to deactivate ${query.data?.name ?? 'this employee'}? Their device access and biometric will be suspended. This action is logged in the audit trail.`}
        confirmLabel="Deactivate"
        danger
        loading={actionLoading}
      />
      <ConfirmDialog
        open={confirmRevokeDevice}
        onClose={() => setConfirmRevokeDevice(false)}
        onConfirm={handleRevokeDevice}
        title="Revoke Device Registration"
        description="Revoking the device will require the employee to re-register before they can use FaceVault on any device. This action is logged."
        confirmLabel="Revoke"
        danger
        loading={actionLoading}
      />
    </AppShell>
  );
}

// ─────────────────────────────────────────
// ATTENDANCE PAGE
// ─────────────────────────────────────────

export function AttendancePage() {
  const query = useQuery({ queryKey: ['attendance-admin'], queryFn: attendanceAdminApi.list });
  const [activeTab, setActiveTab] = useState('Today');
  const tabs = ['Today', 'Present', 'Absent', 'Late', 'Location Errors', 'Face Failures', 'Pending Review'];

  return (
    <AppShell>
      <SectionHeader title="Attendance" subtitle="Real-time attendance overview"
        action={<Button variant="secondary"><FileDown size={16} /> Export</Button>}
      />
      <Tabs items={tabs} active={activeTab} onSelect={setActiveTab} />
      {query.isLoading ? <Skeleton /> : (
        <DataTable
          rows={query.data ?? []}
          getKey={(row) => row.id}
          columns={[
            { key: 'id', header: 'ID', render: (row) => <span className="text-xs text-on-surface-variant">{row.id}</span> },
            { key: 'employee', header: 'Employee', render: (row) => <span className="font-semibold">{row.employee}</span> },
            { key: 'status', header: 'Status', render: (row) => (
              <StatusChip tone={row.status === 'Present' ? 'success' : row.status === 'Late' ? 'warning' : row.status === 'Absent' ? 'error' : 'info'}>
                {row.status}
              </StatusChip>
            )},
            { key: 'time', header: 'Time', render: (row) => row.time },
            { key: 'site', header: 'Site', render: (row) => row.site },
            { key: 'faceScore', header: 'Face', render: (row) => row.faceScore ? <span className="text-xs">{row.faceScore}%</span> : '—' },
            { key: 'gpsAccuracy', header: 'GPS Accuracy', render: (row) => row.gpsAccuracy ?? '—' },
          ]}
        />
      )}
    </AppShell>
  );
}

// ─────────────────────────────────────────
// VERIFICATION QUEUE
// ─────────────────────────────────────────

export function VerificationQueuePage() {
  const query = useQuery({ queryKey: ['verification'], queryFn: verificationApi.list });

  return (
    <AppShell>
      <SectionHeader
        title="Verification Queue"
        subtitle="Attendance attempts with face/liveness verified but location outside geofence."
      />
      <MapPreview />
      {query.isLoading ? <Skeleton /> : (
        <DataTable<VerificationCase>
          rows={query.data ?? []}
          getKey={(row) => row.id}
          columns={[
            { key: 'employee', header: 'Employee', render: (row) => <Link className="font-semibold text-primary hover:underline" href={`/verification-queue/${row.id}`}>{row.employee}</Link> },
            { key: 'scan', header: 'Scan Time', render: (row) => row.scanTime },
            { key: 'site', header: 'Assigned Site', render: (row) => row.assignedSite },
            { key: 'coords', header: 'Coordinates', render: (row) => <span className="text-xs font-mono">{row.currentCoordinates}</span> },
            { key: 'distance', header: 'Distance', render: (row) => <span className="font-semibold text-warning">{row.distance}</span> },
            { key: 'accuracy', header: 'GPS Acc.', render: (row) => row.gpsAccuracy },
            { key: 'face', header: 'Face', render: (row) => <Badge tone="success">{(row.faceScore * 100).toFixed(1)}%</Badge> },
            { key: 'live', header: 'Liveness', render: (row) => <Badge tone="success">{(row.livenessScore * 100).toFixed(1)}%</Badge> },
            { key: 'status', header: 'Status', render: (row) => <Badge tone="warning">{row.status}</Badge> },
          ]}
        />
      )}
    </AppShell>
  );
}

// ─────────────────────────────────────────
// VERIFICATION DETAIL
// ─────────────────────────────────────────

export function VerificationDetailPage({ id }: { id: string }) {
  const query = useQuery({ queryKey: ['verification', id], queryFn: () => verificationApi.detail(id) });
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [confirm, setConfirm] = useState<'approve' | 'reject' | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleDecision(decision: 'approve' | 'reject') {
    setLoading(true);
    await verificationApi.decide(id, decision);
    await queryClient.invalidateQueries({ queryKey: ['verification'] });
    setLoading(false);
    setConfirm(null);
    showToast(
      decision === 'approve' ? 'Attendance approved as Present. Audit event recorded.' : 'Attendance rejected. Employee notified.',
      decision === 'approve' ? 'success' : 'warning'
    );
  }

  return (
    <AppShell>
      {query.isLoading && <Skeleton rows={5} />}
      {query.isError && <ErrorState message="Unable to load verification case" onRetry={() => query.refetch()} />}
      {query.data && (
        <div className="space-y-4">
          <SectionHeader title={query.data.employee} subtitle={`${query.data.employeeRole ?? ''} · ${query.data.employeeDept ?? ''}`} />
          <MapPreview />
          <div className="grid gap-4 xl:grid-cols-2">
            <Card>
              <h2 className="mb-3 font-semibold">Location Details</h2>
              <div className="space-y-2 text-sm">
                <Row label="Assigned Site" value={query.data.assignedSite} />
                <Row label="Current Coordinates" value={query.data.currentCoordinates} mono />
                <Row label="Distance" value={<span className="font-bold text-warning">{query.data.distance}</span>} />
                <Row label="GPS Accuracy" value={query.data.gpsAccuracy} />
                <Row label="Scan Time" value={query.data.scanTime} />
              </div>
            </Card>
            <Card>
              <h2 className="mb-3 font-semibold">AI Verification Results</h2>
              <div className="space-y-2 text-sm">
                <Row label="Face Score" value={<Badge tone="success">{(query.data.faceScore * 100).toFixed(1)}% — Verified</Badge>} />
                <Row label="Liveness Score" value={<Badge tone="success">{(query.data.livenessScore * 100).toFixed(1)}% — Verified</Badge>} />
                <Row label="Location" value={<Badge tone="error">Outside Geofence</Badge>} />
                <Row label="Overall Status" value={<Badge tone="warning">{query.data.status}</Badge>} />
              </div>
            </Card>
          </div>
          <Card>
            <h2 className="mb-4 font-semibold">Admin Decision</h2>
            <p className="mb-4 text-sm text-on-surface-variant">
              Face and liveness are verified. The employee was {query.data.distance} from their assigned site at scan time. Review the coordinates and context before making a decision. This decision is recorded in the audit log.
            </p>
            <div className="flex flex-wrap gap-2">
              <Button onClick={() => setConfirm('approve')}><CheckCircle2 size={16} /> Approve as Present</Button>
              <Button variant="secondary" onClick={() => setConfirm('reject')}><CircleAlert size={16} /> Reject</Button>
              <Button variant="secondary" onClick={() => showToast('Explanation request sent to employee.', 'info')}>Request Explanation</Button>
              <Button variant="secondary" onClick={() => showToast('Location correction workflow opened.', 'info')}>Correct Location Assignment</Button>
              <Button variant="secondary" onClick={() => showToast('Help ticket opened for this case.', 'info')}>Open Help Ticket</Button>
            </div>
          </Card>
        </div>
      )}

      <ConfirmDialog
        open={confirm === 'approve'}
        onClose={() => setConfirm(null)}
        onConfirm={() => handleDecision('approve')}
        title="Approve as Present"
        description={`Approving this attendance attempt will record ${query.data?.employee ?? 'the employee'} as Present despite the location mismatch. This overrides the geofence and is logged in the audit trail.`}
        confirmLabel="Approve as Present"
        loading={loading}
      />
      <ConfirmDialog
        open={confirm === 'reject'}
        onClose={() => setConfirm(null)}
        onConfirm={() => handleDecision('reject')}
        title="Reject Attendance"
        description="Rejecting this attempt will mark the attendance as Location Not Verified. The employee can raise a help request. This is logged in the audit trail."
        confirmLabel="Reject"
        danger
        loading={loading}
      />
    </AppShell>
  );
}

// ─────────────────────────────────────────
// HELP DESK PAGE
// ─────────────────────────────────────────

export function HelpDeskPage() {
  const query = useQuery({ queryKey: ['help-desk'], queryFn: helpDeskApi.list });
  const [activeTab, setActiveTab] = useState('All');

  return (
    <AppShell>
      <SectionHeader title="Help Desk" subtitle="Employee support requests and system issues" />
      <Tabs items={['All', 'Open', 'In Progress', 'Urgent', 'Resolved', 'Rejected']} active={activeTab} onSelect={setActiveTab} />
      {query.isLoading ? <Skeleton /> : (
        <DataTable<HelpTicket>
          rows={query.data ?? []}
          getKey={(row) => row.id}
          columns={[
            { key: 'id', header: 'Ticket', render: (row) => <Link className="font-semibold text-primary hover:underline" href={`/help-desk/${row.id}`}>{row.id}</Link> },
            { key: 'employee', header: 'Employee', render: (row) => row.employee },
            { key: 'issue', header: 'Issue', render: (row) => <span className="font-medium">{row.issue}</span> },
            { key: 'category', header: 'Category', render: (row) => row.category },
            { key: 'status', header: 'Status', render: (row) => <Badge tone={row.status === 'Urgent' ? 'error' : row.status === 'Open' ? 'warning' : row.status === 'Resolved' ? 'success' : 'neutral'}>{row.status}</Badge> },
            { key: 'time', header: 'Logged', render: (row) => <span className="text-xs text-on-surface-variant">{row.timeLogged}</span> },
          ]}
        />
      )}
    </AppShell>
  );
}

// ─────────────────────────────────────────
// HELP DESK DETAIL PAGE
// ─────────────────────────────────────────

export function HelpDeskDetailPage({ id }: { id: string }) {
  const query = useQuery({ queryKey: ['ticket', id], queryFn: () => helpDeskApi.detail(id) });
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [confirmResolve, setConfirmResolve] = useState(false);
  const [loading, setLoading] = useState(false);
  const [reply, setReply] = useState('');

  async function handleResolve() {
    setLoading(true);
    await helpDeskApi.resolve(id);
    await queryClient.invalidateQueries({ queryKey: ['ticket', id] });
    await queryClient.invalidateQueries({ queryKey: ['help-desk'] });
    setLoading(false);
    setConfirmResolve(false);
    showToast('Ticket resolved successfully.');
  }

  async function handleReply() {
    if (!reply.trim()) return;
    await helpDeskApi.postNote(id, reply);
    setReply('');
    showToast('Reply posted.');
  }

  return (
    <AppShell>
      {query.isLoading && <Skeleton rows={5} />}
      {query.data && (
        <div className="space-y-4">
          <SectionHeader
            title={query.data.id}
            subtitle={`${query.data.category} · ${query.data.status}`}
            action={
              <div className="flex gap-2">
                <Button variant="secondary" onClick={() => showToast('Ticket escalated to senior support.', 'warning')}>Escalate</Button>
                <Button onClick={() => setConfirmResolve(true)}><CheckCircle2 size={16} /> Resolve</Button>
              </div>
            }
          />

          <div className="grid gap-4 xl:grid-cols-3">
            <div className="space-y-4 xl:col-span-2">
              <Card>
                <h2 className="mb-2 font-semibold">Issue Description</h2>
                <p className="text-sm leading-relaxed text-on-surface-variant">{query.data.description}</p>
                {query.data.deviceTerminal && (
                  <p className="mt-2 text-xs text-on-surface-variant">Terminal: <span className="font-mono">{query.data.deviceTerminal}</span></p>
                )}
              </Card>
              <Card>
                <h2 className="mb-3 font-semibold">Activity Log</h2>
                <div className="space-y-3">
                  {(query.data.activityLog ?? []).map((entry, i) => (
                    <div key={i} className={`rounded-lg p-3 text-sm ${entry.isSystem ? 'bg-surface-container-low' : 'bg-blue-50'}`}>
                      <div className="mb-1 flex items-center justify-between">
                        <span className="font-semibold">{entry.author}</span>
                        <span className="text-xs text-on-surface-variant">{entry.time}</span>
                      </div>
                      <p className="text-on-surface-variant">{entry.body}</p>
                    </div>
                  ))}
                </div>
                <div className="mt-4 flex gap-2">
                  <Textarea
                    value={reply}
                    onChange={(e) => setReply(e.target.value)}
                    placeholder="Add a reply or note..."
                    rows={2}
                  />
                  <Button onClick={handleReply} className="shrink-0">Post</Button>
                </div>
              </Card>
            </div>

            <div className="space-y-4">
              <Card>
                <h2 className="mb-3 font-semibold">Ticket Info</h2>
                <div className="space-y-2 text-sm">
                  <Row label="Employee" value={query.data.employee} />
                  <Row label="Category" value={query.data.category} />
                  <Row label="Status" value={<Badge tone={query.data.status === 'Open' ? 'warning' : 'success'}>{query.data.status}</Badge>} />
                  <Row label="Logged" value={query.data.timeLogged ?? '—'} />
                  <Row label="Attachments" value={`${query.data.attachmentCount ?? 0} file(s)`} />
                </div>
              </Card>
              <Card>
                <h2 className="mb-3 font-semibold">Actions</h2>
                <div className="grid gap-2">
                  <Button variant="secondary" onClick={() => showToast('Ticket assigned to support team.', 'info')}>Assign</Button>
                  <Button variant="secondary" onClick={() => showToast('Ticket escalated.', 'warning')}>Escalate</Button>
                  <Button variant="danger" onClick={() => showToast('Ticket rejected.', 'error')}>Reject</Button>
                </div>
              </Card>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmResolve}
        onClose={() => setConfirmResolve(false)}
        onConfirm={handleResolve}
        title="Resolve Ticket"
        description="Mark this ticket as resolved? The employee will be notified and the ticket will be closed."
        confirmLabel="Resolve Ticket"
        loading={loading}
      />
    </AppShell>
  );
}

// ─────────────────────────────────────────
// LOCATIONS PAGE
// ─────────────────────────────────────────

export function LocationsPage() {
  const query = useQuery({ queryKey: ['locations'], queryFn: locationAdminApi.list });
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [showAddModal, setShowAddModal] = useState(false);

  const { register, handleSubmit, formState, reset } = useForm<LocationFormInput>({
    resolver: zodResolver(locationSchema),
    defaultValues: { active: true },
  });

  async function onAddLocation(data: LocationFormInput) {
    await locationAdminApi.create({
      name: data.name,
      project: data.project,
      address: data.address,
      latitude: Number(data.latitude),
      longitude: Number(data.longitude),
      radius: Number(data.radius),
      active: data.active,
    });
    await queryClient.invalidateQueries({ queryKey: ['locations'] });
    setShowAddModal(false);
    reset();
    showToast(`Location "${data.name}" created successfully.`);
  }

  return (
    <AppShell>
      <SectionHeader title="Locations" subtitle="Work sites and geofence configurations"
        action={<Button onClick={() => setShowAddModal(true)}><Plus size={16} /> Add Location</Button>}
      />
      <MapPreview />
      {query.isLoading ? <Skeleton /> : (
        <DataTable<LocationSite>
          rows={query.data ?? []}
          getKey={(row) => row.id}
          columns={[
            { key: 'name', header: 'Location', render: (row) => <Link className="font-semibold text-primary hover:underline" href={`/locations/${row.id}`}>{row.name}</Link> },
            { key: 'project', header: 'Project', render: (row) => row.project },
            { key: 'address', header: 'Address', render: (row) => row.address },
            { key: 'lat', header: 'Lat', render: (row) => <span className="font-mono text-xs">{row.latitude}</span> },
            { key: 'lng', header: 'Lng', render: (row) => <span className="font-mono text-xs">{row.longitude}</span> },
            { key: 'radius', header: 'Radius', render: (row) => `${row.radius} m` },
            { key: 'active', header: 'Status', render: (row) => <Badge tone={row.active ? 'success' : 'neutral'}>{row.active ? 'Active' : 'Disabled'}</Badge> },
            { key: 'employees', header: 'Assigned', render: (row) => `${row.assignedEmployees} employees` },
          ]}
        />
      )}

      <Modal open={showAddModal} onClose={() => setShowAddModal(false)} title="Add Location"
        footer={
          <>
            <Button variant="secondary" onClick={() => setShowAddModal(false)}>Cancel</Button>
            <Button onClick={handleSubmit(onAddLocation)} disabled={formState.isSubmitting}>
              {formState.isSubmitting ? 'Saving...' : 'Create Location'}
            </Button>
          </>
        }
      >
        <form className="grid gap-4">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Site Name" error={formState.errors.name?.message}>
              <Input {...register('name')} placeholder="Sector 17" />
            </FormField>
            <FormField label="Project" error={formState.errors.project?.message}>
              <Input {...register('project')} placeholder="Metro Expansion" />
            </FormField>
          </div>
          <FormField label="Address" error={formState.errors.address?.message}>
            <Input {...register('address')} placeholder="Work site address" />
          </FormField>
          <div className="grid gap-4 md:grid-cols-3">
            <FormField label="Latitude" error={formState.errors.latitude?.message}>
              <Input {...register('latitude')} placeholder="28.5901" />
            </FormField>
            <FormField label="Longitude" error={formState.errors.longitude?.message}>
              <Input {...register('longitude')} placeholder="77.0479" />
            </FormField>
            <FormField label="Radius (m)" error={formState.errors.radius?.message}>
              <Input {...register('radius')} placeholder="150" />
            </FormField>
          </div>
          <label className="flex items-center gap-2 text-sm font-semibold">
            <input type="checkbox" {...register('active')} defaultChecked /> Active
          </label>
        </form>
      </Modal>
    </AppShell>
  );
}

// ─────────────────────────────────────────
// ANNOUNCEMENTS PAGE
// ─────────────────────────────────────────

export function AnnouncementsPage() {
  const query = useQuery({ queryKey: ['announcements-admin'], queryFn: announcementAdminApi.list });
  const router = useRouter();

  return (
    <AppShell>
      <SectionHeader title="Announcements" subtitle="Publish notices to your workforce"
        action={<Button onClick={() => router.push('/announcements/create')}><Plus size={16} /> Create Announcement</Button>}
      />
      {query.isLoading ? <Skeleton /> : (
        <DataTable
          rows={query.data ?? []}
          getKey={(row) => row.id}
          columns={[
            { key: 'title', header: 'Title', render: (row) => <Link className="font-semibold text-primary hover:underline" href={`/announcements/${row.id}`}>{row.title}</Link> },
            { key: 'category', header: 'Category', render: (row) => row.category },
            { key: 'target', header: 'Audience', render: (row) => row.target },
            { key: 'status', header: 'Status', render: (row) => <Badge tone={row.status === 'Published' ? 'success' : row.status === 'Scheduled' ? 'info' : 'neutral'}>{row.status}</Badge> },
            { key: 'pinned', header: 'Pinned', render: (row) => row.pinned ? '📌' : '—' },
            { key: 'publishedAt', header: 'Published', render: (row) => <span className="text-xs text-on-surface-variant">{row.publishedAt ?? '—'}</span> },
          ]}
        />
      )}
    </AppShell>
  );
}

// ─────────────────────────────────────────
// ANNOUNCEMENT CREATE PAGE
// ─────────────────────────────────────────

export function AnnouncementCreatePage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { showToast } = useToast();

  const { register, handleSubmit, formState } = useForm<AnnouncementFormInput>({
    resolver: zodResolver(announcementSchema),
    defaultValues: { priority: 'Normal', pinned: false },
  });

  async function onSubmit(data: AnnouncementFormInput) {
    await announcementAdminApi.create({
      title: data.title,
      category: data.category,
      body: data.body,
      target: data.target,
      pinned: data.pinned,
    });
    await queryClient.invalidateQueries({ queryKey: ['announcements-admin'] });
    showToast(`Announcement "${data.title}" published.`);
    router.push('/announcements');
  }

  return (
    <AppShell>
      <SectionHeader title="Create Announcement" subtitle="Publish a notice to selected employees" />
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl space-y-4">
        <Card>
          <div className="grid gap-4">
            <FormField label="Title" error={formState.errors.title?.message}>
              <Input {...register('title')} placeholder="Announcement title" />
            </FormField>
            <div className="grid gap-4 md:grid-cols-2">
              <FormField label="Category" error={formState.errors.category?.message}>
                <Select {...register('category')}>
                  <option value="">Select category</option>
                  {['Safety', 'Emergency', 'Policy', 'Project', 'General', 'Shift', 'System'].map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </Select>
              </FormField>
              <FormField label="Priority" error={formState.errors.priority?.message}>
                <Select {...register('priority')}>
                  <option value="Normal">Normal</option>
                  <option value="Important">Important</option>
                  <option value="Urgent">Urgent</option>
                </Select>
              </FormField>
            </div>
            <FormField label="Target Audience" error={formState.errors.target?.message}>
              <Select {...register('target')}>
                <option value="">Select audience</option>
                <option value="All Employees">All Employees</option>
                <option value="Operations">Operations Department</option>
                <option value="Engineering">Engineering Department</option>
                <option value="Safety">Safety Department</option>
                <option value="Metro Expansion team">Metro Expansion Team</option>
              </Select>
            </FormField>
            <FormField label="Body" error={formState.errors.body?.message}>
              <Textarea {...register('body')} placeholder="Write the announcement body here..." rows={6} />
            </FormField>
            <label className="flex items-center gap-2 text-sm font-semibold">
              <input type="checkbox" {...register('pinned')} /> Pin this announcement
            </label>
          </div>
        </Card>
        <div className="flex gap-3">
          <Button type="submit" disabled={formState.isSubmitting}>
            {formState.isSubmitting ? 'Publishing...' : 'Publish Announcement'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => router.back()}>Cancel</Button>
        </div>
      </form>
    </AppShell>
  );
}

// ─────────────────────────────────────────
// REPORTS PAGE
// ─────────────────────────────────────────

export function ReportsPage() {
  const report = useQuery({ queryKey: ['dashboard-report'], queryFn: reportApi.dashboard });
  const deptQuery = useQuery({ queryKey: ['departments-report'], queryFn: reportApi.departments });

  const reportTypes = [
    { title: 'Attendance Reports', desc: 'Daily, weekly, monthly attendance breakdown by employee, department, and project.' },
    { title: 'Exception Reports', desc: 'Location mismatches, face failures, and liveness failures requiring review.' },
    { title: 'Help Desk Reports', desc: 'Ticket volume, resolution times, and category analysis.' },
    { title: 'Employee Reports', desc: 'Headcount, turnover, and attendance percentage per employee.' },
    { title: 'Offline Sync Reports', desc: 'Records synced, failed syncs, and queue health.' },
    { title: 'Project Reports', desc: 'Attendance by project and assigned location.' },
  ];

  const COLORS = ['#0F4C81', '#1E88E5', '#2E7D32', '#ED6C02', '#D32F2F'];

  return (
    <AppShell>
      <SectionHeader title="Reports & Analytics" subtitle="Data exports and trend analysis"
        action={<Button variant="secondary"><FileDown size={16} /> Export CSV</Button>}
      />

      <div className="grid gap-4 xl:grid-cols-2">
        <Card className="h-72">
          <h2 className="mb-3 font-semibold">Attendance Trend (This Week)</h2>
          {report.isLoading ? <Skeleton /> : (
            <ResponsiveContainer width="100%" height="85%">
              <AreaChart data={report.data}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E0E5EB" />
                <XAxis dataKey="day" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Area dataKey="present" fill="#d2e4ff" stroke="#00355f" strokeWidth={2} name="Present" />
                <Area dataKey="absent" fill="#ffebee" stroke="#D32F2F" strokeWidth={2} name="Absent" />
                <Area dataKey="late" fill="#fff3e0" stroke="#ED6C02" strokeWidth={2} name="Late" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </Card>

        <Card className="h-72">
          <h2 className="mb-3 font-semibold">Department Attendance %</h2>
          {deptQuery.isLoading ? <Skeleton /> : (
            <ResponsiveContainer width="100%" height="85%">
              <PieChart>
                <Pie data={deptQuery.data} dataKey="percent" nameKey="department" cx="50%" cy="50%" outerRadius={80} label={({ department, percent }) => `${department}: ${percent}%`}>
                  {(deptQuery.data ?? []).map((_, index) => <Cell key={index} fill={COLORS[index % COLORS.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          )}
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {reportTypes.map((rt) => (
          <Card key={rt.title} className="cursor-pointer transition hover:border-secondary hover:shadow-md">
            <div className="mb-2 flex items-start justify-between">
              <FileDown className="text-primary" size={20} />
              <Button variant="ghost" className="h-8 px-2 text-xs">Export</Button>
            </div>
            <h2 className="font-semibold">{rt.title}</h2>
            <p className="mt-1 text-sm text-on-surface-variant">{rt.desc}</p>
            <div className="mt-3 flex gap-2">
              {['CSV', 'Excel', 'PDF'].map((fmt) => (
                <span key={fmt} className="rounded bg-surface-container-low px-2 py-0.5 text-xs font-semibold text-on-surface-variant">{fmt}</span>
              ))}
            </div>
          </Card>
        ))}
      </div>
    </AppShell>
  );
}

// ─────────────────────────────────────────
// AUDIT LOGS PAGE
// ─────────────────────────────────────────

export function AuditLogsPage() {
  const query = useQuery({ queryKey: ['audit-logs'], queryFn: auditApi.list });

  return (
    <AppShell>
      <SectionHeader title="Audit Logs" subtitle="Complete record of all administrative actions"
        action={<Button variant="secondary"><FileDown size={16} /> Export</Button>}
      />
      {query.isLoading ? <Skeleton /> : (
        <DataTable
          rows={query.data ?? []}
          getKey={(row) => row.id}
          columns={[
            { key: 'timestamp', header: 'Time', render: (row) => <span className="whitespace-nowrap text-xs font-mono">{row.timestamp}</span> },
            { key: 'event', header: 'Event', render: (row) => <span className="font-semibold">{row.event}</span> },
            { key: 'actor', header: 'Actor', render: (row) => row.actor },
            { key: 'target', header: 'Target', render: (row) => <span className="font-mono text-xs">{row.target ?? '—'}</span> },
            { key: 'details', header: 'Details', render: (row) => <span className="text-xs text-on-surface-variant">{row.details ?? '—'}</span> },
          ]}
        />
      )}
    </AppShell>
  );
}

// ─────────────────────────────────────────
// SETTINGS PAGE
// ─────────────────────────────────────────

export function SettingsPage({ section }: { section?: string }) {
  const query = useQuery({ queryKey: ['settings'], queryFn: settingsApi.sections });
  const { showToast } = useToast();
  const active = section ?? 'attendance';
  const activeCapitalized = active.charAt(0).toUpperCase() + active.slice(1);

  const settingGroups = {
    Attendance: [
      { key: 'check_in_window', label: 'Check-in Window', value: '30 minutes', type: 'text' },
      { key: 'grace_period', label: 'Grace Period (minutes)', value: '10', type: 'number' },
      { key: 'default_radius', label: 'Default GeoFence Radius (m)', value: '150', type: 'number' },
      { key: 'late_threshold', label: 'Late Threshold (minutes after shift)', value: '15', type: 'number' },
    ],
    Biometrics: [
      { key: 'face_threshold', label: 'Face Match Threshold', value: '0.92', type: 'number' },
      { key: 'liveness_threshold', label: 'Liveness Threshold', value: '0.90', type: 'number' },
      { key: 'quality_threshold', label: 'Minimum Face Quality', value: '0.85', type: 'number' },
      { key: 're_enroll_policy', label: 'Re-enrollment Policy', value: 'Manual', type: 'text' },
    ],
    Offline: [
      { key: 'offline_enabled', label: 'Offline Attendance Enabled', value: 'true', type: 'text' },
      { key: 'sync_retry', label: 'Sync Retry Count', value: '5', type: 'number' },
      { key: 'max_queue', label: 'Maximum Queue Size', value: '500', type: 'number' },
      { key: 'bg_sync', label: 'Background Sync Interval (minutes)', value: '15', type: 'number' },
    ],
    Organisation: [
      { key: 'org_name', label: 'Organisation Name', value: 'FaceVault Corp', type: 'text' },
      { key: 'timezone', label: 'Timezone', value: 'Asia/Kolkata (IST +05:30)', type: 'text' },
      { key: 'contact', label: 'Admin Contact Email', value: 'admin@facevault.local', type: 'text' },
    ],
  };

  return (
    <AppShell>
      <SectionHeader title="Settings" subtitle="Configure attendance, biometric, offline, and system preferences" />
      <div className="flex gap-2 overflow-x-auto border-b border-border-subtle pb-2 mb-6">
        {(query.data ?? ['Organisation', 'Attendance', 'Biometrics', 'Offline', 'Notifications', 'Roles']).map((sec) => (
          <Link key={sec} href={`/settings/${sec.toLowerCase()}`}
            className={`whitespace-nowrap rounded-t border-b-2 px-4 py-2 text-sm font-semibold transition ${
              activeCapitalized === sec ? 'border-primary text-primary' : 'border-transparent text-on-surface-variant hover:text-on-surface'
            }`}
          >
            {sec}
          </Link>
        ))}
      </div>

      <div className="max-w-2xl space-y-4">
        {Object.entries(settingGroups).map(([group, items]) => (
          <Card key={group} className={activeCapitalized === group ? 'ring-2 ring-secondary' : ''}>
            <h2 className="mb-4 font-semibold">{group}</h2>
            <div className="grid gap-4 md:grid-cols-2">
              {items.map((item) => (
                <FormField key={item.key} label={item.label}>
                  <Input defaultValue={item.value} type={item.type} />
                </FormField>
              ))}
            </div>
          </Card>
        ))}
        <div className="flex gap-3">
          <Button onClick={() => showToast('Settings saved successfully.')}>Save Changes</Button>
          <Button variant="secondary" onClick={() => showToast('Settings reset to defaults.', 'warning')}>Reset Defaults</Button>
        </div>
      </div>
    </AppShell>
  );
}

// ─────────────────────────────────────────
// SHARED INTERNAL COMPONENTS
// ─────────────────────────────────────────

function SectionHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-col justify-between gap-3 md:flex-row md:items-center">
      <div>
        <h1 className="text-2xl font-semibold text-on-surface">{title}</h1>
        {subtitle && <p className="mt-0.5 text-sm text-on-surface-variant">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

function Tabs({
  items,
  active,
  onSelect,
}: {
  items: string[];
  active: string;
  onSelect: (item: string) => void;
}) {
  return (
    <div className="mb-4 flex gap-2 overflow-x-auto">
      {items.map((item) => (
        <button
          key={item}
          onClick={() => onSelect(item)}
          className={`whitespace-nowrap rounded-full px-3 py-1.5 text-sm font-semibold transition ${
            active === item ? 'bg-primary text-white' : 'bg-white text-on-surface-variant hover:bg-surface-container-low'
          }`}
        >
          {item}
        </button>
      ))}
    </div>
  );
}

function MapPreview() {
  return (
    <Card className="mb-4 h-64 overflow-hidden">
      <div className="relative h-full rounded-lg bg-[linear-gradient(135deg,#d2e4ff,#f7f9fc)]">
        <div className="absolute left-1/2 top-1/2 h-40 w-40 -translate-x-1/2 -translate-y-1/2 rounded-full border-4 border-secondary/30 bg-blue-100/20" />
        <div className="absolute left-[52%] top-[44%] flex items-center gap-2 rounded-full bg-white px-3 py-2 text-sm font-semibold shadow-card">
          <MapPinned size={16} className="text-primary" /> Sector 17 — 150m radius
        </div>
        <p className="absolute bottom-3 right-3 rounded bg-white/80 px-2 py-1 text-xs text-on-surface-variant backdrop-blur-sm">
          Map integration point — connect to Google Maps, Mapbox, or OpenStreetMap
        </p>
      </div>
    </Card>
  );
}

function Row({
  label,
  value,
  mono = false,
}: {
  label: string;
  value: React.ReactNode;
  mono?: boolean;
}) {
  return (
    <div className="flex items-start justify-between gap-2">
      <span className="shrink-0 text-on-surface-variant">{label}</span>
      <span className={`text-right font-medium ${mono ? 'font-mono text-xs' : ''}`}>{value}</span>
    </div>
  );
}

'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { BarChart3, Bell, Building2, CalendarCheck, ClipboardList, FileText, HelpCircle, Home, LogOut, MapPinned, Megaphone, Settings, ShieldCheck, Users } from 'lucide-react';
import { clsx } from 'clsx';
import { useSessionStore } from '@/store/session-store';
import { Button } from './ui';
import { Protected } from './protected';

const nav = [
  { href: '/dashboard', label: 'Dashboard', icon: Home },
  { href: '/employees', label: 'Employees', icon: Users },
  { href: '/attendance', label: 'Attendance', icon: CalendarCheck },
  { href: '/verification-queue', label: 'Verification Queue', icon: ShieldCheck },
  { href: '/help-desk', label: 'Help Desk', icon: HelpCircle },
  { href: '/announcements', label: 'Announcements', icon: Megaphone },
  { href: '/locations', label: 'Locations', icon: MapPinned },
  { href: '/reports', label: 'Reports', icon: BarChart3 },
  { href: '/audit-logs', label: 'Audit Logs', icon: ClipboardList },
  { href: '/settings', label: 'Settings', icon: Settings }
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const logout = useSessionStore((state) => state.logout);

  return (
    <div className="min-h-screen bg-background text-on-surface md:grid md:grid-cols-[256px_1fr]">
      <aside className="sticky top-0 hidden h-screen border-r border-border-subtle bg-white p-4 md:block">
        <div className="mb-6 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-white"><Building2 size={20} /></div>
          <div>
            <p className="text-lg font-bold text-primary">FaceVault</p>
            <p className="text-xs text-on-surface-variant">Admin Console</p>
          </div>
        </div>
        <nav className="space-y-1">
          {nav.map((item) => {
            const Icon = item.icon;
            const active = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className={clsx('flex items-center gap-3 rounded px-3 py-2 text-sm font-medium', active ? 'bg-blue-50 text-primary' : 'text-on-surface-variant hover:bg-surface-container-low')}>
                <Icon size={18} />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <Button
          variant="ghost"
          className="mt-6 w-full justify-start"
          onClick={() => {
            logout();
            router.push('/login');
          }}
        >
          <LogOut size={16} /> Logout
        </Button>
      </aside>
      <main className="min-w-0">
        <header className="sticky top-0 z-20 flex items-center justify-between border-b border-border-subtle bg-background/95 px-4 py-3 backdrop-blur md:px-6">
          <div>
            <p className="text-xs font-semibold uppercase text-on-surface-variant">AI attendance operations</p>
            <h1 className="text-xl font-semibold">Workforce Management</h1>
          </div>
          <Button variant="ghost"><Bell size={18} /> 7</Button>
        </header>
        <div className="p-4 md:p-6"><Protected>{children}</Protected></div>
      </main>
    </div>
  );
}



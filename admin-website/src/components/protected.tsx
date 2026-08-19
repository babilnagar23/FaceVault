'use client';

import { usePathname, useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { useSessionStore } from '@/store/session-store';

export function Protected({ children }: { children: React.ReactNode }) {
  const authenticated = useSessionStore((state) => state.authenticated);
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (!authenticated && pathname !== '/login') {
      router.replace('/login');
    }
  }, [authenticated, pathname, router]);

  return <>{children}</>;
}


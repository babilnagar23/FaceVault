'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { Lock, ShieldCheck } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { adminAuthApi } from '@/lib/admin-api';
import { useSessionStore } from '@/store/session-store';
import { adminLoginSchema, type AdminLoginInput } from '@/validators/auth';
import { Button, Card, Input } from '@/components/ui';

export default function LoginPage() {
  const router = useRouter();
  const login = useSessionStore((state) => state.login);
  const { register, handleSubmit, formState } = useForm<AdminLoginInput>({
    resolver: zodResolver(adminLoginSchema),
    defaultValues: { organisationCode: 'FACEVAULT', email: 'admin@facevault.local', password: 'demo1234', remember: true }
  });

  async function onSubmit(input: AdminLoginInput) {
    await adminAuthApi.login(input);
    login();
    router.push('/dashboard');
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md overflow-hidden p-0">
        <div className="bg-surface-container-low p-8 text-center">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-primary text-white"><ShieldCheck /></div>
          <h1 className="mt-4 text-2xl font-bold text-primary">FaceVault Admin</h1>
          <p className="text-sm text-on-surface-variant">Organisation dashboard with MFA-ready sign in.</p>
        </div>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 p-6">
          <label className="grid gap-1 text-sm font-semibold">Organisation code<Input {...register('organisationCode')} /></label>
          <label className="grid gap-1 text-sm font-semibold">Admin email<Input type="email" {...register('email')} /></label>
          <label className="grid gap-1 text-sm font-semibold">Password<Input type="password" {...register('password')} /></label>
          <label className="flex items-center gap-2 text-sm"><input type="checkbox" {...register('remember')} /> Remember session</label>
          {Object.values(formState.errors).map((error) => <p key={error.message} className="text-sm text-error">{error.message}</p>)}
          <Button className="w-full" disabled={formState.isSubmitting}><Lock size={16} /> Login</Button>
          <button type="button" className="w-full text-sm font-semibold text-secondary">Forgot password</button>
        </form>
      </Card>
    </main>
  );
}


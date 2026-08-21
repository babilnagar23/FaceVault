'use client';

import { clsx } from 'clsx';
import React, { createContext, useCallback, useContext, useRef, useState } from 'react';

// ─────────────────────────────────────────
// BUTTON
// ─────────────────────────────────────────

export function Button({
  className,
  variant = 'primary',
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
}) {
  return (
    <button
      className={clsx(
        'inline-flex h-10 items-center justify-center gap-2 rounded px-4 text-sm font-semibold transition disabled:opacity-60',
        variant === 'primary' && 'bg-primary text-white hover:bg-primary-container',
        variant === 'secondary' && 'border border-secondary text-secondary hover:bg-blue-50',
        variant === 'ghost' && 'text-primary hover:bg-surface-container-low',
        variant === 'danger' && 'bg-error text-white hover:opacity-90',
        className
      )}
      {...props}
    />
  );
}

// ─────────────────────────────────────────
// CARD
// ─────────────────────────────────────────

export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={clsx('rounded-xl border border-border-subtle bg-surface p-4 shadow-card', className)} {...props} />;
}

// ─────────────────────────────────────────
// BADGE / STATUS CHIP
// ─────────────────────────────────────────

export function Badge({
  className,
  tone = 'neutral',
  ...props
}: React.HTMLAttributes<HTMLSpanElement> & { tone?: 'success' | 'warning' | 'error' | 'neutral' | 'info' }) {
  return (
    <span
      className={clsx(
        'inline-flex rounded-full px-2.5 py-1 text-xs font-bold',
        tone === 'success' && 'bg-green-50 text-success',
        tone === 'warning' && 'bg-orange-50 text-warning',
        tone === 'error' && 'bg-red-50 text-error',
        tone === 'neutral' && 'bg-surface-container text-on-surface-variant',
        tone === 'info' && 'bg-blue-50 text-secondary',
        className
      )}
      {...props}
    />
  );
}

export const StatusChip = Badge;

// ─────────────────────────────────────────
// FORM CONTROLS
// ─────────────────────────────────────────

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className="h-10 w-full rounded border border-border-subtle bg-white px-3 text-sm text-on-surface outline-none placeholder:text-on-surface-variant focus:border-secondary focus:ring-2 focus:ring-blue-100 disabled:bg-surface-container-low"
      {...props}
    />
  );
}

export function Textarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className="w-full rounded border border-border-subtle bg-white px-3 py-2 text-sm text-on-surface outline-none placeholder:text-on-surface-variant focus:border-secondary focus:ring-2 focus:ring-blue-100"
      rows={4}
      {...props}
    />
  );
}

export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      className="h-10 w-full rounded border border-border-subtle bg-white px-3 text-sm outline-none focus:border-secondary focus:ring-2 focus:ring-blue-100"
      {...props}
    />
  );
}

export function FormField({
  label,
  error,
  children,
}: {
  label: string;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="grid gap-1">
      <span className="text-sm font-semibold text-on-surface">{label}</span>
      {children}
      {error && <span className="text-xs text-error">{error}</span>}
    </label>
  );
}

// ─────────────────────────────────────────
// SKELETON
// ─────────────────────────────────────────

export function Skeleton({ rows = 4 }: { rows?: number }) {
  return (
    <div className="space-y-2">
      {Array.from({ length: rows }).map((_, index) => (
        <div key={index} className="h-12 animate-pulse rounded bg-surface-container" />
      ))}
    </div>
  );
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

export function EmptyState({
  title,
  message,
  action,
  actionLabel,
}: {
  title: string;
  message: string;
  action?: () => void;
  actionLabel?: string;
}) {
  return (
    <Card className="py-12 text-center">
      <p className="font-semibold text-on-surface">{title}</p>
      <p className="mt-1 text-sm text-on-surface-variant">{message}</p>
      {action && (
        <button
          onClick={action}
          className="mt-4 rounded px-4 py-2 text-sm font-semibold text-secondary hover:bg-blue-50"
        >
          {actionLabel ?? 'Try again'}
        </button>
      )}
    </Card>
  );
}

// ─────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────

export function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <Card className="flex items-center justify-between">
      <span className="text-sm text-error">{message}</span>
      <Button variant="secondary" onClick={onRetry}>
        Retry
      </Button>
    </Card>
  );
}

// ─────────────────────────────────────────
// DATA TABLE
// ─────────────────────────────────────────

export function DataTable<T>({
  columns,
  rows,
  getKey,
}: {
  columns: { key: string; header: string; render: (row: T) => React.ReactNode }[];
  rows: T[];
  getKey: (row: T) => string;
}) {
  return (
    <div className="overflow-x-auto rounded-xl border border-border-subtle bg-white">
      <table className="min-w-full text-left text-sm">
        <thead className="bg-surface-container-low text-xs font-semibold uppercase text-on-surface-variant">
          <tr>
            {columns.map((column) => (
              <th key={column.key} className="px-4 py-3">
                {column.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={getKey(row)} className="border-t border-border-subtle hover:bg-surface-container-low">
              {columns.map((column) => (
                <td key={column.key} className="px-4 py-3">
                  {column.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ─────────────────────────────────────────
// MODAL
// ─────────────────────────────────────────

export function Modal({
  open,
  onClose,
  title,
  children,
  footer,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="w-full max-w-lg rounded-2xl border border-border-subtle bg-surface shadow-[0_24px_64px_rgba(0,0,0,0.18)]">
        <div className="flex items-center justify-between border-b border-border-subtle px-6 py-4">
          <h2 className="text-lg font-semibold text-on-surface">{title}</h2>
          <button
            onClick={onClose}
            className="rounded p-1 text-on-surface-variant hover:bg-surface-container-low"
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        <div className="p-6">{children}</div>
        {footer && (
          <div className="flex justify-end gap-2 border-t border-border-subtle px-6 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = 'Confirm',
  danger = false,
  loading = false,
}: {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description: string;
  confirmLabel?: string;
  danger?: boolean;
  loading?: boolean;
}) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button variant={danger ? 'danger' : 'primary'} onClick={onConfirm} disabled={loading}>
            {loading ? 'Processing...' : confirmLabel}
          </Button>
        </>
      }
    >
      <p className="text-sm text-on-surface-variant">{description}</p>
    </Modal>
  );
}

// ─────────────────────────────────────────
// TOAST SYSTEM
// ─────────────────────────────────────────

type ToastItem = {
  id: string;
  message: string;
  tone: 'success' | 'error' | 'warning' | 'info';
};

type ToastContextType = {
  showToast: (message: string, tone?: ToastItem['tone']) => void;
};

const ToastContext = createContext<ToastContextType>({ showToast: () => {} });

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const counter = useRef(0);

  const showToast = useCallback((message: string, tone: ToastItem['tone'] = 'success') => {
    const id = `toast-${counter.current++}`;
    setToasts((prev) => [...prev, { id, message, tone }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 3800);
  }, []);

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      {/* Toast container */}
      <div className="fixed bottom-6 right-6 z-[100] flex flex-col gap-2" aria-live="polite">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={clsx(
              'flex min-w-[280px] max-w-sm items-center gap-3 rounded-lg border px-4 py-3 shadow-lg',
              'animate-in slide-in-from-right-4 fade-in duration-200',
              toast.tone === 'success' && 'border-green-200 bg-green-50 text-success',
              toast.tone === 'error' && 'border-red-200 bg-red-50 text-error',
              toast.tone === 'warning' && 'border-orange-200 bg-orange-50 text-warning',
              toast.tone === 'info' && 'border-blue-200 bg-blue-50 text-secondary'
            )}
          >
            <span className="text-lg">
              {toast.tone === 'success' ? '✓' : toast.tone === 'error' ? '✕' : toast.tone === 'warning' ? '⚠' : 'ℹ'}
            </span>
            <p className="text-sm font-semibold">{toast.message}</p>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  return useContext(ToastContext);
}

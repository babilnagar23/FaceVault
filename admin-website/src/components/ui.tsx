import { clsx } from 'clsx';

export function Button({ className, variant = 'primary', ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'secondary' | 'ghost' }) {
  return (
    <button
      className={clsx(
        'inline-flex h-10 items-center justify-center gap-2 rounded px-4 text-sm font-semibold transition',
        variant === 'primary' && 'bg-primary text-white hover:bg-primary-container',
        variant === 'secondary' && 'border border-secondary text-secondary hover:bg-blue-50',
        variant === 'ghost' && 'text-primary hover:bg-surface-container-low',
        className
      )}
      {...props}
    />
  );
}

export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={clsx('rounded-xl border border-border-subtle bg-surface p-4 shadow-card', className)} {...props} />;
}

export function Badge({ className, tone = 'neutral', ...props }: React.HTMLAttributes<HTMLSpanElement> & { tone?: 'success' | 'warning' | 'error' | 'neutral' }) {
  return (
    <span
      className={clsx(
        'inline-flex rounded-full px-2.5 py-1 text-xs font-bold',
        tone === 'success' && 'bg-green-50 text-success',
        tone === 'warning' && 'bg-orange-50 text-warning',
        tone === 'error' && 'bg-red-50 text-error',
        tone === 'neutral' && 'bg-surface-container text-on-surface-variant',
        className
      )}
      {...props}
    />
  );
}

export const StatusChip = Badge;

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input className="h-10 rounded border border-border-subtle bg-white px-3 text-sm outline-none focus:border-secondary focus:ring-2 focus:ring-blue-100" {...props} />;
}

export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <select className="h-10 rounded border border-border-subtle bg-white px-3 text-sm outline-none focus:border-secondary focus:ring-2 focus:ring-blue-100" {...props} />;
}

export function Skeleton({ rows = 4 }: { rows?: number }) {
  return <div className="space-y-2">{Array.from({ length: rows }).map((_, index) => <div key={index} className="h-12 animate-pulse rounded bg-surface-container" />)}</div>;
}

export function EmptyState({ title, message }: { title: string; message: string }) {
  return <Card className="text-center"><p className="font-semibold">{title}</p><p className="text-sm text-on-surface-variant">{message}</p></Card>;
}

export function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return <Card className="flex items-center justify-between"><span className="text-sm text-error">{message}</span><Button variant="secondary" onClick={onRetry}>Retry</Button></Card>;
}

export function DataTable<T>({ columns, rows, getKey }: { columns: { key: string; header: string; render: (row: T) => React.ReactNode }[]; rows: T[]; getKey: (row: T) => string }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-border-subtle bg-white">
      <table className="min-w-full text-left text-sm">
        <thead className="bg-surface-container-low text-xs font-semibold uppercase text-on-surface-variant">
          <tr>{columns.map((column) => <th key={column.key} className="px-4 py-3">{column.header}</th>)}</tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={getKey(row)} className="border-t border-border-subtle">
              {columns.map((column) => <td key={column.key} className="px-4 py-3">{column.render(row)}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}


import { z } from 'zod';

// ─────────────────────────────────────────
// EMPLOYEE
// ─────────────────────────────────────────

export const employeeSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  department: z.string().min(1, 'Department is required'),
  role: z.string().min(1, 'Role is required'),
  project: z.string().min(1, 'Project is required'),
  location: z.string().min(1, 'Location is required'),
  shift: z.string().min(1, 'Shift is required'),
  email: z.string().email('Enter a valid email'),
  phone: z.string().optional(),
  manager: z.string().optional(),
});

export type EmployeeFormInput = z.infer<typeof employeeSchema>;

// ─────────────────────────────────────────
// LOCATION / SITE
// ─────────────────────────────────────────

export const locationSchema = z.object({
  name: z.string().min(2, 'Site name is required'),
  project: z.string().min(1, 'Project is required'),
  address: z.string().min(5, 'Address is required'),
  latitude: z
    .string()
    .refine((v) => !isNaN(Number(v)) && Number(v) >= -90 && Number(v) <= 90, 'Invalid latitude'),
  longitude: z
    .string()
    .refine((v) => !isNaN(Number(v)) && Number(v) >= -180 && Number(v) <= 180, 'Invalid longitude'),
  radius: z
    .string()
    .refine((v) => !isNaN(Number(v)) && Number(v) > 0 && Number(v) <= 5000, 'Radius must be 1–5000 m'),
  active: z.boolean().default(true),
});

export type LocationFormInput = z.infer<typeof locationSchema>;

// ─────────────────────────────────────────
// ANNOUNCEMENT
// ─────────────────────────────────────────

export const announcementSchema = z.object({
  title: z.string().min(3, 'Title is required').max(120, 'Title is too long'),
  category: z.enum(['Safety', 'Emergency', 'Policy', 'Project', 'General', 'Shift', 'System'], {
    errorMap: () => ({ message: 'Select a valid category' }),
  }),
  body: z.string().min(10, 'Body text is required').max(5000, 'Body is too long'),
  target: z.string().min(1, 'Select a target audience'),
  priority: z.enum(['Normal', 'Important', 'Urgent']).default('Normal'),
  pinned: z.boolean().default(false),
  publishAt: z.string().optional(),
  expiresAt: z.string().optional(),
});

export type AnnouncementFormInput = z.infer<typeof announcementSchema>;

// ─────────────────────────────────────────
// VERIFICATION DECISION
// ─────────────────────────────────────────

export const verificationDecisionSchema = z.object({
  decision: z.enum(['approve', 'reject', 'request_explanation', 'correct_location']),
  remarks: z.string().optional(),
});

export type VerificationDecisionInput = z.infer<typeof verificationDecisionSchema>;

// ─────────────────────────────────────────
// HELP TICKET REPLY
// ─────────────────────────────────────────

export const helpReplySchema = z.object({
  body: z.string().min(1, 'Reply cannot be empty'),
  action: z.enum(['note', 'assign', 'resolve', 'reject', 'escalate']).default('note'),
});

export type HelpReplyInput = z.infer<typeof helpReplySchema>;

import { z } from 'zod';

export const adminLoginSchema = z.object({
  organisationCode: z.string().min(2, 'Organisation code is required'),
  email: z.string().email('Enter a valid admin email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  remember: z.boolean()
});

export type AdminLoginInput = z.infer<typeof adminLoginSchema>;


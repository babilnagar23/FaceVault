# Shared Frontend Contracts

The mobile and admin frontends are wired against typed interfaces rather than hardcoded backend calls.

## Core API Areas

- Authentication and session refresh
- Employee profile, assignments, devices, and biometric status
- Attendance attempts, history, exceptions, and review decisions
- Location/geofence management
- Help desk ticket lifecycle
- Announcements and notifications
- Reports, audit logs, and settings
- Offline sync queue ingestion and conflict reporting

## Security Notes

- Passwords are never persisted.
- Mobile tokens belong in secure storage.
- Biometric embeddings are not exposed to UI code.
- Admin route protection is enforced in the frontend and must be mirrored by Django permissions.


# Frontend Implementation Map

## Existing Code

The repository initially contained only the Stitch reference bundle at `stitch_facevault/`. There were no existing Flutter, Next.js, backend, API client, state management, local storage, or authentication implementations to reuse.

## Reusable Components

The reusable runtime components created in this phase are:

- Mobile: `AppScaffold`, `MetricCard`, `StatusChip`, `PrimaryActionButton`, `AppTextField`, `EmptyStateView`, `ErrorStateView`, `LoadingSkeleton`.
- Admin: `Button`, `Card`, `Badge`, `StatusChip`, `Input`, `Select`, `Table`, `Skeleton`, `EmptyState`, `ErrorState`, `AppShell`.

## Stitch References

The runtime visual language is based on `stitch_facevault/enterprise_precision/DESIGN.md`, with screen-specific hierarchy and content borrowed from:

- Mobile: splash, login, permissions, device registration, face enrollment, attendance AI pipeline, attendance success, attendance history, employee dashboard, help center, community announcements, notifications, profile, offline sync.
- Admin: admin login, dashboard overview, employee management, employee profile, biometric enrollment management, verification review, help desk, location geofence setup, reports analytics center, attendance settings, biometric settings, platform settings.

## Required Missing Screens

All required routes now have connected state/data-backed screens. Backend-backed actions currently call typed mock repositories through API interfaces, so replacing mocks with Django clients is straightforward.

## Final Frontend Architecture

```text
Screen/Page
  -> Controller/Hook
  -> Repository/API interface
  -> Mock datasource now, Django API later
  -> Offline queue/cache where required
```


# FaceVault

AI-powered, offline-first attendance and workforce management frontend foundation.

## Applications

- `mobile-app/` - Flutter employee application using Riverpod, GoRouter, Dio, secure storage, permissions, camera/location abstractions, and an offline sync queue.
- `admin-website/` - Next.js admin dashboard using TypeScript, Tailwind CSS, TanStack Query, Zustand, React Hook Form, Zod, and Recharts.
- `stitch_facevault/` - Stitch-generated design references. These files are preserved as references and are not runtime application code.

## Run

```powershell
cd mobile-app
flutter pub get
flutter analyze
flutter test
flutter run
```

```powershell
cd admin-website
npm install
npm run dev
npm run lint
npm run typecheck
npm run build
```


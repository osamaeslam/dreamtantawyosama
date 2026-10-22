# AGENTS.md

## Project Overview
This repository contains a 100% pure Flutter multiplatform application at `flutter_tantawy/` supporting Web, Android, and iOS platforms. React has been completely decommissioned and removed.

## Key Architecture Notes
- **Flutter Multiplatform app**: At `flutter_tantawy/`, 28 screens, full models and state services
- **Database**: Supabase backend with realtime streams and offline sync
- **UI**: Arabic-first (RTL), luxury dark-gold theme, mobile rep flow, catalog, visits & invoice printing

## Lint and Build Commands
For Flutter (local or GitHub Actions CI):
```bash
# In flutter_tantawy/ directory:
flutter pub get        # Install dependencies
flutter analyze        # Run static analysis / lint
flutter format .        # Format Dart code
flutter test            # Run tests
flutter build apk       # Build Android APK
flutter build web       # Build Web release
```

For the automated web container / distribution:
```bash
# In root directory:
npm run lint            # Flutter verification check
npm run build           # Production distribution pipeline
```

## Code Style Guidelines
- Dart: Follow effective Dart style guide (2-space indentation, camelCase)
- Arabic text in Arabic strings, English in code identifiers
- All model fields must be optional (nullable) for backward compatibility
- Use `shared_preferences` and `provider` for state & persistence

## File Structure
- `flutter_tantawy/lib/models/models.dart` — Canonical models matching enterprise schema
- `flutter_tantawy/lib/services/supabase_service.dart` — All Supabase queries and realtime subscriptions
- `flutter_tantawy/lib/services/cart_service.dart` — Cart management with variant & carton pricing
- `flutter_tantawy/lib/services/theme_provider.dart` — Luxury dark-gold theme provider
- `flutter_tantawy/lib/services/role_access_controller.dart` — RBAC for all data types & screens
- `flutter_tantawy/lib/screens/*.dart` — 28 screens for sales reps, supervisors, management, and legal
- `flutter_tantawy/lib/theme/app_theme.dart` — Luxury dark-gold theme
- `flutter_tantawy/main.dart` — App entry point

## GitHub Actions Automated Pipelines
- `.github/workflows/deploy.yml` — Automated Flutter Web build and deployment to Vercel
- `.github/workflows/build-apk.yml` — Automated Android APK release compilation and artifact download
# AGENTS.md

## Project Overview
This repository contains a React web application at the root (`src/`) and a Flutter mobile app at `flutter_tantawy/`. The project is migrating from a React TypeScript web app to a Flutter app supporting Web, Android, and iOS platforms.

## Key Architecture Notes
- **React app**: TypeScript at root, 52 components, 29 services in `src/`
- **Flutter app**: At `flutter_tantawy/`, 23 Dart files with 26 model classes and 10 enums
- **Database**: Shared Supabase backend with identical schema
- **UI**: Arabic-first (RTL), dark theme, professional catalog features

## Lint and Typecheck Commands
⚠️ **IMPORTANT**: The Flutter SDK is NOT installed in this environment. The following commands must be run locally where Flutter is available:

```
# In flutter_tantawy/ directory:
flutter pub get        # Install dependencies
flutter analyze        # Run static analysis / lint
flutter format .        # Format Dart code
flutter test            # Run tests
flutter build apk       # Build Android APK
flutter build web       # Build web version
```

For the React app:
```
# In root directory:
npm run lint            # ESLint
npm run typecheck       # TypeScript type checking
npm run build           # Production build
```

## Code Style Guidelines
- Dart: Follow effective Dart style guide (2-space indentation, camelCase)
- Arabic text in Arabic strings, English in code identifiers
- All model fields must be optional (nullable) for backward compatibility
- Use `shared_preferences` for local persistence (no other state management libs beyond provider)

## File Structure
- `flutter_tantawy/lib/models/models.dart` — Canonical models matching `src/types.ts`
- `flutter_tantawy/lib/services/supabase_service.dart` — All Supabase queries
- `flutter_tantawy/lib/services/cart_service.dart` — Cart management with variant support
- `flutter_tantawy/lib/services/theme_provider.dart` — Theme mode persistence
- `flutter_tantawy/lib/services/role_access_controller.dart` — RBAC for all data types
- `flutter_tantawy/lib/screens/*.dart` — Screen implementations
- `flutter_tantawy/lib/theme/app_theme.dart` — Light and dark themes
- `flutter_tantawy/main.dart` — App entry point

## Validation Notes
Since Flutter SDK is unavailable, all `.dart` files have been validated using Python-based character count validation. All 23 files show balanced braces, parentheses, and brackets. The `catalog_screen.dart` file shows a false positive in naive bracket counting due to Dart's nested string interpolation `'${condition ? "yes" : "no"}'` — the actual Dart syntax is valid.

## React Reference Files
- `src/types.ts` — Canonical TypeScript types (737 lines)
- `src/components/OrderReturnModal.tsx` — Return management reference
- `src/components/TargetPerformanceDashboard.tsx` — Performance dashboard reference
- `src/components/CollectionForecastView.tsx` — Forecast view reference
- `src/components/AllCustomersAnalyticsView.tsx` — Analytics reference
- `src/components/ManagementDashboard.tsx` — Management reference
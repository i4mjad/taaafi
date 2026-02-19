# Mobile Agent

You are the **mobile-agent** for the Ta'aafi monorepo. You develop the Flutter mobile app.

## Scope

- **WRITE:** `apps/mobile/`
- **READ:** Entire repository (for context, shared types, backend contracts)
- **NEVER WRITE:** `apps/admin/`, `apps/website/`, `functions/`, root config files

## HARD RULES

Read and follow ALL hard rules in the root `CLAUDE.md`. Additionally:
- Never lower `minSdkVersion` below **23**
- Never modify Dart SDK constraint outside `>=3.0.0 <=4.0.0`
- Warn the user when touching `android/` or `ios/` — Shorebird cannot OTA native changes
- Never commit `google-services.json`, `.env`, or service account files

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State management | Riverpod v2 with codegen (`riverpod_annotation` + `riverpod_generator`) |
| Routing | GoRouter v16 (`core/routing/`) |
| HTTP client | Dio (`core/network/`) |
| Firebase | Core, Auth, Firestore, Functions, Analytics, Crashlytics, Messaging, Remote Config, Storage |
| OTA | Shorebird (`shorebird_code_push ^2.0.4`) |
| Analytics | Mixpanel + Firebase Analytics (facade in `core/monitoring/`) |
| Payments | RevenueCat (`purchases_flutter ^9.1.0`) |
| Calendar | Syncfusion Flutter Calendar |
| Rich text | flutter_quill |
| Charts | fl_chart |
| Icons | Lucide Icons + Ta3afiPlatformIcons (custom) |
| Fonts | ExpoArabic (Book/Medium/Bold/Light/SemiBold) |

## Architecture

**Feature-first + Clean Architecture**

```
lib/
├── core/                    # Shared infrastructure
│   ├── localization/        # AppLocalizations + LocaleNotifier
│   ├── monitoring/          # Analytics facade (Mixpanel + Firebase)
│   ├── routing/             # GoRouter setup, route names, nav scaffold
│   ├── theming/             # ThemeData, colors, text styles
│   ├── messaging/           # FCM topic service
│   ├── network/             # Dio provider
│   ├── services/            # Device tracking, email sync, haptic
│   ├── shared_widgets/      # Reusable widgets
│   └── utils/
├── features/                # Feature modules
│   ├── authentication/      # Auth flows (Apple, Google, Firebase)
│   ├── community/           # Forum, challenges, profiles
│   ├── direct_messaging/    # DMs
│   ├── groups/              # Group management, updates, messages
│   ├── home/                # Home screen, reports
│   ├── vault/               # Diaries, emotions, streaks, calendar, analytics
│   ├── plus/                # Premium features (RevenueCat)
│   ├── referral/            # Referral system
│   ├── notifications/       # Notification center
│   ├── onboarding/          # Onboarding flow
│   └── shared/              # Cross-feature shared models/widgets
└── i18n/                    # Translation files
```

**Layer pattern per feature:** `presentation/` → `application/` → `data/` → `domain/`
Not all features need all layers. Simpler features may only have `presentation/` + `data/`.

## Riverpod Codegen Workflow

After ANY change to `@riverpod`-annotated providers or classes:
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```
- Always commit generated `*.g.dart` files alongside source changes
- Use `build_runner watch` during active development for auto-regeneration

## i18n Rules

Every new user-facing string MUST have **both** translations:
- `lib/i18n/en_translations.dart` — add to `kEn` map
- `lib/i18n/ar_translations.dart` — add to `kAr` map
- Register in `lib/i18n/translations.dart` if adding a new translations file

Arabic is the default locale. Use `AppLocalizations` from `core/localization/` to access translations.

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/app.dart` | Root ConsumerWidget (MaterialApp + GoRouter + theming) |
| `lib/firebase_options.dart` | Firebase config (auto-generated) |
| `lib/core/routing/` | All route definitions and navigation |
| `lib/core/theming/` | Theme, colors, text styles, dark mode |
| `lib/i18n/translations.dart` | Master translation registry |
| `pubspec.yaml` | Dependencies and app metadata |
| `android/app/build.gradle` | Android build config (minSdk, compileSdk) |

## Platform Constraints

- **Android minSdk:** 23 (strict — never lower)
- **Android compileSdk:** 35
- **Android targetSdk:** 35
- **Dart SDK:** `>=3.0.0 <=4.0.0`
- **Java:** 17
- **MultiDex:** enabled
- **Core library desugaring:** enabled

## Commit Convention

Follow the root `CLAUDE.md` commit convention. Always use scope `mobile`:
```
feat(mobile): add streak counter to home screen
fix(mobile): resolve null check in vault provider
chore(mobile): update riverpod to latest version
```
Commit after each small, atomic change. Never batch unrelated changes.

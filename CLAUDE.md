# Ta'aafi Monorepo — CLAUDE.md

## HARD RULES

> These rules are **non-negotiable**. Every agent and every session must follow them.

1. **Never commit secrets** — No `.env`, API keys, service account JSONs, `google-services.json`, or `rebootapp-*.json` files. If you see them staged, unstage immediately.
2. **Never modify production data** — No Firestore writes to prod, no deploys without explicit user permission.
3. **Never deploy without explicit permission** — No `firebase deploy`, `shorebird release`, Codemagic triggers, or Vercel deploys unless the user says so.
4. **Never delete user data** — No Firestore document deletions without explicit approval.
5. **Never force push** — No `git push --force`, no `git reset --hard`.
6. **Never modify Firebase config without asking** — `.firebaserc`, `firebase.json`, `firestore.rules`, `storage.rules` are all protected.

---

## Repository Structure

```
taaafi/
├── apps/
│   ├── mobile/          # Flutter mobile app (iOS + Android)
│   ├── admin/           # Next.js admin control panel
│   └── website/         # Next.js public marketing website
├── functions/           # Unified Firebase Cloud Functions (all apps)
├── firebase.json        # Root Firebase config
├── .firebaserc          # Firebase project binding
├── firestore.rules      # Firestore security rules
├── firestore.indexes.json # Composite indexes
├── storage.rules        # Storage security rules
├── CLAUDE.md            # This file — single source of truth
└── .claude/agents/      # Agent definitions for team-based work
```

**No monorepo tooling** (no Turborepo, no Nx). Each app is independent with its own `package.json` / `pubspec.yaml`. Keep them independent.

---

## Shared Infrastructure

- **Firebase project:** `rebootapp-37a30` (single project for all apps)
- **Cloud Functions:** Single unified directory at `functions/` — Firebase Functions v5, Node 22
- **Firebase config:** Root-level `firebase.json`, `.firebaserc`, `firestore.rules`, `storage.rules`
- **Firestore, Auth, Storage, FCM** — shared across mobile + admin
- **Website has NO Firebase dependency** — purely static/SSR

---

## App Details

### Mobile (`apps/mobile/`)

| Aspect | Detail |
|--------|--------|
| Framework | Flutter + Dart SDK `>=3.0.0 <=4.0.0` |
| State management | Riverpod v2 with codegen (`riverpod_annotation` + `riverpod_generator`) |
| Routing | GoRouter v16 |
| Architecture | Feature-first + Clean Architecture (`presentation/application/data/domain`) |
| Firebase | Core, Auth, Firestore, Functions, Analytics, Crashlytics, Messaging, Remote Config, Storage |
| OTA updates | Shorebird (`shorebird_code_push ^2.0.4`) |
| Analytics | Dual: Mixpanel + Firebase Analytics (facade pattern in `core/monitoring/`) |
| Payments | RevenueCat (`purchases_flutter ^9.1.0`) |
| i18n | Compile-time Dart Maps in `lib/i18n/` (`kEn`, `kAr`) — Arabic default |
| Fonts | ExpoArabic (custom), Ta3afiPlatformIcons |
| Android minSdk | **23** (strict) |
| Android compileSdk | 35 |
| App ID | `com.amjadkhalfan.reboot_app_3` |
| CI | Codemagic |

### Admin (`apps/admin/`)

| Aspect | Detail |
|--------|--------|
| Framework | Next.js 15 + React 19 + TypeScript 5.9 |
| Styling | Tailwind CSS **v4** (CSS-first, no JS config) + shadcn/ui **new-york** style |
| Architecture | Module-based (`src/modules/`, `src/repositories/`, `src/services/`) |
| Firebase | Client SDK v11 + Admin SDK v13 |
| Auth | Firebase Auth with RBAC |
| i18n | JSON dictionaries (`src/dictionaries/ar.json`, `en.json`) + middleware routing via `[lang]` segment |
| Default locale | Arabic (`ar`) |
| UI components | shadcn/ui (new-york), Lucide icons, Recharts, TanStack Table, dnd-kit |

### Website (`apps/website/`)

| Aspect | Detail |
|--------|--------|
| Framework | Next.js 15 + React 19 + TypeScript 5 |
| Styling | Tailwind CSS **v3.4** (JS config) + shadcn/ui **default** style |
| Animations | Framer Motion v12 |
| Architecture | Page-centric (landing, blog, privacy, terms) |
| Blog | Static data in `src/data/blog.ts` (intentional — no CMS) |
| Firebase | **None** — no backend dependency |
| i18n | JSON dictionaries (`src/app/dictionaries/`) + middleware (hardcoded Arabic redirect) |
| Default locale | Arabic (`ar`) — hardcoded in middleware |
| Forms | react-hook-form + zod |

---

## Commands Reference

### Mobile
```bash
cd apps/mobile
flutter pub get                              # Install dependencies
flutter run                                  # Run debug
flutter build apk                            # Build Android APK
flutter build ios                            # Build iOS
dart run build_runner build --delete-conflicting-outputs  # Generate Riverpod code
dart run build_runner watch --delete-conflicting-outputs  # Watch mode for codegen
```

### Admin
```bash
cd apps/admin
yarn install                                 # Install dependencies
yarn dev                                     # Dev server (Next.js)
yarn build                                   # Production build
yarn lint                                    # ESLint
npx shadcn@latest add <component>            # Add shadcn component (new-york style)
```

### Website
```bash
cd apps/website
yarn install                                 # Install dependencies
yarn dev                                     # Dev server (Next.js)
yarn build                                   # Production build
yarn lint                                    # ESLint
npx shadcn@latest add <component>            # Add shadcn component (default style)
```

### Backend (Functions)
```bash
cd functions
yarn install                                 # Install dependencies
yarn build                                   # Compile TypeScript
yarn build:watch                             # Watch mode
```

---

## Mandatory Workflows

### Riverpod Codegen (Mobile)
After ANY change to `@riverpod`-annotated providers or classes:
```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```
Generated files (`*.g.dart`) must be committed alongside source changes.

### Translations (All Apps)
Every new user-facing string MUST have **both Arabic and English** translations:
- **Mobile:** Add to both `lib/i18n/en_translations.dart` and `lib/i18n/ar_translations.dart`
- **Admin:** Add to both `src/dictionaries/en.json` and `src/dictionaries/ar.json`
- **Website:** Add to both `src/app/dictionaries/en.json` and `src/app/dictionaries/ar.json`

### shadcn/ui Components
When adding new UI components to admin or website:
```bash
npx shadcn@latest add <component-name>
```
Do NOT manually create shadcn components. The CLI handles styling and dependencies.

### Native Changes Warning (Mobile)
When touching `android/` or `ios/` directories: **WARN the user** that Shorebird cannot OTA-update native changes. These require a full app store release.

### Platform Constraints (Mobile)
- Android minSdk must remain **>= 23** — never lower it
- Dart SDK must stay within `>=3.0.0 <=4.0.0`
- Verify any new dependency respects these constraints

---

## Git Strategy

### Branching
- Direct commits to `main` (no feature branches unless user requests)
- **Never force push**

### Commit Convention (STRICT)

Format: `type(scope): message`

**type:** `feat` | `fix` | `chore` | `refactor` | `style` | `docs` | `perf`

**scope:** `mobile` | `admin` | `website` | `backend` | `infra`

**message:** Max 10 words, lowercase, no period

Examples:
```
feat(mobile): add streak counter to home screen
fix(backend): handle null user in moderation function
chore(admin): upgrade shadcn button component
refactor(website): extract blog card into component
docs(infra): update claude.md with new patterns
```

### Commit Frequency (STRICT)
- Commit after **each small, atomic change**
- One logical change = one commit
- Never accumulate a large batch of work without committing
- Do not bundle unrelated changes in a single commit

---

## Package Managers

| App | Manager | Lockfile |
|-----|---------|----------|
| Mobile (Flutter) | `pub` | `pubspec.lock` |
| Functions | `yarn` | `yarn.lock` |
| Admin | `yarn` | `yarn.lock` |
| Website | `yarn` | `yarn.lock` |

**Never use `npm`** in this repo. Always use `yarn` for JS/TS projects and `pub` for Flutter.

---

## Known Tech Debt

1. **Firestore rules** — Rules file exists at root `firestore.rules` but may be outdated. Review before modifying.
2. **Tailwind version mismatch** — Admin uses Tailwind v4 (CSS-first), website uses Tailwind v3 (JS config). They are intentionally different; do not try to unify.
3. **Mixed lockfiles** — Admin has both `yarn.lock` and `package-lock.json`. Prefer `yarn.lock`; `package-lock.json` can be removed.
4. **Legacy app name** — The Flutter app is still named `reboot_app_3` internally. This is a known legacy artifact; do not rename without explicit approval.
5. **Duplicate setGlobalOptions** — `messageModeration.ts` calls `setGlobalOptions` with the same settings as `index.ts`. Harmless but could be cleaned up.

---

## Agent Team

| Agent | Scope (Write) | Scope (Read) | Purpose |
|-------|--------------|--------------|---------|
| `mobile-agent` | `apps/mobile/` | Entire repo | Flutter mobile app development |
| `admin-agent` | `apps/admin/` | Entire repo | Admin panel development |
| `website-agent` | `apps/website/` | Entire repo | Marketing website development |
| `backend-agent` | `functions/` | Entire repo | Cloud Functions development |
| `growth-agent` | Linear docs, planning files | Entire repo | Product strategy, behavioral psychology, feature specs |
| `team-lead` | None (coordination only) | Entire repo | Task delegation and cross-app coordination |

Agent definitions live in `.claude/agents/`. Each agent follows the HARD RULES above and the commit conventions.

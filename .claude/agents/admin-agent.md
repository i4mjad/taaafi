# Admin Agent

You are the **admin-agent** for the Ta'aafi monorepo. You develop the admin control panel.

## Scope

- **WRITE:** `apps/admin/`
- **READ:** Entire repository (for context, shared types, backend contracts)
- **NEVER WRITE:** `apps/mobile/`, `apps/website/`, `functions/`, root config files

## HARD RULES

Read and follow ALL hard rules in the root `CLAUDE.md`. Additionally:
- Use `npx shadcn@latest add <component>` to add new UI components — never create them manually
- shadcn style is **new-york** — do not change to default
- Always add both Arabic and English translations when adding user-facing strings
- Use `yarn` for all package management — never `npm`

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 15 (App Router) |
| React | v19 |
| TypeScript | 5.9 |
| Styling | Tailwind CSS **v4** (CSS-first, no JS config) |
| Components | shadcn/ui (**new-york** style), Lucide icons |
| Firebase | Client SDK v11 + Admin SDK v13 |
| Tables | TanStack React Table v8 |
| Charts | Recharts v3 |
| DnD | dnd-kit |
| Validation | Zod v3 |
| Dates | date-fns v4 |
| Notifications | Sonner |
| Theming | next-themes |

## Architecture

**Module-based with clean separation of concerns**

```
src/
├── app/
│   ├── [lang]/                  # i18n routing segment
│   │   ├── dashboard/           # Main dashboard
│   │   ├── user-management/     # Users, referrals, reports, settings
│   │   ├── community/           # Forum, groups, DMs
│   │   ├── groups-management/   # Group administration
│   │   ├── content/             # Content management
│   │   └── features/            # Feature flags / app features
│   └── api/                     # API routes (admin, fcm)
├── auth/                        # AuthProvider
├── components/
│   └── ui/                      # shadcn/ui components
├── contexts/                    # TranslationContext
├── dictionaries/                # ar.json, en.json
├── hooks/                       # Custom hooks
├── lib/                         # Firebase client, dictionary loader, utils
├── modules/                     # Feature modules (each has pages/)
│   ├── community/
│   ├── content/
│   ├── features/
│   ├── groups/
│   ├── groups-management/
│   └── user_management/         # Includes repositories (Firebase + InMemory)
├── repositories/                # Shared repositories
├── services/                    # AuthService
├── types/                       # Shared TypeScript types
└── utils/                       # Shared utilities
```

## i18n

- **Dictionary files:** `src/dictionaries/ar.json` and `src/dictionaries/en.json`
- **Config:** `i18n.config.ts` — `defaultLocale: "ar"`, `locales: ["en", "ar"]`
- **Middleware:** `middleware.ts` — browser language detection via `@formatjs/intl-localematcher` + `negotiator`, redirects to `/{locale}/dashboard`
- **Routing:** `[lang]` dynamic segment in App Router
- **Context:** `TranslationContext.tsx` for client components
- **Default locale:** Arabic (`ar`)

When adding strings, always update **both** `ar.json` and `en.json`. Maintain the same nested key structure.

## RTL Support

Arabic is the default locale. The root layout sets `lang="ar"` and the app supports RTL. When building layouts:
- Use logical CSS properties (`ms-`, `me-`, `ps-`, `pe-`) over `ml-`/`mr-`/`pl-`/`pr-`
- Test both Arabic and English layouts

## shadcn/ui

- **Style:** `new-york`
- **Base color:** `neutral`
- **CSS variables:** enabled
- **Icon library:** Lucide
- **Tailwind:** v4 CSS-first (no `tailwind.config.ts` content paths needed)

To add a component:
```bash
cd apps/admin && npx shadcn@latest add <component-name>
```

## Key Files

| File | Purpose |
|------|---------|
| `src/app/layout.tsx` | Root layout (lang, fonts) |
| `src/app/[lang]/layout.tsx` | Locale layout |
| `src/lib/firebase.ts` | Firebase client initialization |
| `src/lib/dictionary.ts` | Dictionary loader |
| `src/lib/utils.ts` | cn() utility |
| `src/auth/AuthProvider.tsx` | Auth context provider |
| `src/contexts/TranslationContext.tsx` | Translation context |
| `middleware.ts` | i18n middleware |
| `i18n.config.ts` | Locale configuration |
| `components.json` | shadcn/ui configuration |

## Commit Convention

Follow the root `CLAUDE.md` commit convention. Always use scope `admin`:
```
feat(admin): add user deletion request table
fix(admin): correct rtl layout in group details
chore(admin): upgrade tanstack table to v8.21
```
Commit after each small, atomic change. Never batch unrelated changes.

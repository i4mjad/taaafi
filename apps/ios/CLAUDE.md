# Ta'aafi iOS — CLAUDE.md

> This file covers the native iOS app at `apps/ios/`. For monorepo-wide rules, see the root [`/CLAUDE.md`](../../CLAUDE.md).

---

## Hard Rules

All [root CLAUDE.md hard rules](../../CLAUDE.md) apply, plus:

1. **Never modify Xcode signing or team settings** — Team ID, provisioning profiles, and code signing are configured; do not change them.
2. **Never change bundle identifiers** — `com.amjadkhalfan.RebootApp.Dev` is the sole bundle ID.
3. **Never modify entitlements without asking** — `ios.entitlements`, `DeviceActivityReport.entitlements`, and `DeviceActivityMonitor.entitlements` are protected.
4. **Never commit `GoogleService-Info.plist` or API keys** — These are git-ignored for a reason.
5. **Never lower deployment target below iOS 17** — The app relies on iOS 17+ APIs (`@Observable`, `DeviceActivityReport`, Swift Charts).

---

## Project Structure

```
apps/ios/
├── ios/                              # Main app target
│   ├── iosApp.swift                  # @main entry point
│   ├── MainTabView.swift             # 5-tab navigation (Guard is only active tab)
│   ├── Features/
│   │   └── Guard/
│   │       ├── GuardScreen.swift           # Screen Time report UI + date picker
│   │       ├── GuardSettingsScreen.swift    # Category classification settings
│   │       ├── ScreenTimeManager.swift     # @Observable auth + monitoring manager
│   │       └── CategoryClassification.swift # Category-to-threat mapping
│   └── Resources/
│       ├── Assets.xcassets/          # Colors and image assets
│       └── AppIconDev.icon/          # App icon (SVG-based)
├── DeviceActivityReport/             # ExtensionKit UI extension
│   ├── DeviceActivityReport.swift    # Extension entry point
│   ├── TotalActivityReport.swift     # Data processing scene
│   ├── TotalActivityView.swift       # Report UI (hero, chart, app list)
│   ├── ActivityReport.swift          # Data models
│   ├── CategoryClassification.swift  # Duplicate of main app (separate compilation unit)
│   ├── DeviceActivityReport.entitlements
│   └── Info.plist
├── DeviceActivityMonitor/            # Device activity monitor extension (stub)
│   ├── DeviceActivityMonitorExtension.swift
│   ├── DeviceActivityMonitor.entitlements
│   └── Info.plist
└── ios.xcodeproj/                    # Xcode project
```

---

## App Configuration

| Aspect | Detail |
|--------|--------|
| Framework | SwiftUI (iOS 17+) |
| State management | `@Observable` macro |
| Navigation | `NavigationStack` + `TabView` |
| Bundle ID | `com.amjadkhalfan.RebootApp.Dev` |
| Display name | Ta'aafi Dev |
| Team ID | JA8SVE4GX4 |
| App Group | `group.com.taaafi.app` |
| i18n | String Catalogs (`.xcstrings`), Arabic default |
| CI | Xcode Cloud |
| Extensions | DeviceActivityReport, DeviceActivityMonitor |
| External dependencies | None (no SPM packages yet) |

---

## Architecture

### Pattern: MVVM + Feature-First

Each feature lives under `Features/<Name>/` with this structure:

```
Features/<Name>/
├── Views/        # SwiftUI views
├── ViewModels/   # @Observable classes
├── Models/       # Data types
└── Services/     # Business logic, network, persistence
```

### State Management

| Decorator | Use Case |
|-----------|----------|
| `@State` | Local view state |
| `@Observable` | ViewModels and shared managers |
| `@Environment` | Dependency injection of `@Observable` objects |
| `@Binding` | Parent-to-child two-way binding |

### Navigation

- `NavigationStack` with `navigationDestination(for:)` for type-safe routing
- **Never** use the deprecated `NavigationView`
- `TabView` with `Tab` initializer (iOS 18+)

### Data Sharing Between App and Extensions

Extensions cannot use `@Observable`. Use App Group `UserDefaults` for cross-process data:

```swift
UserDefaults(suiteName: "group.com.taaafi.app")
```

---

## SwiftUI Code Standards

### Views
- Use `struct` for all views — keep them small and focused
- Use `#Preview` macro (not `PreviewProvider`)
- Use `.task {}` for async work (not `onAppear` + `Task`)
- Modifier order matters: padding before background
- Use `LazyVStack` / `LazyHStack` for scrollable lists
- Create `ViewModifier` for reusable styling patterns

### ViewModels
- Annotate with `@Observable` and `@MainActor`
- Inject via `.environment()` in parent, access with `@Environment` in child

### Accessibility
- Accessibility labels on all interactive elements
- Support Dynamic Type — use `.font(.body)`, not fixed sizes
- Respect `accessibilityReduceMotion` for animations
- Use stable `Identifiable` conformance in `ForEach`

### Performance
- Use `LazyVStack` / `LazyHStack` in `ScrollView` for long lists
- Avoid heavy computation in `body` — move to ViewModel
- Use `Equatable` conformance where beneficial for diffing

---

## Spacing System

4pt baseline grid used across all views:

| Token | Value |
|-------|-------|
| `xxs` | 4 |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 16 |
| `lg` | 20 |
| `xl` | 24 |
| `xxl` | 32 |

---

## Commands Reference

```bash
# Open in Xcode
open apps/ios/ios.xcodeproj

# Build from command line
cd apps/ios && xcodebuild -project ios.xcodeproj -scheme ios \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build folder
cd apps/ios && xcodebuild -project ios.xcodeproj -scheme ios clean
```

---

## Mandatory Workflows

### Translations
Every user-facing string must have **both Arabic and English** translations in the String Catalog. Arabic is the default locale, hardcoded in `iosApp.swift`:

```swift
.environment(\.locale, Locale(identifier: "ar"))
```

### CategoryClassification Sync
`CategoryClassification.swift` exists in **two separate compilation units** (main app and DeviceActivityReport extension). Any change to category logic **must be mirrored in both copies**:
- `ios/Features/Guard/CategoryClassification.swift`
- `DeviceActivityReport/CategoryClassification.swift`

### Entitlements
All three targets share identical entitlements (Family Controls + App Groups). **Never modify entitlements without explicit user approval.**

### Adding SPM Packages
Add Swift Package dependencies via Xcode UI or by editing `Package.resolved`. Never manually edit the `.pbxproj` for package references.

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | PascalCase | `GuardScreen.swift` |
| Types (struct/class/enum) | PascalCase | `ScreenTimeManager` |
| Properties / methods | camelCase | `selectedDate`, `requestAuthorization()` |
| Feature folders | PascalCase | `Features/Guard/` |
| Full-screen views | `*Screen` suffix | `GuardScreen` |
| Component views | `*View` suffix | `TotalActivityView` |
| ViewModels / Managers | `*ViewModel` or `*Manager` | `ScreenTimeManager` |

---

## Git Conventions

Follows root CLAUDE.md commit format with `ios` scope:

```
feat(ios): add login screen
fix(ios): handle nil user in auth service
chore(ios): add firebase sdk via spm
refactor(ios): extract chart into reusable component
```

Commit after each small, atomic change. One logical change = one commit.

---

## Known Constraints

1. **Duplicate `CategoryClassification.swift`** — The main app and DeviceActivityReport extension each have their own copy because extensions are separate compilation units. Keep them in sync manually.
2. **Extensions cannot use `@Observable`** — Cross-process state sharing must go through App Group `UserDefaults`.
3. **Arabic locale hardcoded** — Set in `iosApp.swift` via `.environment(\.locale, ...)`. Users cannot change locale at runtime yet.
4. **No Firebase SDK yet** — Firebase integration is planned for an upcoming phase.
5. **DeviceActivityMonitor is a stub** — All lifecycle methods call `super` with no custom logic.
6. **Only Guard tab is implemented** — Home, Vault, Community, and Account tabs show placeholder text.

---

## Migration Reference

This iOS app is being built phase-by-phase as a native replacement for the Flutter app at `apps/mobile/`. The migration is tracked in Linear as **AMJ-123**. Each phase adds features from the Flutter source, adapted to native SwiftUI patterns.

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
│   ├── Core/                         # Shared services, models, security
│   │   ├── Auth/                     # AuthService, AuthModels
│   │   ├── Firestore/                # FirestoreService
│   │   ├── Models/                   # Ban, Warning, AppFeature
│   │   ├── Network/                  # CloudFunctionsService, StorageService
│   │   ├── Security/                 # BanWarningFacade, RouteSecurityService, StartupSecurityService
│   │   ├── Services/                 # AnalyticsFacade, ErrorLogger, DeviceTrackingService
│   │   └── Theme/                    # Spacing, AppFont, AppColors, Typography, Strings
│   ├── Features/
│   │   └── Guard/
│   │       ├── GuardScreen.swift           # Screen Time report UI + date picker
│   │       ├── GuardSettingsScreen.swift    # Category classification settings
│   │       ├── ScreenTimeManager.swift     # @Observable auth + monitoring manager
│   │       └── CategoryClassification.swift # Category-to-threat mapping
│   ├── Localizable.xcstrings          # String Catalog (ar source + en)
│   └── Resources/
│       ├── Assets.xcassets/          # Colors and image assets
│       │   └── Colors/              # 8 color families, light/dark adaptive
│       ├── Fonts/                    # ExpoArabic font files
│       └── AppIconDev.icon/          # App icon (SVG-based)
├── iosTests/                         # Unit tests (Swift Testing framework)
│   └── Core/                         # Mirrors main target Core/ structure
│       ├── Auth/                     # AuthModelsTests
│       ├── Models/                   # BanTests, AppFeatureTests
│       ├── Security/                 # SecurityResultTests, RouteSecurityServiceTests, etc.
│       ├── Services/                 # AnalyticsFacadeTests, mocks
│       └── Theme/                    # SpacingTests, AppFontTests, AppColorsTests, TypographyTests, StringsTests
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
| Testing | Swift Testing framework (`@Test`, `#expect`, `@Suite`) |
| External dependencies | Firebase SDK, GoogleSignIn, RevenueCat (SPM) |
| Font | ExpoArabic (Light, Book, Medium, SemiBold, Bold) |

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

## Theming System

All theming primitives live in `ios/Core/Theme/`. Use these instead of hardcoded values.

### Spacing (`Spacing.swift`)

4pt baseline grid. Use `Spacing.*` for all padding, spacing, and layout values:

| Token | Value |
|-------|-------|
| `Spacing.xxs` | 4 |
| `Spacing.xs` | 8 |
| `Spacing.sm` | 12 |
| `Spacing.md` | 16 |
| `Spacing.lg` | 20 |
| `Spacing.xl` | 24 |
| `Spacing.xxl` | 32 |

### Colors (`AppColors.swift` + Asset Catalog)

Colors are defined as **Asset Catalog color sets** in `Resources/Assets.xcassets/Colors/` with light/dark appearances. `AppColors` provides type-safe access:

```swift
AppColors.primary      // primary500 alias
AppColors.primary500   // specific shade
AppColors.error        // error500 alias
AppColors.background   // adaptive background
AppColors.grey500      // neutral text
```

**8 color families:** `primary`, `secondary`, `tint`, `success`, `warning`, `error`, `grey`, `background`
**10 shades per family:** `50`, `100`, `200`, `300`, `400`, `500`, `600`, `700`, `800`, `900`
**Semantic aliases:** `primary`, `secondary`, `success`, `warning`, `error` → `*500`

To add a new color: create a `.colorset` in `Assets.xcassets/Colors/` with light + dark appearances, then add a `static let` in `AppColors.swift`.

### Fonts (`AppFont.swift`)

**ExpoArabic** is the app font (matching the Flutter mobile app). Font files are in `Resources/Fonts/`. Registered via `Info.plist` `UIAppFonts` array.

Use `AppFont.custom(size:weight:)` for SwiftUI views:

| `AppFontWeight` | ExpoArabic File |
|-----------------|-----------------|
| `.thin` | Light (fallback) |
| `.extraLight` | Light (fallback) |
| `.light` | Light |
| `.regular` | Book |
| `.book` | Medium |
| `.medium` | SemiBold |
| `.semiBold` | Bold |
| `.bold` | Bold (capped) |

### Native UI Element Fonts (`AppAppearance.swift`)

Native UIKit elements (nav bar, tab bar) are overridden via `UIAppearance` APIs in `AppAppearance.configure()`, called in `iosApp.init()` before `FirebaseApp.configure()`.

`AppAppearance` is `@MainActor` — `UIAppearance` proxies must run on the main thread.

| Element | Size | Weight |
|---------|------|--------|
| Nav bar large title | 34pt | `.regular` (ExpoArabic-Book) |
| Nav bar inline title | 17pt | `.medium` (ExpoArabic-SemiBold) |
| Back button text | 17pt | `.regular` (ExpoArabic-Book) |
| Tab bar label | 10pt | `.regular` (ExpoArabic-Book) |

Do **not** use SwiftUI `.font()` modifiers to style these elements — the appearance proxy handles them globally.

### Typography (`Typography.swift`)

Named text styles using `AppFont`. Use `Typography.*` for all `.font()` modifiers:

| Style | Size | Weight |
|-------|------|--------|
| `Typography.h1` | 40 | semiBold |
| `Typography.h2` | 30 | semiBold |
| `Typography.h3` | 28 | semiBold |
| `Typography.h4` | 24 | semiBold |
| `Typography.h5` | 21 | semiBold |
| `Typography.h6` | 16 | semiBold |
| `Typography.bodyLarge` | 18 | book |
| `Typography.body` | 16 | book |
| `Typography.footnote` | 14 | book |
| `Typography.caption` | 13 | book |
| `Typography.small` | 12 | book |
| `Typography.bodyTiny` | 10 | medium |
| `Typography.screenHeading` | 28 | bold |

### Strings (`Strings.swift` + `Localizable.xcstrings`)

All user-facing strings are in the String Catalog (`Localizable.xcstrings`) with Arabic as source language. Access via `Strings.*`:

```swift
Strings.Tab.home          // "الرئيسية" / "Home"
Strings.Guard.title       // "الحارس" / "Guard"
Strings.Common.loading    // "جاري التحميل..." / "Loading..."
```

**Groups:** `Strings.Tab`, `Strings.Guard`, `Strings.Common`

To add a new string:
1. Add the key + translations to `Localizable.xcstrings`
2. Add a `static let` in the appropriate `Strings.*` group

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

## Test-Driven Development (STRICT)

**TDD is mandatory for all iOS development.** Every new feature, bug fix, and refactor must follow the Red-Green-Refactor cycle. This is non-negotiable.

### The Cycle

1. **Red** — Write a failing test FIRST that describes the expected behavior
2. **Green** — Write the minimum production code to make the test pass
3. **Refactor** — Clean up while keeping tests green

### Rules

1. **No production code without a failing test** — If there is no test demanding the code, do not write it.
2. **Test behavior, not implementation** — Tests describe WHAT the code does, not HOW it does it. Ask "what should happen when...?" not "does this function get called?".
3. **Tests are first-class citizens** — Test code gets the same care as production code. No sloppy test names, no copy-paste test bodies, no magic values without context.
4. **One logical assertion per test** — Each `@Test` function verifies one behavior. Multiple `#expect` calls are fine if they describe facets of the same behavior.
5. **Never chase coverage numbers** — 80% coverage of the wrong things is worse than 40% coverage of critical behavior. Test the logic that matters: state transitions, edge cases, error paths, business rules.
6. **Keep tests fast and isolated** — No Firebase, no network, no disk in unit tests. Use protocols + mocks to isolate the unit under test. Pure logic tests need zero mocks.

### What to Test

| Always test | Skip testing |
|-------------|-------------|
| Business logic and state transitions | SwiftUI view layout |
| Error handling and edge cases | Trivial getters/setters with no logic |
| Data transformations and parsing | Third-party library internals |
| Security checks and access control | Auto-generated code |
| Cache behavior (hit, miss, expiry) | One-line pass-through wrappers |

### Test Structure

```swift
import Testing
@testable import ios

@Suite("FeatureName")
struct FeatureNameTests {

    @Test("description of expected behavior")
    func behaviorUnderTest() {
        // Given — set up preconditions
        // When — perform the action
        // Then — assert the outcome with #expect
    }
}
```

### Mocking Strategy

- **Pure logic** (models, enums, helpers) — test directly, no mocks needed
- **Services with dependencies** — extract a protocol, inject a mock
- **Protocol naming** — `<TypeName>Protocol` (e.g., `BanWarningFacadeProtocol`)
- **Mock naming** — `Mock<TypeName>` (e.g., `MockBanWarningFacade`)
- **Mock location** — `iosTests/` mirroring the source structure

### Commands

```bash
# Run all tests
cd apps/ios && xcodebuild -project ios.xcodeproj -scheme ios \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run tests from Xcode
Cmd+U
```

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
3. **Arabic locale hardcoded** — Set in `iosApp.swift` via `.environment(\.locale, ...)`. String Catalog provides AR+EN translations but locale selection is not yet user-facing.
4. **DeviceActivityMonitor is a stub** — All lifecycle methods call `super` with no custom logic.
5. **Only Guard tab is implemented** — Home, Vault, Community, and Account tabs show placeholder text.

---

## Migration Reference

This iOS app is being built phase-by-phase as a native replacement for the Flutter app at `apps/mobile/`. The migration is tracked in Linear as **AMJ-123**. Each phase adds features from the Flutter source, adapted to native SwiftUI patterns.

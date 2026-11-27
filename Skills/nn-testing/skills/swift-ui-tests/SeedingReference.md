# Seeding Reference

This document describes patterns for setting up test data and configuration in UI tests. Seeding ensures each test starts with a known, deterministic state rather than depending on pre-existing data.

---

## Two-Tier Seeding Architecture

UI test seeding works at two levels:

### Tier 1: Environment Keys

Simple boolean flags passed via `app.launchEnvironment`. The app reads these at launch to toggle behavior.

**Use for:** Feature flags, disabling features (ads, onboarding, analytics), enabling test mode, skipping authentication flows.

```swift
// Define keys as an enum for type safety
public enum TestEnvKey: String {
    case skipOnboarding
    case disableAds
    case isGuestUser
    case mockMaintenance
    case enableBetaFeature
}

// In test setup
addKeyToENV(TestEnvKey.disableAds.rawValue)
addKeyToENV(TestEnvKey.skipOnboarding.rawValue)
app.launch()

// In the app's launch code
if ProcessInfo.containsKey(TestEnvKey.disableAds.rawValue) {
    adManager.disable()
}
```

### Tier 2: Typed Seed Configs

Structured `Codable` objects passed via `app.launchEnvironment` as JSON. The app decodes these to provision complex test data (database records, user profiles, relationships).

**Use for:** Pre-populating database state, configuring user profiles, setting up relationships between entities, controlling data-dependent behavior.

```swift
// Define a seed config matching what the app needs
public struct SeedConfig: Codable, Sendable {
    var userRole: UserRole = .standard
    var itemCount: Int = 3
    var isPremium: Bool = false
    var memberNames: [String]? = nil
}

// In tests — NnTestKit handles encoding and launch
launchSeeded(config: SeedConfig(userRole: .admin, itemCount: 5))
```

---

## NnTestKit Seeding Helpers

NnTestKit provides built-in infrastructure for Tier 2 seeding. See `NnTestKit/UITestApi.md` for full API details.

### Key Methods

| Method | What It Does |
|--------|-------------|
| `launchSeeded(config:envKeys:)` | Encodes config, generates unique `runId` + test email, launches app |
| `setSeedConfig(_:envKeys:)` | Same setup but does NOT launch (use when login flow owns the launch) |
| `mainUserEmail` | The generated test user email for this run |
| `seedEmail(for:)` | Expected email for additional seeded users |

### How It Works

1. `launchSeeded` generates a unique 8-char `runId` per test run
2. It creates a test user email: `tester+<runId>@uitest.local`
3. It JSON-encodes your `SeedConfig` and places it in `UITEST_SEED_CONFIG`
4. It calls `app.launch()`
5. The app reads `UITestSeedContext.fromEnvironment()` and runs a seeder before showing UI

### Combining Both Tiers

```swift
func launchWithFullConfig(config: SeedConfig = SeedConfig()) {
    launchSeeded(
        config: config,
        envKeys: [
            TestEnvKey.disableAds.rawValue,
            TestEnvKey.skipOnboarding.rawValue
        ]
    )
}
```

---

## App-Side Seeding

The app must cooperate with the seeding system. At launch, it checks for UI test mode and runs a seeder before rendering the main UI.

### Pattern

```swift
// In the app's bootstrap or root view
import NnTestVariables

if ProcessInfo.isUITesting,
   let seed = UITestSeedContext<SeedConfig>.fromEnvironment(SeedConfig.self) {
    // Provision test data using seed.config
    await seeder.run(
        runId: seed.runId,
        email: seed.userEmail,
        password: seed.userPassword,
        config: seed.config
    )
}
```

### Rules

- The seeder must complete before the app shows interactive UI
- Use `seed.runId` to namespace test data (prevents collision between parallel runs)
- Use `seed.userEmail` and `seed.userPassword` for the primary test user
- The seeder should be idempotent — running it twice with the same `runId` should not create duplicates

---

## Parallel Test Isolation (UserDefaults)

When UI tests run in parallel, Xcode clones the simulator for each test class. Each clone has its own filesystem — but if your app reads/writes a `UserDefaults` suite with a **fixed** suite name, state can still leak between launches:

- A clone may reuse a plist from a prior run if the new test's setup doesn't fully wipe it before seeding.
- A `removePersistentDomain` call in `init()` can race with another process accessing the same suite name.

`SwiftData` configured with `isStoredInMemoryOnly: true` is automatically per-process and does not need this treatment. `UserDefaults` suites with fixed names do.

### App-Side: Read a Suffix from Launch Environment

```swift
private let UI_TEST_DEFAULTS_SUITE = "uiTestingMyApp"
private let UI_TEST_DEFAULTS_SUFFIX_KEY = "UI_TEST_DEFAULTS_SUFFIX"

private extension UserDefaults {
    static var uiTestingSuite: UserDefaults {
        let suiteName: String
        if let suffix = ProcessInfo.processInfo.environment[UI_TEST_DEFAULTS_SUFFIX_KEY], !suffix.isEmpty {
            suiteName = "\(UI_TEST_DEFAULTS_SUITE).\(suffix)"
        } else {
            suiteName = UI_TEST_DEFAULTS_SUITE
        }
        guard let defaults = UserDefaults(suiteName: suiteName) else { return .standard }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.synchronize()
        return defaults
    }
}
```

When the env var is absent (e.g., running the app normally), the suite name falls back to the constant.

### Test-Side: Inject a UUID Per Test

```swift
@MainActor
final class MyFeatureUITests: BaseUITestCase {
    override func setUp() {
        super.setUp()
        app.launchEnvironment["UI_TEST_DEFAULTS_SUFFIX"] = UUID().uuidString
    }
}
```

The injection must run AFTER `super.setUp()` so `app` exists, and BEFORE `launchSeeded()` so the env var is present when the app launches.

### Rules

- Apply this pattern when the app uses a non-AppGroup, fixed-name `UserDefaults` suite that is wiped-and-reseeded at launch
- The suffix must be unique per test launch — `UUID().uuidString` is the simplest source
- Pair with `removePersistentDomain` inside the app-side suite getter so each suffix-specific suite starts empty
- Skip when the app uses only in-memory storage or AppGroup defaults isolated by simulator clone

---

## Environment Key Design

### Enum-Based Keys

Define environment keys as a `String`-backed enum to prevent typos and enable autocomplete:

```swift
public enum SharedTestVar: String {
    // Auth control
    case logout
    case isGuest
    
    // Feature flags
    case disableAds
    case enableBetaFeature
    case skipOnboarding
    
    // Test data injection
    case mockDeepLink
    case mockMaintenance
}
```

### App-Side Reading

```swift
// Check a boolean flag
if ProcessInfo.containsKey(SharedTestVar.disableAds.rawValue) {
    // Feature is disabled for testing
}

// Read a value (not just a boolean)
if let deepLinkJSON = ProcessInfo.processInfo.environment[SharedTestVar.mockDeepLink.rawValue] {
    // Parse and handle the mock deep link
}
```

### Passing Values (Not Just Booleans)

For environment keys that carry data (like a mock deep link JSON), pass the value directly:

```swift
// In the test
let inviteJSON = """
{"id": "abc123", "senderName": "Tester", "groupName": "Test Group"}
"""
addKeyToENV(SharedTestVar.mockDeepLink.rawValue, value: inviteJSON)
app.launch()
```

---

## Designing a SeedConfig

A good `SeedConfig` models **test scenarios**, not database schema. Parameters should represent meaningful test variations.

### Good Design

```swift
struct SeedConfig: Codable, Sendable {
    var userRole: UserRole = .standard     // What kind of user
    var itemCount: Int = 3                 // How many items to seed
    var isPremium: Bool = false            // Premium status
    var hasReachedLimit: Bool = false      // Edge case: at capacity
}
```

### Bad Design

```swift
struct SeedConfig: Codable, Sendable {
    var firestoreUserId: String            // Implementation detail
    var collectionPath: String             // Implementation detail
    var documentFields: [String: Any]      // Too low-level
}
```

### Rules

- Default values should represent the most common test scenario (the "happy path")
- Each parameter should correspond to a meaningful behavioral difference
- Use `Optional` for parameters that most tests don't need
- Keep the config flat when possible — avoid deep nesting

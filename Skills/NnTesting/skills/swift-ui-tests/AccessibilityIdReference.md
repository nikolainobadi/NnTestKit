# Accessibility Identifier Reference

This document describes how to organize accessibility identifiers for type-safe, maintainable UI test references. The pattern creates a single source of truth for IDs shared between production code and test code.

---

## Architecture

Accessibility identifiers live in **dedicated, lightweight modules** separate from both the production code and the test code. This separation keeps the ID definitions importable by both sides without pulling in unnecessary dependencies.

```
MyFeature/
├── Sources/
│   ├── MyFeature/              # Production code
│   └── MyFeatureAccessibility/ # Just the ID enums — no business logic
└── Tests/
    └── MyFeatureTests/         # Unit tests
    
MyAppUITests/                   # UI tests import MyFeatureAccessibility
```

The accessibility module contains only enum definitions. It has no dependencies on UIKit, SwiftUI, or business logic.

---

## Defining Accessibility IDs

Use `String`-backed enums, one per screen or logical area:

```swift
// In MyFeatureAccessibility module

public enum TaskListAccessibilityId: String {
    case addButton
    case filterToggle
    case taskRow
    case emptyStateLabel
}

public enum TaskDetailAccessibilityId: String {
    case nameField
    case saveButton
    case deleteButton
    case reminderToggle = "taskDetailReminderToggle"  // Custom raw value when needed for uniqueness
}
```

### Rules

- One enum per screen or feature area
- Use `String` raw values (auto-generated from case names by default)
- Provide explicit raw values only when the default would collide with another screen's IDs
- Keep enum cases descriptive: `addButton` not `btn1`
- The enum name follows the pattern: `<Screen>AccessibilityId`

---

## Production Code Integration

In SwiftUI views, apply accessibility identifiers using the enum's raw value:

```swift
import MyFeatureAccessibility

struct TaskListView: View {
    var body: some View {
        List {
            // ...
        }
        .toolbar {
            Button("Add") { /* ... */ }
                .accessibilityIdentifier(TaskListAccessibilityId.addButton.rawValue)
        }
    }
}
```

### With NnSwiftUIKit

Projects that depend on NnSwiftUIKit should prefer `.setOptionalAccessibiltyId(_:)` over SwiftUI's native modifier. It accepts an optional string and only attaches an identifier when one is provided — useful when the ID is computed and may be nil:

```swift
Button("Add") { /* ... */ }
    .setOptionalAccessibiltyId(TaskListAccessibilityId.addButton.rawValue)
```

If the project does not import NnSwiftUIKit, fall back to SwiftUI's `.accessibilityIdentifier(_:)`.

Some projects create a `View` extension for convenience:

```swift
extension View {
    func accessibilityIdentifier(_ id: TaskListAccessibilityId) -> some View {
        self.accessibilityIdentifier(id.rawValue)
    }
}
```

This keeps the production code type-safe — the compiler catches invalid IDs.

---

## Required Coverage: Every Tappable Element Needs Its Own ID

Every `Button`, nav-bar button, custom tap target, and other interactive control in production code **must** have a dedicated accessibility identifier. No exceptions for "obvious" labels like Save / Cancel / Done.

### Why

Duplicate visible labels are a top source of UI-test flakiness. A typical screen graph — Settings sheet → editor sheet → nested item-editor sheet — can stack three buttons all labelled "Save". Text-based XCUITest queries (`app.buttons["Save"]`, `tapButton("Save")`) become ambiguous: XCUITest either taps the wrong one or can't resolve which to tap, depending on which sheets are currently in the accessibility tree.

This is not a hypothetical. A real Settings flow once had a `tapButton("Save")` sequence that "worked" intermittently before nested sheets were added, then silently started tapping the *outer* sheet's Save once both inner and outer "Save" labels coexisted on screen. The test passed locally but failed under different timing. The fix was to give every Save and Cancel its own unique ID and stop matching by text.

### Practical Guidance

- Add the ID **at the same time** as the Button — never as a follow-up pass.
- Icon-only buttons (pencil, trash, gear, plus, chevron) need IDs **even more** urgently — they have no visible label fallback at all.
- When using `withNavBarButton` / similar wrappers, pass `accessibilityId:` explicitly; don't rely on the visible text propagating.
- Naming: scope the ID to the screen/sheet it lives in (e.g., `quickAmountsEditorSaveButton`, `amountEditorSaveButton`) so that the same conceptual action ("Save") on different surfaces gets distinct, greppable identifiers.

### Quick Check Before Shipping a View

For every interactive element in the view, ask: *if a test had to tap this, would it find it by ID alone, without relying on the visible label?* If the answer is "no" or "only if no other view has the same label", add an ID.

---

## Test Code Integration

NnTestKit helpers accept `String` parameters for accessibility IDs. Two styles are acceptable for bridging enum type safety into those string-based APIs — projects pick one and stay consistent.

### Style A: String Extension Helpers (concise)

```swift
// In the UI test target (e.g., Shared/AccessibilityExtensions.swift)

import MyFeatureAccessibility

extension String {
    static func taskListId(_ id: TaskListAccessibilityId) -> String {
        id.rawValue
    }

    static func taskDetailId(_ id: TaskDetailAccessibilityId) -> String {
        id.rawValue
    }
}
```

Usage:

```swift
tapButton(.taskListId(.addButton))
typeInField(fieldId: .taskDetailId(.nameField), text: "New Task")
waitForElement(app.switches, id: .taskDetailId(.reminderToggle))
elementAppeared(app.staticTexts, named: .taskListId(.emptyStateLabel))
```

**Tradeoff:** terse call sites; requires adding one extension method per accessibility enum.

### Style B: Direct `.rawValue` Usage (explicit)

```swift
tapButton(TaskListAccessibilityId.addButton.rawValue)
typeInField(fieldId: TaskDetailAccessibilityId.nameField.rawValue, text: "New Task")
waitForElement(app.switches, id: TaskDetailAccessibilityId.reminderToggle.rawValue)
```

**Tradeoff:** more verbose; no extension layer to maintain; greppable for the literal enum case name.

### Choosing

- Pick **Style A** when the test target has many accessibility enums and the extra `.someScreenId(_:)` boilerplate pays off across hundreds of call sites.
- Pick **Style B** when there are few enums, or when grep-ability matters more than concision.
- **Do not mix both styles within one test target** — pick one and apply consistently.

---

## Selection-State Queries

XCUITest treats a `Button` (or any composite element) as a single accessibility element — identifiers on its inner `Image` children (e.g., a "selected" checkmark) get absorbed and are invisible to tests. To expose selection state without inventing a separate ID per state, use `.accessibilityValue`:

```swift
ForEach(VolumeUnit.allCases, id: \.self) { unit in
    Button {
        selectedUnit = unit
    } label: {
        // ...row content with a conditional checkmark...
    }
    .accessibilityIdentifier(accessibilityId(for: unit).rawValue)
    .accessibilityValue(selectedUnit == unit ? "selected" : "")
}
```

Tests query the value alongside the identifier:

```swift
let mlOption = waitForElement(app.buttons, id: VolumeUnitAccessibilityId.optionMl.rawValue)
XCTAssertEqual(mlOption.value as? String, "selected")
```

### When to Use

- Radio-button / single-select rows where each option already has its own accessibility identifier
- Custom toggle states that aren't natively exposed via `XCUIElement.value`
- Any composite control where a "state" sub-element would be absorbed into its parent

### When Not to Use

- `Toggle` (`Switch`) — already exposes `.value` ("0" / "1") natively
- `Picker` selection — query the picker's own value
- `Stepper` / `Slider` — state is exposed natively

---

## Organizing Accessibility Modules

### Small Projects

A single shared accessibility module (e.g., `AccessibilityIdKit`) containing all screen enums:

```
AccessibilityIdKit/
├── TabBarAccessibilityId.swift
├── LoginAccessibilityId.swift
├── SettingsAccessibilityId.swift
└── TaskListAccessibilityId.swift
```

### Modular Projects

Each feature package has its own accessibility target:

```
MyFeaturePackage/
├── Sources/
│   ├── MyFeature/
│   └── MyFeatureAccessibility/   # Lightweight — just enums
```

This keeps accessibility IDs colocated with their feature while remaining independently importable.

### Rules

- Accessibility modules must have **zero business logic dependencies**
- They should be importable by both the production target and the UI test target
- Keep them as thin as possible — enums and nothing else
- When adding a new screen, add a new enum to the appropriate accessibility module

---

## Adding a New Screen's Accessibility IDs

When writing UI tests for a new screen:

1. **Check if an accessibility module exists** for the feature area
2. **Add a new enum** (or add cases to an existing one) in the accessibility module
3. **Add the `.accessibilityIdentifier()` calls** in the production SwiftUI view
4. **Add a `String` extension helper** in the UI test target's shared directory
5. **Use the type-safe helpers** in your test code

If no accessibility module exists yet, check how the project organizes its IDs before creating one — follow the existing pattern.

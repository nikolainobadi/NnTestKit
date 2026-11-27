# nn-ui-testing

Conventions for Swift UI tests (XCUITest), packaged as a Claude Code plugin. It contains one skill, `swift-ui-tests`, which sets up and writes UI test files built on NnTestKit's `BaseUITestCase`, and covers accessibility identifiers, seeding, and reusable helper patterns.

## Installation

```
/plugin install nn-ui-testing@<marketplace>
```

The plugin has no plugin dependencies. The project under test must depend on NnTestKit (`NnUITestHelpers`). If the `NnTesting` plugin is also installed, the skill uses its `NnTestKit` skill's `UITestApi.md` for API details. If it is not, the skill reads them from the project's existing UI tests and the resolved NnTestKit package source.

## Usage

Ask for the work in plain language, or invoke the skill directly with the feature or flow under test:

```
/nn-ui-testing:swift-ui-tests Settings
```

| Request | What happens |
| --- | --- |
| "Set up UI tests for the Settings screen" | Creates the UI test file in the existing UI test target, or lists the structural violations in an existing one. |
| "Write a UI test that logs in and checks the dashboard" | Adds UI test cases to an existing, structurally valid UI test file. |

If the feature or flow under test is not named, the skill asks for it before doing anything else.

## Files

All paths are relative to `skills/swift-ui-tests/`.

| File | Role |
| --- | --- |
| `SKILL.md` | Entry file: workflow routing and context files. |
| `Workflows/SetupUITestFile.md` | Creates or validates the structure of a UI test file. |
| `Workflows/WriteUITests.md` | Writes UI test cases into a structurally valid file. |
| `UITestStructuralReference.md` | Rules for imports, the test class, `setUp`, helpers, and file location. |
| `UITestWritingReference.md` | Rules for naming, test structure, assertions, isolation, and flakiness. |
| `AccessibilityIdReference.md` | How to define, apply, and reference accessibility identifiers. |
| `SeedingReference.md` | Environment keys, typed seed configs, and parallel test isolation. |
| `UITestHelperPatterns.md` | Reusable navigation, login, relaunch, CRUD, and verification helpers. |

## Maintenance

- NnTestKit API facts (signatures, parameters, behavior) belong in the `NnTestKit` skill's `UITestApi.md`, not here. This skill states conventions and points there for the API.
- Do not edit the `version` field in `.claude-plugin/plugin.json` by hand; the release tooling writes it.

# nn-testing

Library-neutral conventions for Swift unit tests, packaged as a Claude Code plugin. It contains one skill, `swift-unit-tests`, which sets up, writes, and revises unit test files that use Swift Testing (`import Testing`).

The conventions name no third-party helper library, so the plugin works in projects with or without NnTestKit.

## Installation

The plugin is published through the `nn-swift-skills` marketplace, pinned to an NnTestKit release tag:

```
/plugin marketplace add nikolainobadi/nn-swift-skills
/plugin install nn-testing@nn-swift-skills
```

The `nn-testing` marketplace entry is added with the first NnTestKit release that includes this plugin. Until that release, the install command above will not find it.

The plugin has no plugin dependencies. Projects that use NnTestKit can also install the `NnTesting` plugin. When its `NnTestKit` skill is available, `swift-unit-tests` uses it for NnTestKit leak-tracking details. When it is not, the skill reads those details from the project's existing tests and the resolved NnTestKit package source.

## Usage

Ask for the work in plain language, or invoke the skill directly with the type under test:

```
/nn-testing:swift-unit-tests MyFeatureManager
```

| Request | What happens |
| --- | --- |
| "Set up tests for MyFeatureManager" | Creates the test file in an existing test target, or lists the structural violations in an existing one. |
| "Write unit tests for NetworkClient" | Adds test cases to an existing, structurally valid test file. |
| "Refactor DailyCareCalculatorTests to follow the conventions" | Audits the file, applies the mechanical fixes, and proposes the judgment calls for confirmation. Behavior is preserved. |

If the type under test is not named, the skill asks for it before doing anything else.

## Limitations

- It does not write, set up, or revise unit tests for Views: types conforming to `SwiftUI.View`, `UIViewRepresentable`, or `UIViewControllerRepresentable`. ViewModels and similar types are in scope.
- It never creates a new test target folder. It places files inside one that already exists.
- UI tests are covered by the `swift-ui-tests` skill in the separate `nn-ui-testing` plugin, not here.

## Leak tracking

The conventions say when leak tracking is required and where it lives (`makeSUT`), but not which helper to call. When the test target depends on NnTestKit, the skill uses the `NnTestKit` skill from the `NnTesting` plugin for the import, annotation, and call form if it is installed. If it is not, the skill takes them from an existing leak-tracked test or the resolved package source. When it does not, the skill uses the project's own helper, and asks before adding leak tracking if there is none.

## Files

All paths are relative to `skills/swift-unit-tests/`.

| File | Role |
| --- | --- |
| `SKILL.md` | Entry file: the View exclusion, workflow routing, and the leak-tracking handoff. |
| `Workflows/SetupTestFile.md` | Creates or validates the structure of a test file. |
| `Workflows/WriteTests.md` | Writes test cases into a structurally valid file. |
| `Workflows/ReviseTestFile.md` | Brings an existing test file into compliance without changing what it asserts. |
| `StructuralReference.md` | Rules for imports, the test type, `makeSUT`, and leak tracking. |
| `TestWritingReference.md` | Rules for test descriptions, assertions, organization, and inputs. |
| `MockRules.md` | Rules for building, configuring, and sharing mocks. |
| `TestFileLocationRules.md` | Rules for where a new test file goes and what it is named. |
| `MakeSutExamples.md` | Illustrative `makeSUT` shapes. |
| `MockInvariantTest.md` | Example of the one test the setup workflow may generate. |

## Maintenance

- The skill lives in the NnTestKit repository and is the source of truth; installed copies are snapshots of a release tag. An edit reaches consumers when the next release moves the marketplace `ref`, not when it merges.
- `nnex ship package` writes the `version` field in `.claude-plugin/plugin.json` on every release. Do not edit it by hand.
- Keep this plugin free of NnTestKit APIs. A convention that names one belongs in the `NnTestKit` skill.

# Swift Unit Test File Location and Creation Rules
## Canonical Resource

This document defines the **canonical rules** for locating and creating Swift unit test files
when a test file does not already exist.

This resource is **model-agnostic** and is intended to be shared across AI models
(Claude, Codex, etc.).

This document defines **where** a test file must live and **how** its location is determined.
It does **not** define test structure, imports, or `makeSUT` behavior.

If a model cannot confidently determine a correct location using these rules,
it must stop and ask the user to specify the test target path.

---

## 1. Scope and Responsibility

This document governs only:

- Test target discovery
- Test folder selection
- Subfolder creation rules
- Test file naming
- Mandatory file creation behavior

This document does **not** govern:

- Swift test structure
- `makeSUT`
- Imports
- Test cases
- Mock design
- Leak tracking

Those concerns are defined elsewhere.

---

## 2. Test Target Folder Definition

A **test target folder** is an existing directory that contains Swift unit test files.

A folder qualifies as a test target folder if it contains one or more Swift files that:

- Import `Testing`
- Use `@testable import <ModuleName>`
- Follow Swift test file conventions

Common examples include (but are not limited to):

- `MyFeatureTests`
- `MyFeatureUnitTests`
- `Tests`
- `UnitTests`

Folder names are **not authoritative**.
Contents determine whether a folder is a test target.

---

## 3. Test Target Discovery Rules

When creating a test file:

1. The model must search for **existing test target folders**
2. The model must **not create a new test target folder**
3. The model must select an existing test target folder using the rules below

### Selection Priority

If multiple candidate test target folders exist:

1. Prefer the folder already containing tests for the same module
2. Prefer the folder whose files import the same `@testable` module
3. Prefer the folder whose name most closely matches the module name

If no confident choice can be made:
- Stop
- Ask the user to specify the correct test target path

The model must not guess.

---

## 4. Subfolder Creation Rules

Subfolders **may** be created **inside** an existing test target folder.

Allowed:
- Creating subfolders that match existing project organization
- Grouping tests by feature, domain, or layer

Not allowed:
- Creating a new root test target folder
- Creating a parallel test hierarchy
- Moving or restructuring existing test folders

The root test target folder must already exist.

---

## 5. Test File Naming Rules

Test files must be named using the following convention:

```
<TypeUnderTest>Tests.swift
```

Examples:
- `NetworkClient` → `NetworkClientTests.swift`
- `FeatureManager` → `FeatureManagerTests.swift`
- `AuthService` → `AuthServiceTests.swift`

Rules:
- Append `Tests` directly to the type name
- The type name portion must match the type under test exactly
- One test file per type under test
- Do not reuse or overload test files

---

## 6. File Existence Rules

Once the test target folder has been determined:

- The model must check whether the test file already exists
- The model must not create duplicate test files
- The model must not overwrite existing files unless explicitly instructed

---

## 7. Mandatory File Creation

If the test file does **not** exist:

- The model **must** create it
- File creation is mandatory, not optional
- The model must output a complete, save-ready Swift file
- The output must be suitable for immediate use as a file

The model must not:
- Defer file creation
- Describe what should be created without outputting it
- Ask follow-up questions after the location is resolved

---

## 8. Failure Conditions

The model must stop and ask the user for clarification if:

- No existing test target folder can be confidently identified
- Multiple folders exist and no clear choice can be made
- The module under test cannot be determined

The model must not guess in these situations.

---

## Authority and Precedence

- This document is authoritative for test file placement and creation
- It must be followed before applying any structural or semantic test rules
- Other documents may reference this resource but must not reinterpret it

If another resource conflicts with this document regarding file placement,
**this document wins**.

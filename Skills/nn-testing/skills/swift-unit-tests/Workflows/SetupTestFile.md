# SetupTestFile Workflow

You are setting up or validating the **structure** of a Swift unit test file for the provided type.

This workflow is **structural only**.

Do not:
- Write test cases
- Invent behavior
- Infer assertions
- Guess about the type under test or its dependencies
- Create new test target folders
- Create unit tests for SwiftUI Views

---

## Execution Order (Strict)

You must follow the steps below **in order**.
Do not skip steps.
Do not preload resources prematurely.

---

## Step 1: Identify What Is Being Tested

First, determine **what type or file is under test**.

This must come from:
- The explicit argument provided to the skill, **or**
- A direct clarification request to the user

### If the type under test is not known

- Stop immediately
- Ask the user which type or file is being tested
- Do not read any resources
- Do not locate files
- Do not apply any rules
- Do not make assumptions

Only proceed once the type under test is explicitly identified.

---

## Step 1a: View Exclusion Rule (Hard Stop)

Once the type under test is identified, you must determine whether it is a **View**.

### Detection Criteria

A type is a View if **any** of the following are true:

- The type conforms to `SwiftUI.View` (has a `body` property returning `some View`)
- The type conforms to `UIViewRepresentable` or `UIViewControllerRepresentable`
- The type imports `SwiftUI` and declares a `var body: some View` property
- The source file contains `import SwiftUI` and the type has `@ViewBuilder` annotations

A type is **not** a View if:

- It is a ViewModel, Store, Presenter, Reducer, or similar non-view type — even if its name contains "View" (e.g., `ProfileViewModel`)
- It does not conform to `View` or any SwiftUI representable protocol
- It only consumes view-related data without being a view itself

**The determining factor is protocol conformance, not naming convention.** Read the source file to verify conformance before deciding.

### If the type under test is a View

- Stop immediately
- Do **not** create a test file
- Do **not** validate or modify existing test files
- Inform the user that this skill does not create unit test files for Views
- Take no further action

This rule is non-negotiable.

---

## Step 2: Locate an Existing Test File

Once the type under test is confirmed **not** to be a View:

- Search for an existing test file corresponding to that type
- Prefer existing test folders and established structure
- Do **not** create new folders at this stage

### If a test file **exists**

- Use the existing file
- **Do not read** `TestFileLocationRules.md`
- Proceed directly to structural validation

---

## Step 3: Create the Test File (Only If Missing)

If **no existing test file is found**:

- Read `TestFileLocationRules.md`
- Use it to determine the **correct location** for the new test file
- You may create subfolders *inside* an existing test target if required
- You must **not** create a new test target folder

File creation is mandatory when the file does not exist.

---

## Step 4: Apply Structural Rules

Once the test file is located **or** created:

- Read `StructuralReference.md` before applying any structural rules
- Apply the canonical rules from `StructuralReference.md`

`StructuralReference.md` defines:
- Imports and ordering
- Test type selection
- `makeSUT` rules
- Mock construction rules
- Leak tracking requirements

If anything in this workflow conflicts with `StructuralReference.md`, `StructuralReference.md` wins.

---

## Your Task

Ensure the test file complies with all structural requirements defined in `StructuralReference.md`.

---

## Output Rules

### When the test file does not exist

- Output the **entire contents** of the new test file
- The output must be immediately savable
- Partial skeletons or placeholders are not allowed
- Do not include commentary

### When the test file exists

- Output **only actionable violations**
- Describe exactly what must change
- Do not rewrite the file unless explicitly asked

---

## Absolute Constraints

- Never write or suggest test cases
  - Exception: exactly one invariant test is allowed per `StructuralReference.md` section 5
  - See `MockInvariantTest.md` for an illustrative example

# ReviseTestFile Workflow

You are bringing an **existing** Swift unit test file into compliance with the canonical rules.

This workflow audits a test file that already exists, then revises it so its structure, test cases, and test doubles conform to the canonical references. It reformats and refactors **how tests are expressed** — it never changes **what they assert**.

This workflow must never create a new test file. If the file does not exist, route to `SetupTestFile` instead.

---

## Behavior Preservation (Hard Rule)

Revision changes form, never meaning. This rule outranks every fix below.

You must never:

- Change an expected value, comparison, or assertion semantics
- Remove a behavioral scenario or reduce coverage
- Add a new behavioral scenario (that is the `WriteTests` workflow's job)
- Alter production code under test
- Change what a test proves in order to make it "cleaner"

A revised file must exercise exactly the same behaviors, against the same inputs, expecting the same outcomes, as the original. If a rule cannot be satisfied without changing what a test proves, stop and ask.

The single permitted structural transformation that touches scenario count is consolidating duplicate tests into one argument-driven test — and only because it preserves coverage exactly. It is a judgment-call fix (see below), never mechanical.

---

## Preconditions

If no argument identifies the test file or type under test:

- Stop immediately
- Ask the user which test file is being revised
- Do not read any files
- Do not make assumptions

If the named test file does not exist:

- Stop immediately
- Tell the user the file does not exist
- Recommend the `SetupTestFile` workflow
- Do not create it here

---

## Canonical Rules

Revision spans structure, test writing, and test doubles. You must read **all three** canonical references before auditing or editing:

- `StructuralReference.md`
- `TestWritingReference.md`
- `MockRules.md`

This is mandatory, not conditional. Treat these documents as the single source of truth. Do not deviate, reinterpret, or weaken any rule. If this workflow conflicts with them, they win.

---

## Step 1: Audit

Read the existing test file in full. Check it against every rule category in the three references, and produce a categorized violation report. Each finding must cite the rule it violates and quote the offending code.

Then classify every finding into exactly one of two buckets.

### Bucket A — Mechanical (safe to autofix)

Deterministic, behavior-preserving transformations with no wording or design choice:

- `@Test("description")` string form → `@Test` on its own line above a backtick-escaped function name, reusing the existing description text verbatim **when it is already behavior-driven**
- `@Test func` inline → `@Test` on its own line
- `#expect(x == true)` → `#expect(x)`; `#expect(x == false)` → `#expect(!x)`
- Optional chaining or optional comparison inside `#expect(...)` → `try #require` unwrap into a named local, then assert on the local; add `throws` to the signature
- `_` tuple placeholders in `makeSUT()` bindings → bind only used elements via the tuple accessor (`let sut = makeSUT().sut`)
- Inline SUT/dependency/mock construction inside a test → routed through `makeSUT`
- A duplicated setup-and-assertion literal → a single named local referenced in both places (Input Identity)
- Import ordering and removal of unused imports
- `makeSUT` relocated to a bottom private extension labeled exactly `// MARK: - SUT`
- Leak-tracking call-site parameters reordered to be the final `makeSUT` parameters; `trackForMemoryLeaks(sut)` → the full call-site-forwarding form
- Comments inside test cases removed

### Bucket B — Judgment call (propose, then confirm)

Anything requiring a wording choice, a design decision, or a change that could ripple:

- Rewording a description that encodes implementation details, names the method under test, or describes how a result is produced
- Consolidating several tests into one argument-driven test (apply the Decision Heuristic in `TestWritingReference.md`)
- Splitting a multi-assertion test into separate single-behavior tests
- Mock redesign: consolidating multiple mocks into one `MockDelegate`, renaming mocks by role, converting public mutable state to `private(set)`, collapsing collection state to single-invocation semantics
- Removing a call-count assertion or any assertion the rules prohibit (call this out explicitly — it is a prohibited practice, but removing an assertion still requires confirmation)
- `struct` ↔ `final class` changes, and adding or removing leak tracking
- Converting MARK-only grouping into extensions when the group boundaries are not already obvious

If a finding is ambiguous between buckets, treat it as Bucket B.

---

## Step 2: Apply

Apply all **Bucket A** fixes directly, with surgical edits.

For **Bucket B**, do not edit yet. Present the findings grouped by rule, each as a concrete `before → after` proposal, and ask the user to confirm. Apply only the proposals the user approves. Leave the rest unchanged and note that they remain.

Every edit must be the smallest change that satisfies the rule. Do not reformat untouched code.

---

## Step 3: Verify

After editing, verify compilation before claiming the revision is done:

- Build the relevant test target (`xcodebuild build-for-testing` for the scheme that owns the file)
- Report the actual build result
- If the tests can be run, run them and confirm they still pass — a green build with the same passing tests is the proof that behavior was preserved

Never report success without a verified build. If the build fails, fix the regression introduced by the revision before reporting.

---

## Output Rules

- Edit the existing file in place; do not rewrite untouched sections
- Do not modify production code
- Do not add comments inside test cases
- Do not add helpers, mocks, or dependencies the tests do not already require
- Do not explain the tests themselves
- Report: the Bucket A fixes applied, the Bucket B proposals (approved and outstanding), and the build/test result

Be precise. Follow the rules exactly. Preserve behavior above all.

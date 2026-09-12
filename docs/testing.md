# Testing and Validation

## Purpose

This document defines the testing philosophy and validation policy for the standalone Neovim project.

It covers:

- what should and should not be tested;
- the purpose of the packaged smoke test;
- structural regression testing;
- stable/experimental state-isolation testing;
- flake checks;
- manual behavioral validation;
- test-impact assessment;
- the relationship between development-time checks and the promotion gate;
- expectations for AI-assisted changes.

## Related Documentation

- `docs/architecture.md` — architectural invariants that tests may protect.
- `docs/workflow.md` — development-time validation and promotion workflow.
- `docs/state-isolation.md` — mutable-state invariants covered by the isolation regression.
- `docs/references.md` — upstream repositories used when verifying APIs, packages, or technical behavior.

Repository and upstream technical references are maintained in `docs/references.md`.

---

# 1. Testing Philosophy

Testing is deliberately incremental.

The goal is **not** to turn the Neovim configuration into a large unit-test suite for every option, keybinding, or visual preference.

Tests should protect behavior that is:

* structurally important;
* integration-sensitive;
* easy to break without noticing;
* difficult to validate reliably by inspection alone;
* dangerous to production reliability if it regresses.

The preferred model is:

```text
meaningful invariant
        ↓
smallest useful regression test
```

not:

```text
configuration exists
        ↓
test every value
```

---

# 2. What Tests Should Protect

Good test targets include invariants such as:

```text
the editor package builds

Neovim starts successfully

the packaged Lua configuration finishes loading

the packaged configuration is actually on runtimepath

a required dependency is available

an important module initializes

a critical event callback executes without error

the declared production default can actually load

stable and experimental mutable state remain isolated

workflow tooling still builds
```

These failures may be difficult to detect from static inspection alone and may make the editor unusable or undermine an architectural guarantee.

---

# 3. What Tests Should Usually Not Protect

Avoid tests that merely freeze aesthetic or easily inspectable configuration choices.

Examples of poor default test targets include:

```text
scrolloff == 12

cursorline == true

exact colors used by a theme

exact leader-group display text

exact statusline formatting

exact icon glyphs

the precise order of cosmetic UI components
```

Such tests are often brittle and provide little protection against meaningful failures.

A setting being intentionally configured does not automatically justify an automated test.

---

# 4. Test Behavior, Not Incidental Implementation

Prefer testing the contract a feature must satisfy rather than the current implementation detail used to satisfy it.

For example, if the project declares a default colorscheme, the useful invariant is:

```text
the packaged default colorscheme successfully loads
```

rather than:

```text
the default must forever be Catppuccin Mocha
```

if the architecture intentionally permits replacing the default later.

Similarly:

```text
critical callback executes without error
```

is generally more useful than asserting the exact Lua function used internally.

Tests should make intended refactoring possible without unnecessary rewrites.

---

# 5. Validation Layers

The project uses several complementary forms of validation.

Conceptually:

```text
manual behavioral validation
        ↓
targeted regression tests
        ↓
packaged smoke test
        ↓
flake checks
        ↓
promotion gate
```

These layers are complementary.

They do not all need to be run manually after every individual edit.

---

# 6. Manual Behavioral Validation

Interactive behavior should be exercised using:

```bash
nvim-next
```

when the change is being developed in an experiment.

Examples:

```text
keymap change
→ invoke the actual mapping

autocmd change
→ trigger the actual event

theme change
→ launch and inspect the theme

Telescope change
→ open and use the affected picker

LSP change
→ open an appropriate project/buffer and exercise it

buffer-management change
→ create the relevant buffer/window situation and test it
```

Manual validation is especially important for:

* visual behavior;
* interaction ergonomics;
* keybinding behavior;
* workflow feel;
* UI layout;
* behavior difficult to reproduce reliably in headless testing.

Do not claim that a visual or interactive behavior was validated unless it was actually exercised.

---

# 7. Startup Success Is Not Enough

A successful Neovim startup proves only that startup-time code completed successfully.

It does not prove that later event-driven behavior works.

This distinction became important during the Stage 6 yank-highlight regression.

The configuration loaded successfully, but the `TextYankPost` callback used an API unavailable in the packaged Neovim version.

The failure appeared only when an operation such as:

```text
yy
```

or:

```text
dd
```

triggered the event.

The testing lesson is:

> If important behavior is event-driven, a useful regression test should trigger the event rather than merely verify startup.

---

# 8. Packaged Smoke Test

The durable packaged smoke test lives at:

```text
tests/smoke.sh
```

Its purpose is to answer a high-value question:

> Can the actual Nix-packaged production editor start and complete important initialization successfully in a clean environment?

This is more useful than testing only the writable development configuration.

The production package is the artifact that ultimately matters.

---

# 9. Configuration-Load Sentinel

The configuration exposes a load sentinel only after user configuration finishes loading.

Conceptually:

```lua
require("user")

vim.g.neovim_config_loaded = true
```

The ordering is intentional.

If configuration loading fails before completion:

```text
syntax error
    ↓
module error
    ↓
require("user") fails
    ↓
sentinel is never set
    ↓
smoke test fails
```

Therefore the sentinel represents:

```text
configuration completed loading
```

rather than merely:

```text
init.lua began executing
```

Do not move the sentinel earlier in startup in a way that weakens this guarantee.

---

# 10. Clean Smoke-Test Environment

The packaged smoke test should not depend on the user's normal Neovim state.

It runs with temporary:

```text
HOME
XDG_CONFIG_HOME
XDG_DATA_HOME
XDG_STATE_HOME
XDG_CACHE_HOME
```

directories.

This prevents personal state from accidentally making a broken package appear healthy.

The desired property is:

```text
packaged editor
+
clean temporary runtime environment
        ↓
successful startup
```

A smoke test that silently consumes normal user state is less trustworthy.

---

# 11. Smoke-Test Scope

The smoke test should remain relatively small.

Its job is not to exhaustively test every editor feature.

It should protect important packaged-startup and integration invariants such as:

```text
Neovim executable exists

packaged configuration loads

expected configuration runtime is present

critical required startup dependency is available

declared production defaults initialize correctly

selected high-value event callbacks do not crash
```

Feature-specific probes may be added when a regression would otherwise pass startup unnoticed and the probe remains inexpensive and reliable.

---

# 12. Event-Level Regression Coverage

The yank-highlight failure established the project's first clear event-level regression pattern.

The smoke test triggers actual yank/delete behavior so `TextYankPost` executes.

Conceptually:

```text
create test lines
        ↓
yy
        ↓
TextYankPost executes
        ↓
dd
        ↓
TextYankPost executes
        ↓
callback failure causes smoke failure
```

This pattern should be reused selectively.

Do not automatically trigger every autocmd in the configuration.

Add event-level coverage when:

* the event is important;
* the callback can fail after otherwise successful startup;
* the failure would be easy to miss;
* exercising the event is cheap and deterministic.

---

# 13. Default-vs-Optional Feature Testing

Some features may be optional at runtime while still being required as part of the declared production configuration.

For example:

```text
user temporarily requests unavailable theme
→ warn
→ keep editor usable
```

may be acceptable runtime behavior.

But:

```text
declared packaged production default cannot load
→ automated test failure
```

is the correct testing behavior.

This distinction follows the architectural principle of graceful degradation:

```text
optional request may fail gracefully

declared production baseline must work
```

Tests should preserve that distinction.

---

# 14. State-Isolation Regression

Stable and experimental editor state must remain separated.

The regression test is:

```text
tests/state-isolation.sh
```

It compares stable and experimental Neovim and verifies separation of important derived application paths.

The current protected categories include:

```text
NVIM_APPNAME

stdpath("config")

stdpath("data")

stdpath("state")

stdpath("cache")

ShaDa path
```

The experimental application identity must be:

```text
nvim-next
```

Detailed state ownership policy belongs in:

```text
docs/state-isolation.md
```

---

# 15. Future State-Related Tests

When persistent editor features are introduced, test coverage should be reassessed.

Examples include:

```text
sessions

persistent undo

plugin databases

indexes

histories

generated metadata

plugin-specific caches
```

If a new feature introduces mutable state that could contaminate stable production from the experimental editor, the state-isolation regression should be extended where practical.

The relevant question is not:

> Did we add a plugin?

It is:

> Did we introduce a new mutable-state path whose accidental sharing would violate the architecture?

---

# 16. Test the Observed System

Tests themselves can be wrong.

During development of the state-isolation regression, headless Neovim's `print()` output appeared on stderr rather than stdout.

The test initially captured only stdout and therefore incorrectly observed an empty application name.

The correction was to capture the actual process output appropriately.

The broader lesson is:

> When a test produces an unexpected result, understand the observed behavior before changing the production code to satisfy the test.

Do not patch implementation behavior merely to accommodate a faulty test harness.

---

# 17. Flake Checks

Nix exposes durable repository checks through:

```text
nix/checks.nix
```

The flake-check layer protects packaged/infrastructure behavior rather than interactive editor ergonomics.

Important checks include the packaged smoke check and successful construction of workflow tooling.

The broad repository command is:

```bash
nix flake check path:. --print-build-logs
```

This evaluates/builds the flake checks for the candidate revision.

---

# 18. `nix flake check` Is Not the Inner Development Loop

A complete:

```bash
nix flake check path:. --print-build-logs
```

can be useful during development, especially when:

* changing Nix packaging;
* adding dependencies;
* changing flake outputs;
* modifying checks;
* debugging a promotion failure;
* changing workflow infrastructure.

It is **not** required after every Lua edit.

For a small Lua-only iteration:

```text
edit
    ↓
restart nvim-next
    ↓
exercise behavior
```

is normally the appropriate immediate loop.

Use the narrowest validation that provides useful feedback during development.

---

# 19. Promotion Gate

The authoritative experiment-to-source-stable workflow is:

```bash
nvim-exp promote
```

The promotion gate includes validation before `main` is advanced.

Its important validation sequence includes:

```text
candidate experiment is valid/clean
        ↓
nix flake check candidate
        ↓
build candidate #nvim
        ↓
run stable-vs-experimental state-isolation regression
        ↓
only then fast-forward main
```

Therefore some broad validation is already enforced at promotion time.

This is why routine development should not mechanically duplicate the entire promotion gate after every small change.

---

# 20. Promotion Checks Are a Floor, Not a Ceiling

The promotion gate protects established project-wide invariants.

A specific feature may still require additional validation.

For example:

```text
new event-driven behavior
→ targeted regression test may be needed

new stateful plugin
→ state-isolation coverage may need extension

new required dependency
→ packaged availability may need a smoke assertion

new complex visual interaction
→ manual validation may remain necessary
```

The existence of a promotion gate does not eliminate feature-specific reasoning.

---

# 21. Test-Impact Assessment

Starting with Stage 6, every meaningful implementation stage or feature should explicitly assess testing impact.

Use these questions:

```text
1. What new failure could this change introduce?

2. Would that failure be dangerous, subtle, or easy to miss?

3. Does an existing test already catch it?

4. If not, what is the cheapest reliable regression test?

5. Would the proposed test protect behavior or merely freeze implementation/cosmetics?
```

Possible outcomes include:

```text
existing coverage is sufficient

manual validation is sufficient

extend an existing test

add a new targeted regression test
```

"Add no test" is a valid conclusion when justified.

---

# 22. When to Add a Regression Test

A new or expanded automated test is especially justified when the failure:

* previously occurred;
* can break production startup;
* violates an architectural invariant;
* appears only after a delayed event;
* depends on packaging rather than source-tree behavior;
* can silently contaminate stable state;
* is likely to recur;
* can be tested cheaply and deterministically.

The ideal regression test demonstrates the failure mode directly.

---

# 23. When Not to Add a Regression Test

Do not add a test simply because implementation changed.

A new test is usually unnecessary when:

* the behavior is purely cosmetic;
* the behavior is trivial to inspect;
* existing coverage already catches the meaningful failure;
* reliable automation would be much more complex than the protected behavior;
* the test would encode private plugin internals rather than user-facing/project invariants;
* the assertion would make reasonable refactoring unnecessarily difficult.

Avoid test growth for its own sake.

---

# 24. Extend Existing Tests Before Creating New Suites

Prefer extending an existing test when the new invariant naturally belongs there.

Examples:

```text
another critical packaged-startup invariant
→ tests/smoke.sh

another stable/experimental state path
→ tests/state-isolation.sh
```

Create a separate test only when the concern is sufficiently distinct that adding it to an existing test would make that test confusing, slow, or conceptually incoherent.

The test tree should remain understandable.

---

# 25. Keep Tests Deterministic

Regression tests should avoid unnecessary dependence on:

* the user's personal HOME;
* existing Neovim state;
* external mutable files;
* network access when not inherently required;
* timing-sensitive UI behavior;
* environment-specific accidental state.

Prefer:

```text
temporary directories

headless execution

explicit environment variables

packaged dependencies

observable exit status

clear failure messages
```

Deterministic tests are more valuable than broad but flaky tests.

---

# 26. Keep Tests Cheap Where Possible

Startup and promotion checks should remain inexpensive enough to run routinely.

Do not introduce heavyweight integration infrastructure for a failure that can be protected by a small shell/Lua probe.

Preferred order:

```text
simple assertion
    ↓
headless Neovim probe
    ↓
small shell regression
    ↓
larger integration machinery only when justified
```

Complexity in the test suite must justify itself just like complexity in the editor.

---

# 27. Test Against the Packaged Neovim Version

Native API behavior must be validated against the Neovim version actually supplied by the project.

Do not assume that documentation from Neovim `master` reflects the packaged stable version.

The yank-highlight regression demonstrated why this matters.

The safe sequence is:

```text
identify packaged Neovim version
        ↓
verify API compatibility
        ↓
implement
        ↓
exercise relevant behavior
```

Where practical, packaged smoke testing should catch incompatible startup or event behavior.

---

# 28. Required Dependencies vs Graceful Degradation

Testing should distinguish required baseline dependencies from optional capabilities.

If something is required for the declared production configuration:

```text
missing required dependency
→ test failure
```

If something is intentionally optional:

```text
missing optional dependency
→ feature disables/warns gracefully
→ editor remains usable
```

A test should not accidentally turn an intentionally optional capability into a hard startup dependency.

Likewise, graceful-degradation behavior should not hide a broken declared production baseline.

---

# 29. Manual and Automated Testing Have Different Jobs

Automated tests are strongest at protecting:

```text
startup

packaging

module availability

state separation

event callbacks

structural invariants

known regressions
```

Manual validation is strongest at assessing:

```text
visual correctness

editing feel

navigation ergonomics

discoverability

interactive workflows

whether the feature actually solves the intended problem
```

Neither replaces the other.

---

# 30. AI-Agent Testing Expectations

An AI agent implementing a task must perform a test-impact assessment rather than automatically generating tests.

The agent should:

```text
inspect existing coverage
        ↓
identify the new failure mode
        ↓
determine whether existing tests cover it
        ↓
add/update tests only when useful
        ↓
run relevant validation
        ↓
report exactly what was and was not validated
```

The agent should not:

* add cosmetic assertions merely to increase coverage;
* claim manual UI verification it did not perform;
* run expensive broad checks repeatedly without reason;
* delete or weaken an invariant test merely to make a change pass;
* modify production behavior to satisfy a misunderstood test without investigating the test.

---

# 31. Reporting Test Results

When completing an implementation task, the validation report should state:

```text
what was tested

which commands/checks were run

whether they passed

what was validated manually

whether tests were added or changed

why no new test was needed, when applicable

anything that remains unverified
```

Avoid vague statements such as:

```text
tests look good
```

Prefer concrete statements such as:

```text
nvim-next startup exercised successfully

TextYankPost behavior was manually triggered

existing smoke coverage already exercises this callback

no new regression test was required
```

or:

```text
added a smoke assertion because the new required plugin could
otherwise be absent from the packaged editor while Lua remained valid
```

---

# 32. Test Maintenance

Tests are part of the architecture and should evolve when the protected contract evolves.

If an architectural invariant intentionally changes:

```text
change architecture
        ↓
update documentation
        ↓
update affected tests
```

Do not preserve an obsolete test merely because it already exists.

Conversely, implementation refactoring should not weaken a still-valid invariant.

The test should follow the contract, not incidental historical code.

---

# 33. Current Testing Model

The project currently has three principal automated validation layers:

```text
tests/smoke.sh
→ packaged Neovim startup/integration regression

tests/state-isolation.sh
→ stable/experimental mutable-state separation

nix/checks.nix
→ flake-visible packaged checks and workflow-tool build validation
```

These are supplemented by:

```text
manual nvim-next validation
```

during experimentation and by:

```text
nvim-exp promote
```

as the enforced source-promotion gate.

Future tests should be added incrementally rather than creating a large speculative suite in advance.

---

# 34. Testing Invariants

The following testing rules should remain true unless deliberately revised.

1. Tests protect meaningful behavior and architecture, not every preference.

2. Packaged production behavior matters more than source-only success.

3. Smoke testing uses an isolated temporary runtime environment.

4. Configuration-load success is asserted only after user configuration completes.

5. Important event-driven behavior may require triggering the actual event.

6. Stable/experimental mutable-state separation remains regression-tested.

7. Test harness behavior must be understood before changing production code to satisfy it.

8. Every meaningful feature receives a test-impact assessment.

9. Existing coverage should be reused when it already protects the new failure mode.

10. New tests should be the cheapest reliable protection for meaningful regressions.

11. Cosmetic and implementation-specific assertions should generally be avoided.

12. Broad flake checks are available but are not the inner loop for every Lua edit.

13. The promotion gate enforces broad candidate validation before source stable advances.

14. Manual interactive validation remains necessary for behavior that automation cannot meaningfully judge.

15. Agents must accurately report what was actually validated.

---

# 35. One-Screen Testing Model

```text
                       CHANGE
                          │
                          ▼
                identify failure mode
                          │
                          ▼
             does existing coverage catch it?
                   ┌──────┴──────┐
                   │             │
                  yes            no
                   │             │
                   │        is regression
                   │        coverage useful?
                   │          ┌──┴──┐
                   │          │     │
                   │         yes    no
                   │          │     │
                   │      add the   rely on
                   │      smallest  appropriate
                   │      useful    manual/existing
                   │      test      validation
                   └──────┬──────┘
                          │
                          ▼
                    test / validate
                          │
                          ▼
                    inspect results
                          │
                          ▼
                    promotion gate
                          │
                          ▼
                    source stable
```

---

# 36. Governing Principle

The test suite exists to make important failures difficult to reintroduce without turning the configuration into a brittle specification of every implementation detail.

The concise model is:

```text
TEST INVARIANTS.
TRIGGER REAL FAILURE MODES.
KEEP TESTS SMALL.
DO NOT TEST COSMETICS.
VALIDATE WHAT AUTOMATION CANNOT.
```


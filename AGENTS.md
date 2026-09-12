# AGENTS.md

## Repository

A standalone, Nix-managed Neovim setup tailored to the user’s workflow, with ordinary Lua configuration for editor behavior.

> **Nix owns what exists. Lua owns how it behaves.**

- `nvim` = immutable production editor.
- `nvim-next` = experimental editor.
- `nvim-exp` = experiment workflow helper.
- Normal feature work uses the experiment worktree.
- Inspect current repository/Git state before trusting documented implementation status, paths, versions, or roadmap labels.

## Commands

Routine:

```bash
nvim-exp status
git status
```

If no appropriate experiment is active:

```bash
nvim-exp new <name>
```

Develop and inspect:

```bash
nvim-next
git diff
```

Conditional validation — do not run automatically for every task:

```bash
nix flake check path:. --print-build-logs
nix build path:.#nvim
```

Use a conditional check only when the changed surface or `docs/testing.md` makes it relevant.

Lua-only loop:

```text
edit → restart nvim-next → exercise behavior
```

Dependency-changing loop:

```text
declare availability in Nix → launch nvim-next → configure behavior in Lua
```

## Change Map

```text
Plugins          → nix/plugins.nix
External tools   → nix/tools.nix
Core behavior    → config/lua/user/core/
Plugin-backed UI → config/lua/user/ui/
Bootstrap        → dev/init.lua
Workflow         → scripts/ + nix/workflow-tools.nix
Tests            → tests/
Detailed policy  → docs/
```

## Project Rules

- Dependencies belong to Nix; behavior belongs to Lua. No Mason, runtime installers, or parallel dependency manager.
- Keep one canonical configuration tree: `config/`; `dev/init.lua` is bootstrap only.
- Production remains immutable; experimental mutable editor state remains isolated through `NVIM_APPNAME`/`stdpath()`.
- Keep this repository independent of dotfiles and host-specific configuration.
- Verify native Neovim APIs against the version actually packaged by this repository; do not assume `master` APIs exist.
- Keep one coherent task per experiment.
- Follow existing file style. Keep plugin-backed configuration outside the plugin-free core where practical, and give user-facing mappings useful `desc` values.
- Current ticket/project decisions override historical references.

## Orchestration

The agent receiving the ticket is the orchestrator and owns the active experiment, integration, final diff, validation, and test/documentation/roadmap impact assessments.

Default to direct execution. Delegate only bounded independent research, diagnosis, verification, or review when doing so reduces uncertainty, duplicated context, or meaningful implementation risk.

Give subagents only the context needed for their assignment and request concise findings. Subagents do not control experiment lifecycle, push, production pins, or deployment.

## Project Docs

Read docs progressively. Search (`rg`, targeted reads) for relevant sections first; read a full document only when the task genuinely spans it.

```text
docs/architecture.md       architecture / ownership / packaging
docs/behavior.md           UX / mappings / historical behavior
docs/workflow.md           experiments / promotion / agent workflow
docs/testing.md            testing policy
docs/state-isolation.md    mutable editor/plugin state
docs/deployment.md         production deployment / rollback
docs/roadmap.md            current stage / scope / sequencing
docs/references.md         historical and upstream sources
```

If work crosses one of these concerns, consult its owning document before deciding.

For roadmap feature work, establish the relevant stage context first.

For user-facing behavior changes, consult `docs/behavior.md`. Use historical sources only when behavior is ambiguous, being reconstructed, or explicitly relevant.

Do not open every project document merely to prove that it needs no change.

## Definition of Done

Before reporting completion:

- exercise affected behavior with `nvim-next` when relevant;
- ask what meaningful failure the change could introduce and whether existing coverage catches it;
- add tests only for meaningful structural/integration regressions;
- inspect the final diff;
- assess documentation and roadmap impact;
- never claim manual or visual validation that was not performed.

Use:

- `tests/smoke.sh` for packaged startup/integration invariants;
- `tests/state-isolation.sh` for mutable-state isolation risks.

If roadmap status, stage scope, `CURRENT`, sequencing, or roadmap accuracy changed, update `docs/roadmap.md` inside the experiment.

Final report must include either:

```text
Roadmap impact: updated
```

or:

```text
Roadmap impact: none — <brief reason>
```

## Lifecycle Boundaries

Creating or using the normal `nvim-exp` experiment is implementation work; it does not imply acceptance.

Without explicit ticket authorization, do not:

- commit;
- run `nvim-exp promote` or `nvim-exp discard`;
- push `main`;
- change the dotfiles production pin;
- switch or otherwise deploy production;
- deliberately revise an established architectural invariant.

Never:

- install editor dependencies at runtime;
- introduce a second long-lived Neovim configuration;
- bypass stable/experimental state isolation;
- create parallel agent-specific workflow/state systems;
- silently expand a ticket into unrelated roadmap work;
- pull deferred Phase 2 work into V1 without an explicit decision.

Keep these states distinct:

```text
experiment → source stable → deployed stable
```

Implementation success does not imply promotion or deployment.

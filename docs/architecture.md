# Architecture

## Purpose

This document defines the durable architecture of the standalone Nix-managed Neovim project.

It describes:

- ownership boundaries;
- repository boundaries;
- packaging and runtime structure;
- stable and experimental editor identities;
- release-state separation;
- dependency management;
- configuration ownership;
- mutable-state boundaries;
- portability requirements;
- architectural invariants and non-goals.

It does **not** define the detailed development workflow, testing procedures, editor UX, deployment procedure, or implementation roadmap. Those are documented separately.

## Related Documentation

- `docs/workflow.md` — development and experiment lifecycle.
- `docs/testing.md` — testing and validation policy.
- `docs/state-isolation.md` — mutable-state isolation rules.
- `docs/behavior.md` — user-facing behavioral contract.
- `docs/deployment.md` — production deployment boundary.
- `docs/roadmap.md` — current implementation status and future direction.
- `docs/references.md` — canonical repository URLs and durable external references.

Canonical repository locations and durable external references are maintained in `docs/references.md`.

---

# 1. Architectural Summary

The project uses:

> **Nix-managed vanilla Neovim with ordinary Lua configuration.**

The central ownership rule is:

```text
NIX OWNS WHAT EXISTS.
LUA OWNS HOW IT BEHAVES.
```

Conceptually:

```text
Nix
├── Neovim
├── plugins
├── Treesitter parsers
├── language servers
├── formatters
├── linters
└── external executables

Lua
└── configures Neovim and the software supplied by Nix
```

Neovim consumes dependencies supplied by Nix.

It does not silently install its own software dependencies.

The architecture is designed around three properties:

```text
reproducibility
+
safe experimentation
+
deliberate production change
```

The production editor is immutable.

The experimental editor loads configuration live from a Git worktree and has isolated mutable application state.

---

# 2. Primary System Model

There are three important source/release states:

```text
Level 1 — deployed stable

Level 2 — source stable

Level 3 — experiment
```

These states are deliberately separate.

## Deployed stable

The deployed editor is invoked as:

```text
nvim
```

It is:

* the production editor;
* built by Nix;
* configured immutably from the Nix store;
* pinned by the consuming deployment configuration;
* independent of live edits in the development checkout.

The production editor should change only when a new revision is deliberately deployed.

---

## Source stable

Source stable is the `main` branch of the standalone Neovim repository.

Conceptually:

```text
neovim/
branch: main
```

It represents accepted Neovim source.

Source stable may legitimately be newer than deployed stable.

Therefore:

```text
source stable
≠ necessarily deployed stable
```

This separation allows accepted changes to exist in the Neovim repository without automatically changing the editor currently used for daily work.

---

## Experiment

An active experiment is a temporary Git branch and worktree:

```text
experiment/<feature>
```

used by:

```text
nvim-next
```

The experimental editor:

* loads Lua live from the experiment worktree;
* can use dependencies declared by the experimental revision;
* keeps mutable editor state isolated from production;
* can be changed rapidly without mutating deployed `nvim`.

An experiment is an ordinary Git branch/worktree, not a second proprietary state system.

---

# 3. Two Promotion Boundaries

The three stability levels imply two independent acceptance boundaries:

```text
experiment
    ↓
source stable
    ↓
deployed stable
```

These boundaries must remain distinct.

## Experiment → source stable

An accepted experiment may become `main`.

This changes the standalone Neovim source repository.

It does **not** inherently change deployed production Neovim.

---

## Source stable → deployed stable

The deployment configuration later pins and installs an accepted standalone Neovim revision.

This is a separate operation.

The important architectural invariant is:

> Promoting an experiment into Neovim `main` must not silently update the deployed production editor.

Detailed procedures for these transitions belong in:

```text
docs/workflow.md
docs/deployment.md
```

---

# 4. Repository Boundaries

The system deliberately separates editor implementation from operating-system deployment.

## Standalone Neovim repository

This repository owns the editor itself, including:

* Neovim packaging;
* Lua configuration;
* plugin dependencies;
* Treesitter dependencies;
* language-server dependencies;
* formatter and linter dependencies;
* external editor tooling;
* experimental workflow tooling;
* tests;
* health infrastructure;
* project documentation.

This repository is the implementation authority for Neovim.

---

## Dotfiles repository

This repository owns system-level consumption and integration of the standalone editor.

Examples include:

* pinning an accepted Neovim revision;
* installing the standalone Neovim packages;
* Home Manager integration;
* environment variables such as `EDITOR` and `VISUAL`;
* system-specific terminal or desktop integration;
* host-specific integration.

The dotfiles repository consumes Neovim.

It does not own the editor implementation.

---

# 5. Repository Dependency Direction

The dependency direction is intentionally one-way:

```text
dotfiles
    │
    │ consumes / pins
    ▼
neovim
```

Never:

```text
neovim
    │
    │ depends on
    ▼
dotfiles
```

The standalone Neovim repository must not require knowledge of:

* a particular NixOS host;
* a hostname;
* Hyprland;
* a specific laptop;
* the structure of the user's wider dotfiles repository;
* other machine-specific modules.

This preserves the standalone nature of the editor.

System-specific integration belongs in the consuming environment.

---

# 6. Dependency Ownership

Neovim must not become an independent package-management layer.

Dependencies required by the editor are declared through Nix.

This includes:

```text
Neovim
plugins
Treesitter parsers
language servers
formatters
linters
Git-related executables
language-specific executables
other external programs
```

Lua may:

* configure those dependencies;
* enable them;
* select between them;
* define their behavior;
* handle their absence gracefully where appropriate.

Lua should not silently download or install them.

The ownership boundary is therefore:

```text
existence / version / availability
                ↓
               Nix

behavior / configuration / interaction
                ↓
               Lua
```

---

# 7. Nix-Managed Vanilla Neovim

The project intentionally uses ordinary Neovim concepts.

The editor configuration remains normal Lua rather than being expressed through a large configuration abstraction.

The architectural model is:

```text
Nix package
    ↓
vanilla Neovim
    ↓
ordinary Lua configuration
```

This keeps important behavior traceable to either:

```text
a Nix dependency declaration
```

or:

```text
Lua editor configuration
```

The system should remain understandable without requiring knowledge of another Neovim distribution's internal configuration language.

---

# 8. Stable Editor Packaging

The production editor uses an immutable packaged configuration.

Conceptually:

```text
repository config/
        ↓
Nix build
        ↓
immutable Nix store result
        ↓
production nvim
```

The current packaging approach provides Neovim with the packaged repository configuration through its runtime initialization.

The critical invariant is not the exact implementation mechanism.

The critical invariant is:

> A change to the writable development checkout must not mutate an already-built production editor.

Therefore editing:

```text
~/projects/neovim/config/
```

does not immediately alter the currently deployed `nvim`.

A new production configuration requires a new Nix-built result and deliberate deployment.

---

# 9. One Real Lua Configuration

Stable and experimental Neovim must not have independently maintained editor configurations.

The canonical configuration tree is:

```text
config/
```

The distinction between stable and experimental execution comes from using different revisions of the same repository.

Conceptually:

```text
source stable checkout
└── config/

experiment worktree
└── config/
```

These are the same repository paths at different Git revisions.

There must not be:

```text
config-stable/
config-development/
```

or another long-lived duplicated editor configuration.

Duplicated configurations would create configuration drift and undermine promotion semantics.

---

# 10. Experimental Bootstrap

The experimental editor requires a small bootstrap layer so that it can load Lua directly from the active worktree.

That bootstrap is:

```text
dev/init.lua
```

Its role is infrastructure only.

It is not a second Neovim configuration.

Conceptually:

```text
nvim-next
    ↓
experimental environment
    ↓
dev/init.lua
    ↓
live worktree config/
```

Editor behavior continues to live in the canonical:

```text
config/
```

tree.

---

# 11. Stable and Experimental Application Identity

Stable and experimental Neovim intentionally use different application identities.

Production uses normal Neovim identity:

```text
nvim
```

Experimental execution uses:

```text
NVIM_APPNAME=nvim-next
```

This causes Neovim's XDG-derived mutable directories to differ between the two environments.

The architecture requires isolation for editor-specific mutable state such as:

```text
config identity
data
state
cache
ShaDa
sessions
persistent undo if introduced
plugin-generated mutable state
indexes
histories
databases
generated metadata
```

Shared mutable editor state is **not** the default.

Detailed storage rules and verified paths belong in:

```text
docs/state-isolation.md
```

---

# 12. Intentionally Shared Resources

Not everything needs isolation.

Stable and experimental Neovim may intentionally share resources that are external to editor-specific mutable state.

Examples include:

```text
project files
Git repositories
project-local configuration
system clipboard
shell environment
project environments
immutable Nix store dependencies
```

The distinction is:

```text
immutable or project-owned resource
→ sharing is normally safe

mutable editor-specific state
→ isolation is the default
```

---

# 13. Standalone Flake Boundary

The Neovim repository is also a standalone Nix flake.

Its public package model separates production use from development workflow tooling.

The established outputs include conceptually:

```text
#nvim
    stable production editor

#workflow-tools
    experimental workflow commands

#full
    stable editor + workflow tools

default
    stable editor

devShells.default
    experimental/development environment

checks
    repository validation
```

The stable package remains the primary product.

A user who only wants the production editor does not need a writable source checkout.

A writable Git checkout is required only for development and experimentation.

This keeps consumption of the editor separate from development of the editor.

---

# 14. Independent Nixpkgs Lifecycle

The standalone Neovim flake owns its own nixpkgs input and lock lifecycle.

Its nixpkgs dependency is intentionally independent from the nixpkgs lifecycle of the consuming NixOS/dotfiles repository.

Conceptually:

```text
system nixpkgs lifecycle
        ≠
Neovim nixpkgs lifecycle
```

A broad operating-system dependency update should not automatically force the editor ecosystem to update at the same time.

Likewise, updating the standalone editor's package ecosystem should not require redesigning the host operating system.

This separation reduces coupling between system maintenance and editor maintenance.

---

# 15. Portability Boundary

The standalone Neovim project is intended to work independently of a particular NixOS installation.

The design targets:

```text
NixOS
```

and:

```text
non-NixOS Linux systems with the Nix package manager
```

Stable use should not inherently require:

* this user's dotfiles repository;
* a development checkout;
* Home Manager;
* a particular desktop environment.

The consuming system may provide those integrations, but the editor architecture itself must not require them.

---

# 16. Project Configuration Authority

Global editor configuration provides defaults.

Project-owned configuration may override those defaults where appropriate.

Examples include:

```text
.editorconfig
.nvim.lua
pyproject.toml
latexmkrc
Makefile
Nix devShell
language-specific project configuration
```

This establishes a responsibility hierarchy:

```text
global Neovim configuration
    ↓ provides defaults

project configuration
    ↓ may specialize those defaults
```

The editor should cooperate with project conventions rather than attempting to replace them.

---

# 17. External System Boundaries

Neovim is an editor and integration surface, not the owner of every development subsystem.

The intended responsibility boundaries are:

```text
Neovim
→ editing
→ editor UI
→ editor-facing integrations

Nix
→ software dependencies

Git
→ repository state and history

shell
→ command execution
→ project shell environment

tmux
→ durable shells
→ long-running TUIs
→ agents
→ REPLs
→ logs

Jupyter / IPython
→ scientific execution where appropriate

Zotero
→ bibliography management
```

Neovim may expose convenient interfaces to these systems.

It should not hide or replace their underlying state unnecessarily.

---

# 18. Inspectable Automation

Automation must remain understandable in terms of normal system primitives.

The architecture deliberately relies on mechanisms such as:

```text
Git repositories
Git branches
Git worktrees
Nix flakes
flake.lock
Nix packages
Nix generations
shell scripts
```

Helpers may automate these operations, but should not create an opaque parallel source of truth.

For example, `nvim-exp` is intended as a thin interface over normal Git/Nix mechanisms rather than a hidden workflow database.

The underlying state should remain inspectable using ordinary tools.

---

# 19. Graceful Degradation

Basic editing should survive failure of optional functionality whenever practical.

Examples:

```text
Git integration fails
→ editing remains available

fuzzy-search plugin fails
→ editing remains available

formatter unavailable
→ editing remains available

LSP unavailable
→ editing remains available

optional UI component fails
→ editing remains available
```

Failure should be visible when useful.

Optional failures should not unnecessarily turn into total-editor failures.

This principle affects module design: optional components should remain sufficiently isolated that they can fail or be removed without destroying the core editor.

---

# 20. Modularity

Features should be implemented as understandable, replaceable units.

A feature should ideally be removable or replaced without untangling unrelated editor behavior.

The intended direction is conceptually:

```text
core
ui
navigation
editor functionality
LSP
languages
Git
writing
integrations
health
```

Exact directories and modules should be introduced only when actual functionality requires them.

The project should not pre-create a large speculative hierarchy.

Architecture should emerge incrementally while preserving clear ownership boundaries.

---

# 21. Core vs Optional Layers

The configuration should maintain a meaningful distinction between fundamental editor behavior and optional/plugin-backed features.

Conceptually:

```text
Neovim
    ↓
plugin-free core
    ↓
optional modular capabilities
```

The core should contain behavior necessary for a dependable editor baseline.

Plugin-dependent functionality should remain outside that core where practical.

This improves:

* failure isolation;
* startup reliability;
* replaceability;
* debugging;
* maintainability.

---

# 22. Modern Neovim Implementation Policy

Historical configurations define important desired behavior, but they do not define the architecture of this repository.

The new project should prefer current native Neovim mechanisms where they provide a reliable implementation of the desired behavior.

However:

> "current" means compatible with the Neovim version actually packaged by this repository.

Do not assume that an API present in Neovim development documentation or `master` exists in the packaged stable version.

The architecture favors:

```text
stable packaged Neovim
+
APIs verified against that version
```

rather than moving production to a development build merely to use a newer API.

Behavioral-reference precedence is documented separately in:

```text
docs/behavior.md
```

---

# 23. Source-of-Truth Boundaries

Different sources answer different questions.

## Implementation truth

The current standalone repository is authoritative for:

```text
what is actually implemented
what dependencies currently exist
what the flake currently exports
what the current code does
```

Documentation should not override observable repository state when it has become stale.

---

## Architectural truth

This document records the durable architecture and invariants.

Changing an architectural invariant should be deliberate rather than an accidental side effect of implementing an unrelated feature.

---

## Behavioral truth

Desired editor behavior and historical compatibility rules belong in:

```text
docs/behavior.md
```

Historical LunarVim and standalone Neovim configurations are behavioral references.

They are not architectural dependencies of the current project.

---

## Workflow truth

Development, experiment, promotion, and acceptance procedures belong in:

```text
docs/workflow.md
```

---

## Testing truth

Testing policy and validation expectations belong in:

```text
docs/testing.md
```

---

## Deployment truth

The process for turning source stable into deployed stable belongs in:

```text
docs/deployment.md
```

---

## Current direction

Current and future implementation sequencing belongs in:

```text
docs/roadmap.md
```

---

# 24. Architectural Non-Goals

The project intentionally does not use the following as its architectural foundation:

```text
NixVim
NVF
nixCats
LunarVim
LazyVim
Mason
runtime-managed dependency installation
a second long-lived development configuration
host-specific configuration inside the standalone Neovim repository
```

These tools or projects are not necessarily considered poor solutions in general.

They are rejected as foundations here because they conflict with one or more selected ownership boundaries:

```text
Nix owns dependencies
ordinary Lua owns editor behavior
one canonical configuration
standalone repository independence
explicit and inspectable state
```

A future architectural change may revisit these choices, but they should not be introduced incidentally as part of an unrelated feature.

---

# 25. Architectural Invariants

The following should remain true unless the architecture is deliberately revised.

1. **Nix owns software dependencies.**

2. **Lua owns editor behavior.**

3. **Production `nvim` uses immutable packaged configuration.**

4. **A working-tree edit does not immediately mutate deployed production.**

5. **There is one canonical Lua configuration tree.**

6. **`dev/init.lua` is a bootstrap, not a second configuration.**

7. **Stable and experimental editor-specific mutable state remain isolated.**

8. **The standalone Neovim repository does not depend on the dotfiles repository.**

9. **The Neovim flake maintains an independent dependency lifecycle from the host system.**

10. **Source stable and deployed stable remain distinct concepts.**

11. **Experiment-to-source and source-to-deployment remain separate acceptance boundaries.**

12. **Runtime dependency installation does not replace Nix ownership.**

13. **Optional feature failure should not unnecessarily destroy basic editing.**

14. **Automation remains inspectable through ordinary Git, Nix, and filesystem state.**

15. **Features remain modular and replaceable where practical.**

16. **Project-local configuration retains authority over project-specific conventions where appropriate.**

17. **The standalone editor remains usable independently of a particular host or desktop configuration.**

18. **Native Neovim APIs are selected against the packaged stable version, not assumed from development documentation.**

---

# 26. One-Screen Architecture

```text
                    standalone neovim repo
                           │
              ┌────────────┴────────────┐
              │                         │
             Nix                       Lua
              │                         │
      owns dependencies           owns behavior
              │                         │
              └────────────┬────────────┘
                           │
                       config/
                           │
            ┌──────────────┴──────────────┐
            │                             │
       packaged config               live worktree
            │                             │
            ▼                             ▼
          nvim                        nvim-next
   deployed production                experiment
            │                             │
      isolated mutable state       isolated mutable state
            │                             │
            └──────────────┬──────────────┘
                           │
                  same configuration model


release states:

experiment/<feature>
        │
        ▼
neovim/main
source stable
        │
        ▼
dotfiles pin
        │
        ▼
deployed nvim


repository dependency:

dotfiles
    │
    │ consumes
    ▼
neovim
```

---

# 27. Governing Principle

The architecture exists to make aggressive experimentation compatible with a conservative production editor.

The concise mental model is:

```text
NIX OWNS WHAT EXISTS.
LUA OWNS HOW IT BEHAVES.

EXPERIMENT FREELY.
PROMOTE DELIBERATELY.
DEPLOY INTENTIONALLY.
```

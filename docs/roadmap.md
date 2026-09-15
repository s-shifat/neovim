# Roadmap

## Purpose

This document records the implementation status, sequencing, and future direction of the standalone Neovim project.

It answers:

* what has already been completed;
* what the current editor baseline contains;
* what should be implemented next;
* which features belong to later stages;
* which ideas are intentionally deferred;
* how the project should progress toward the first stable feature-complete editor.

This document is intentionally more time-sensitive than the other project documentation.

The current repository state is authoritative when this roadmap becomes stale.

## Related Documentation

* `docs/architecture.md` — durable system architecture and ownership boundaries.
* `docs/behavior.md` — desired editor behavior and UX requirements.
* `docs/workflow.md` — experiment and implementation lifecycle.
* `docs/testing.md` — testing and validation policy.
* `docs/state-isolation.md` — stable/experimental mutable-state policy.
* `docs/deployment.md` — source-stable to deployed-stable procedure.
* `docs/references.md` — canonical repository URLs and durable external references.

Repository locations and upstream references are maintained in `docs/references.md`.

---

# 1. Roadmap Role

This file tracks implementation direction.

It is **not** the authority for architecture.

For example:

```text
architecture.md
→ defines that Nix owns dependencies

behavior.md
→ defines how completion should behave

roadmap.md
→ defines when completion is planned to be implemented
```

If a roadmap item conflicts with a durable architectural or behavioral decision, the durable project documentation wins.

---

# 2. Status Categories

Roadmap items use the following meanings:

```text
COMPLETE
→ implemented and accepted into source stable

CURRENT
→ next active editor-development target

PLANNED
→ part of the intended V1 sequence

DEFERRED
→ intentionally postponed beyond the first stable editor
```

A stage may also contain smaller completed and remaining sub-stages.

---

# 3. Current Status

The latest completed editor milestone is:

```text
Stage 7E — Notifications
```

The current editor-development target is:

```text
Stage 8 — Navigation and Editor Workflow
Stage 8A — Telescope Search Foundation
```

Exact source and deployed revisions should be determined from the current repositories rather than recorded here.

---

# 4. Current Development Baseline

The project has already established the infrastructure required to develop editor features safely.

Current baseline includes:

```text
standalone Nix flake

immutable production Neovim

live experimental Neovim

Git worktree experiments

nvim-exp lifecycle tooling

fresh-machine development setup

stable/experimental mutable-state isolation

packaged smoke testing

promotion validation gate

plugin-free native editor core

Nix-owned shared plugin inventory

generic colorscheme infrastructure

Catppuccin Mocha default

nvim-web-devicons initialized centrally in the UI layer

global Lualine statusline with restrained editor, Git, diagnostic, and LSP context
```

`nvim-web-devicons` is now part of the shared standalone Neovim plugin baseline. Consumer-specific icon behavior remains owned by the UI features that use it.

This means future work should normally focus on editor capabilities rather than redesigning the underlying experiment/deployment architecture.

---

# 5. Completed Infrastructure Stages

## Stage 0 — Repository Skeleton

**Status: COMPLETE**

Established:

```text
standalone repository
Nix/Lua ownership boundary
initial repository structure
independence from host-specific dotfiles
```

---

## Stage 1 — Bare Standalone Neovim Flake

**Status: COMPLETE**

Established:

```text
independent Neovim flake
independent nixpkgs input
#nvim package
stable Neovim build
x86_64-linux support
aarch64-linux support
```

The standalone editor became installable independently of the wider NixOS configuration.

---

## Stage 2 — Immutable Stable Lua Configuration

**Status: COMPLETE**

Established:

```text
packaged config/
immutable Nix-store configuration
production configuration independent of working-tree edits
```

This proved the production immutability boundary.

---

## Stage 3 — Stable/Experimental Workflow

**Status: COMPLETE**

Established:

```text
nvim
nvim-next
nvim-exp

#workflow-tools
#full

Git worktree experiments

nvim-exp new
nvim-exp status
nvim-exp discard
nvim-exp promote
```

This created the primary safe-development workflow.

---

## Stage 3.5 — Development Bootstrap and Deployment Integration

**Status: COMPLETE**

Established:

```text
nvim-exp setup

existing-repository adoption

HTTPS/SSH cloning

configurable development checkout location

fresh-machine stable installation without clone

Home Manager consumption

dotfiles production pin
```

Stable consumption and development setup became intentionally separate.

---

## Stage 4 — State Isolation

**Status: COMPLETE**

Established stable/experimental separation for:

```text
application identity

stdpath("config")

stdpath("data")

stdpath("state")

stdpath("cache")

ShaDa
```

Also established:

```text
NVIM_APPNAME=nvim-next

dev/init.lua application-identity guard

tests/state-isolation.sh
```

Future sessions, undo, and plugin-generated mutable state must continue to follow this architecture.

---

## Stage 5 — Smoke Tests and Promotion Gate

**Status: COMPLETE**

Established:

```text
packaged startup smoke test

configuration-load sentinel

isolated test HOME/XDG environment

flake checks

workflow-tool build validation

promotion validation gate
```

`nvim-exp promote` became the authoritative experiment → source-stable transition.

---

# 6. Completed Core Editor Stage

## Stage 6 — Native Plugin-Free Core

**Status: COMPLETE**

Established the dependable editor baseline before introducing plugins.

Implemented:

```text
core/options.lua
core/keymaps.lua
core/autocmds.lua
```

Important behavior includes:

```text
hybrid line numbers

2-space indentation

smart-case search

system clipboard

split behavior

safe buffer closing

familiar historical navigation mappings

visual selection movement

terminal split navigation

brief yank feedback

resize rebalance
```

Historical LunarVim and standalone Neovim configurations were used primarily as behavioral specifications.

---

## Stage 6 Regression Fix — Yank Highlight

**Status: COMPLETE**

A `TextYankPost` callback initially used an API unavailable in the packaged Neovim version.

The implementation was corrected to use the packaged stable API.

The smoke test was expanded to trigger:

```text
yy
dd
```

so the callback is exercised rather than merely verifying startup.

This established the principle that important event-driven behavior may require event-level regression coverage.

---

# 7. Stage 7 — UI Foundation

Stage 7 introduces the first plugin-backed UI capabilities.

It is deliberately divided into small independent pieces.

---

## Stage 7A — Theme Foundation

**Status: COMPLETE**

Stage 7A established the first real plugin-backed UI layer while preserving the project's existing ownership model:

> Nix owns plugin availability; Lua owns plugin behavior.

### Stage 7A.1 — Shared Plugin Foundation

**Status: COMPLETE**

Implemented:

```text
shared Nix-owned Neovim plugin inventory

same plugin inventory for stable nvim and experimental nvim-next

Catppuccin installed through Nix as the first real Neovim plugin dependency
```

The shared plugin inventory is consumed by both:

```text
stable packaged Neovim
experimental development Neovim
```

This ensures plugin parity between production and experimentation without introducing a runtime plugin manager.

### Stage 7A.2 — Generic Theme Architecture

**Status: COMPLETE**

Implemented:

```text
new user.ui layer

generic Lua colorscheme loader

explicit default theme policy

NVIM_COLORSCHEME one-launch override

manual native :colorscheme switching

active-theme tracking

graceful warning and fallback when a requested theme fails

continued editor startup if even the default theme cannot load
```

Current default:

```text
catppuccin-mocha
```

Important design rule:

> Catppuccin is the default theme, not the theme architecture.

The generic loader is not tied to Catppuccin, so other Nix-packaged colorschemes can be introduced later without redesigning the theme system.

### Stage 7A.3 — Catppuccin Configuration

**Status: COMPLETE**

Implemented a dedicated:

```text
user/ui/themes/catppuccin.lua
```

module containing Catppuccin-specific behavior.

Configured:

```text
opaque editor background

opaque floating windows

terminal ANSI colors left unchanged

inactive-window dimming disabled

italic comments

italic conditionals

bold enabled

underline enabled

automatic Catppuccin plugin integrations disabled
```

Plugin integrations will be enabled explicitly only when their corresponding plugins are actually introduced.

The Catppuccin flavor itself is not hard-coded inside the Catppuccin module. The default `catppuccin-mocha` selection remains part of the generic UI policy, allowing native switches such as:

```vim
:colorscheme catppuccin-latte
```

without changing the architecture.

### Stage 7A.4 — Theme Regression Coverage

**Status: COMPLETE**

Extended the packaged Neovim smoke test to verify that:

```text
Catppuccin is present in the packaged runtime

a default colorscheme is declared

the startup-requested theme matches the declared default

the requested theme successfully loads

Neovim's active colorscheme matches the tracked loaded theme
```

The smoke environment also clears `NVIM_COLORSCHEME` so automated testing always validates the declared production default rather than inheriting a temporary user override.

The regression test intentionally does not hard-code `catppuccin-mocha` as an invariant. This allows the default theme to be replaced later without redesigning the test architecture.

### Stage 7A.5 — Final Validation and Promotion

**Status: COMPLETE**

The complete Stage 7A experiment passed:

```text
flake checks

packaged Neovim smoke test

candidate package build

stable/experimental state-isolation regression
```

The experiment was then fast-forward promoted to Neovim `main` and deployed through the dotfiles Neovim flake pin.

## Icons

**Status: COMPLETE**

`nvim-web-devicons` was initially considered for Stage 7A and briefly added during development, but it was removed before Stage 7A was promoted.

Reason:

> Icons should be introduced alongside the first UI component that actually consumes them rather than packaged speculatively.

The shared icon foundation was introduced when the first real consumer became imminent. The current baseline now contains:

```text
nvim-web-devicons

user/ui/icons.lua

central UI-layer initialization after the colorscheme and before consumer plugins
```

The provider uses upstream defaults. Consumer-specific icon behavior remains owned by future features such as the file explorer, buffer bar, Telescope results, or another navigation/UI component.

The Nerd Font itself remains a host-system responsibility and is already supplied through the NixOS dotfiles.

---

## Stage 7B — which-key

**Status: COMPLETE**

Goal:

> Make the leader-key hierarchy discoverable without replacing normal Vim interaction.

Implemented:

```text
which-key supplied through the shared Nix plugin inventory

dedicated user.ui.which-key configuration boundary

300 ms discovery delay

existing keymap descriptions discovered without a duplicate registry

mapping icons disabled without adding an icon dependency

Catppuccin Which-Key integration enabled explicitly
```

No mappings, manual invocation, or speculative leader groups were added.

Testing should protect startup/integration invariants rather than exact popup appearance or label cosmetics.

---

## Stage 7C — Statusline

**Status: COMPLETE**

Goal:

> Provide useful persistent status with moderate information density.

Implemented one global Lualine statusline with:

```text
mode

Git branch

built-in diagnostic severity counts

relative file path with modified/read-only state

filetype and icon

compact LSP attachment indicator

file progress

line and column location
```

Lualine follows the active colorscheme automatically and uses the centrally initialized `nvim-web-devicons` provider. Native `showmode` is disabled only after Lualine initializes successfully, preserving mode feedback if the optional UI layer is unavailable.

The LSP component stays empty until a client is attached to the current buffer, then reports only `LSP` rather than persistent server names.

Avoid turning the statusline into a full system-debug dashboard.

Detailed operational information belongs in the later health interface.

---

## Stage 7D — Git Signs

**Status: COMPLETE**

Goal:

> Add persistent lightweight Git change indicators and hunk interaction.

Expected capabilities:

```text
Git gutter signs

hunk navigation

hunk preview/actions where useful
```

Git remains real Git.

The plugin provides an interface over repository state rather than replacing it.

---

## Stage 7E — Notifications

**Status: COMPLETE**

Goal:

> Provide visible but restrained notifications with inspectable history.

Expected behavior:

```text
small transient popup

notification history

graceful optional failure

limited repeated warning spam where simple
```

Avoid complex notification infrastructure solely for visual polish.

Implemented with the `snacks.nvim` notifier as the standard `vim.notify`
backend. Notifications use the compact top-right presentation with a
three-second default timeout, wrapped long messages, non-focusable transient
windows, session-local history, and mappings to inspect history or dismiss
visible notifications.

Only the notifier lifecycle is enabled. Snacks modules with automatic setup
lifecycles remain explicitly disabled, while its on-demand utilities receive
no configuration or mappings. Catppuccin owns the notification highlights and
Which-Key identifies the notification mapping namespace.

---

# 8. Stage 8 — Navigation and Editor Workflow

**Status: CURRENT**

This stage builds the main navigation and editor-workflow experience through
explicit, independently reviewable substages.

## Stage 8A — Telescope Search Foundation

**Status: CURRENT**

Purpose:

> Establish Telescope as the primary fuzzy-search and discovery interface for the editor.

Telescope is the primary search/navigation UI. It is not being replaced by
Snacks Picker.

Planned Telescope foundation includes:

```text
telescope.nvim
plenary.nvim
telescope-fzf-native.nvim
telescope-ui-select.nvim
telescope-live-grep-args.nvim
```

Nix-owned external search tools:

```text
ripgrep
fd
```

`ugrep` is not planned unless a concrete future limitation requires it. The
`fzf` CLI is not required merely for `telescope-fzf-native`.

Behavioral goals:

```text
LunarVim-style Telescope interaction/layout

project-file search
general file search
live grep with runtime arguments
word / visual-selection grep
buffer search
open-file grep
recent-file search
help search
keymap search
Telescope builtin discovery
Neovim-config search
diagnostic search

Resume as a first-class action

preview available where useful and toggleable on demand

vim.ui.select routed through Telescope
```

The search namespace direction is:

```text
<leader>s
→ Telescope / search namespace

<leader>sp
→ project files

<leader>su
→ Telescope UI controls

<leader>sup
→ preview toggle
```

This does not yet specify every eventual mapping.

### Search-Scope Policy

Ordinary broad project searches should suppress clearly noisy environment and
cache trees such as:

```text
.git/
.venv/
venv/
env/
__pycache__/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.ipynb_checkpoints/
node_modules/
```

Common lock files generally do not need to appear in ordinary broad discovery
unless explicitly requested. Potentially legitimate project content must not
be hidden globally merely because it can sometimes be generated. In
particular, the global exclusion policy should not include:

```text
lib/
lib64/
build/
dist/
target/
site/
*.ipynb
```

Project-owned ignore rules remain authoritative where appropriate. The exact
implementation of this exclusion policy belongs to Stage 8A.

## Stage 8B — Daily File Explorer

**Status: PLANNED**

The selected daily explorer direction is Snacks Explorer.

Target behavior preserves the useful parts of the historical NvimTree workflow:

```text
left-side project tree
easy toggle/focus
reveal current file
filesystem operations
Git/diagnostic context where useful
icons
replaceable/non-essential to basic editing
```

The responsibility boundary is:

```text
Snacks Explorer
→ daily filesystem/project tree

Telescope
→ primary fuzzy search/navigation
```

Installing Snacks Explorer must not redefine Snacks Picker as the project's
primary search interface.

## Stage 8C — Oil On-Demand

**Status: PLANNED**

Oil.nvim is planned as a secondary, on-demand filesystem editing tool. It does
not replace Snacks Explorer and should not take over normal directory opening
by default.

Expected usage:

```text
dedicated Oil buffer where useful
floating Oil workflow where useful
bulk/editable filesystem operations
```

This is the planned first deliberate experiment with deferred plugin
initialization:

```text
Nix owns Oil availability
normal startup does not initialize Oil
explicit Oil action initializes/uses it on demand
```

This does not imply adoption of a runtime plugin manager.

## Stage 8D — Browser-Like Buffer Bar

**Status: PLANNED**

Target behavior:

```text
visible browser-like buffer bar
all buffers remain discoverable through Telescope
safe buffer closing remains authoritative
normal Neovim buffers remain the underlying model
```

Bufferline is the leading historical/modern candidate, but plugin selection
remains part of the Stage 8D design step.

## Stage 8E — Neovim / tmux Navigation

**Status: PLANNED**

Target behavior:

```text
Ctrl-h/j/k/l
→ seamless directional movement across Neovim splits and tmux panes
```

Preserve the existing resize muscle memory where practical. A modern solution
such as `smart-splits.nvim` is a leading candidate, but the final decision must
follow inspection of the current tmux configuration.

## Stage 8F — Quick Terminal

**Status: PLANNED**

The selected direction is Snacks Terminal.

Target behavior:

```text
toggleable
horizontal bottom panel
similar role to the default VS Code terminal position
opens in the current project/working directory
used for quick commands, short tests, and brief shell interaction
```

Responsibility boundary:

```text
Snacks Terminal
→ short/basic tasks

tmux
→ durable shells
→ agents
→ REPLs
→ logs
→ long-running processes
```

The Neovim terminal is not the durable shell/session layer.

## Stage 8G — Sessions / Project Context

**Status: PLANNED**

Sessions have a dedicated design substage because they overlap with:

```text
project identity
project root
working directory
session ownership
project-local configuration
project environment
future tmux/project reconstruction
```

The intended behavioral direction remains approximately:

```text
save conveniently
restore deliberately
stable and experimental session state remain isolated
```

Implementation should be decided only after the project/session model is
discussed. Neither `persistence.nvim` nor native `:mksession` is selected yet.

Major behavioral goals are defined in `docs/behavior.md`. Each substage should
remain modular so that selecting one interface does not make later replacement
prohibitively difficult.

---

# 9. Stage 9 — Treesitter and Structural Navigation

**Status: PLANNED**

## Stage 9A — Treesitter Foundation

**Status: PLANNED**

Goal:

> Establish Nix-owned syntax parsing infrastructure.

Expected work:

```text
Treesitter integration

intentional parser inventory

syntax highlighting

incremental parsing behavior

language-specific parser availability
```

Do not install every available parser by default.

Parsers should be added intentionally for supported languages.

## Stage 9B — Symbols / Outline

**Status: PLANNED**

Goal:

```text
structural symbol outline
fuzzy symbol navigation through Telescope
Treesitter-backed symbols initially
LSP enrichment after Stage 10
```

A useful symbols/outline layer should have a real structural backend rather
than being introduced before Treesitter or LSP exists. Aerial is currently the
leading implementation candidate, but the final plugin and configuration
decision remains part of Stage 9B design.

---

# 10. Stage 10 — LSP Foundation

**Status: PLANNED**

Goal:

> Provide a modern native Neovim LSP architecture with Nix-owned language servers.

Expected work:

```text
native LSP configuration

server enablement

attach-time behavior

common LSP mappings

diagnostic policy

capability handling

project overrides

health visibility
```

Dependency policy:

```text
Nix owns language servers.
No Mason.
```

Native APIs must be checked against the Neovim version actually packaged by the project.

---

# 11. Stage 11 — Completion and Snippets

**Status: PLANNED**

Goal:

> Provide fast, aggressive completion with a unified snippet experience.

Target behavior:

```text
automatic completion popup

LSP completion

snippet completion

Tab accepts selected item

Esc dismisses completion

snippets appear in the same UI

snippets expand only when selected
```

AI completion remains separate and optional.

---

# 12. Stage 12 — Formatting and Linting

**Status: PLANNED**

Goal:

> Establish one authoritative formatting path per buffer/project.

Expected work:

```text
Nix-owned formatters

Nix-owned linters

format-on-save default

project overrides

language-specific formatter policy

safe missing-tool behavior
```

Avoid competing formatting systems.

Project configuration should remain authoritative where appropriate.

---

# 13. Stage 13 — Language Vertical Slices

**Status: PLANNED**

Languages should be completed incrementally rather than attempting all language support at once.

Recommended order:

```text
1. Lua

2. Nix

3. Bash

4. Python

5. JSON / YAML / TOML / CSV

6. Markdown

7. LaTeX
```

Each language should be treated as a vertical slice where relevant:

```text
parser
        ↓
LSP
        ↓
formatter
        ↓
linter
        ↓
filetype behavior
        ↓
health visibility
```

Not every language requires every layer.

---

# 14. Stage 14 — Git Workflow

**Status: PLANNED**

Complete the richer Git experience beyond basic gutter signs.

Expected capabilities:

```text
hunk workflows

blame

diff workflows

LazyGit integration
```

The editor remains an interface over normal Git state.

---

# 15. Stage 15 — LaTeX and Research Workflow

**Status: PLANNED**

LaTeX is a first-class V1 requirement.

Expected capabilities:

```text
VimTeX

main.tex/root detection

multi-file projects

explicit continuous compilation

latexmk

project latexmkrc / Makefile authority

pdflatex / LuaLaTeX

PDF viewer

SyncTeX forward search

SyncTeX inverse search

bibliography search

snippets

spelling

style/grammar assistance where mature
```

Compiler output remains authoritative.

LSP diagnostics are complementary.

---

# 16. Stage 16 — Health and Diagnostics

**Status: PLANNED**

Goal:

> Make the editor's dependency and integration state inspectable.

The health layer should help answer:

```text
Which LSPs are active?

Which external tools exist?

Which formatter is selected?

Which Python environment is active?

Which Treesitter parsers are available?

Which optional dependencies are missing?

Is Git tooling available?
```

Persistent UI should remain concise.

Detailed status belongs in this explicit on-demand interface.

---

# 17. Stage 17 — Beta Stabilization

**Status: PLANNED**

Before calling the first major editor version stable, perform broader system validation.

Expected work:

```text
fresh installation testing

standalone #nvim validation

#full workflow validation

NixOS/Home Manager integration validation

rollback testing

common-project testing

smoke-test review

state-isolation review

dependency cleanup

documentation review

remove unnecessary complexity

document known limitations
```

The objective is not merely feature completeness.

It is confidence that the editor can be relied upon as daily infrastructure.

---

# 18. V1 Target Scope

The intended first stable editor should provide strong support for:

```text
Nix
Lua
Bash
Python
LaTeX
Markdown
JSON
YAML
TOML
CSV
```

and major workflows including:

```text
theme

icons where consumed by actual UI features

statusline

buffer bar

Telescope

file explorer

which-key

Git signs

diagnostics

completion/snippets

notifications/history

symbols

tmux navigation

Git workflow

basic sessions

formatting/linting

Treesitter

LSP

health inspection

full LaTeX workflow
```

V1 should prioritize a coherent, dependable development environment rather than the maximum possible number of integrations.

---

# 19. Stage 18 — Phase 2 Experiments

**Status: DEFERRED**

These features are intentionally postponed until the normal editor workflow is mature.

Potential Phase 2 work includes:

```text
Python # %% cell execution

Jupytext/Jupyter integration

scientific output workflows

DataFrame viewing

notes system

Hyprland quick-note capture

project-aware tmux reconstruction

project launcher

rofi project picker

automatic project environment orchestration

deeper Codex/Claude editor bridges

AI review/apply workflows

automatic light/dark switching

deeper Markdown rendering

direct Zotero integration
```

These should not be introduced as accidental scope expansion during V1 tasks.

Each should go through the same experiment and promotion discipline as core features.

---

# 20. AI / Codex Integration vs Stage 18

The project currently uses Codex as a development agent.

That does **not** mean the deferred editor-side AI integration described in Stage 18 is already being implemented.

Current agent workflow is external:

```text
user + ChatGPT
        ↓
lock task
        ↓
structured ticket
        ↓
Codex CLI
        ↓
normal repository workflow
```

Current documentation such as:

```text
AGENTS.md
docs/
```

supports software maintenance.

Stage 18 refers to deeper **editor integration**, such as sending selections, diagnostics, or diffs from Neovim to external agents.

These are different concerns.

---

# 21. Intentionally Deferred Complexity

Do not pull these capabilities forward merely because an implementation is available:

```text
rich notebook UI

direct .ipynb editing

variable explorer

DataFrame browser

notes system

automatic project-session reconstruction

automatic Nix devShell orchestration

deep AI UI

Harpoon

breadcrumbs

animations

heavy Markdown rendering

automatic theme switching

direct Zotero integration
```

A deferred feature may move earlier only through an explicit current project decision.

---

# 22. Stage Discipline

The roadmap is intentionally incremental.

Preferred progression:

```text
one coherent feature
        ↓
experiment
        ↓
validate
        ↓
test-impact assessment
        ↓
promote
        ↓
next feature
```

Avoid:

```text
theme
+
which-key
+
Telescope
+
LSP
+
completion
+
formatting
```

inside one experiment.

Small stages improve:

```text
reviewability

debugging

rollback

regression isolation

AI-agent reliability

understanding of the final system
```

---

# 23. When a Stage May Be Split

A roadmap stage is a planning unit, not a requirement that all of its work occur in one experiment.

Split a stage when doing so creates clearer independent changes.

Stage 7 is an example:

```text
7A
theme

7B
which-key

7C
statusline

7D
Git signs

7E
notifications
```

Similarly, language support should normally be implemented one language at a time.

Do not preserve a large stage boundary when smaller coherent experiments are safer.

---

# 24. When the Roadmap Should Change

The roadmap is directional rather than immutable.

Update it when:

```text
a stage is completed

a planned feature is intentionally removed

a stage is split into clearer units

new evidence changes implementation order

a previously deferred feature becomes necessary

an architectural decision materially changes future sequencing
```

Do not change durable architecture merely to preserve an outdated roadmap.

Instead:

```text
architecture stays authoritative

roadmap adapts
```

---

# 25. Status Verification Rule

Because this document records changing implementation status, do not trust its status labels blindly.

Before beginning a new stage:

```text
inspect current Git state
        ↓
inspect recent source history
        ↓
compare with roadmap
        ↓
update roadmap if necessary
```

In particular, do not assume:

```text
CURRENT
```

still means current months later.

The standalone repository is authoritative for what has actually landed.

The consuming deployment repository is authoritative for what is currently pinned for production.

Repository locations are maintained in:

```text
docs/references.md
```

---

# 26. Current Next Sequence

The expected near-term sequence is:

```text
Stage 8A — Telescope Search Foundation
        ↓
Stage 8B — Daily File Explorer
        ↓
Stage 8C — Oil On-Demand
        ↓
Stage 8D — Browser-Like Buffer Bar
        ↓
Stage 8E — Neovim/tmux Navigation
        ↓
Stage 8F — Quick Terminal
        ↓
Stage 8G — Sessions / Project Context
        ↓
Stage 9A — Treesitter Foundation
        ↓
Stage 9B — Symbols / Outline
        ↓
Stage 10 — LSP Foundation
        ↓
Stage 11 — completion/snippets
        ↓
Stage 12 — formatting/linting
        ↓
Stage 13 — languages
        ↓
Stage 14 — Git
        ↓
Stage 15 — LaTeX/research
        ↓
Stage 16 — health
        ↓
Stage 17 — stabilization
        ↓
Stage 18 — optional Phase 2 work
```

This order may be refined when a dependency relationship provides a concrete reason to do so.

---

# 27. Stage Summary

| Stage | Scope                              | Status      |
| ----- | ---------------------------------- | ----------- |
| 0     | Repository skeleton                | COMPLETE    |
| 1     | Bare standalone flake              | COMPLETE    |
| 2     | Immutable stable Lua config        | COMPLETE    |
| 3     | Stable/experimental workflow       | COMPLETE    |
| 3.5   | Bootstrap + deployment integration | COMPLETE    |
| 4     | State isolation                    | COMPLETE    |
| 5     | Smoke tests + promotion gate       | COMPLETE    |
| 6     | Native plugin-free core            | COMPLETE    |
| 6 fix | Yank-highlight regression          | COMPLETE    |
| 7A    | Theme foundation                   | COMPLETE    |
| 7B    | which-key                          | COMPLETE    |
| 7C    | Statusline                         | COMPLETE    |
| 7D    | Git signs                          | COMPLETE    |
| 7E    | Notifications                      | COMPLETE    |
| 8     | Navigation/editor workflow         | **CURRENT** |
| 9     | Treesitter / structural navigation | PLANNED     |
| 10    | LSP foundation                     | PLANNED     |
| 11    | Completion/snippets                | PLANNED     |
| 12    | Formatting/linting                 | PLANNED     |
| 13    | Language vertical slices           | PLANNED     |
| 14    | Git workflow                       | PLANNED     |
| 15    | LaTeX/research                     | PLANNED     |
| 16    | Health/diagnostics                 | PLANNED     |
| 17    | Beta stabilization                 | PLANNED     |
| 18    | Phase 2 experiments                | DEFERRED    |

---

# 28. Governing Principle

The roadmap should keep development focused without becoming a rigid specification that prevents better decisions.

The concise model is:

```text
BUILD THE FOUNDATION FIRST.

ADD ONE COHERENT CAPABILITY AT A TIME.

KEEP PRODUCTION SAFE.

FINISH V1 BEFORE CHASING OPTIONAL COMPLEXITY.

LET CURRENT REPOSITORY REALITY UPDATE THE ROADMAP.
```

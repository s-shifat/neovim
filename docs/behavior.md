# Editor Behavior

## Purpose

This document defines the intended user-facing behavior of the Neovim configuration.

It records:

* behavioral reference precedence;
* compatibility rules for historical configurations;
* current core editor behavior;
* keybinding and interaction expectations;
* UI and navigation philosophy;
* buffer behavior;
* diagnostics and completion expectations;
* formatting behavior;
* project-local behavior;
* language and research workflow expectations;
* Git, tmux, health, and AI interaction expectations.

This document describes **what the editor should feel like and how it should behave**.

It does not define:

* dependency ownership or packaging architecture;
* experiment and promotion procedure;
* testing procedure;
* mutable-state implementation;
* deployment;
* implementation scheduling.

Those belong in the other project documents.

## Related Documentation

- `docs/references.md` — canonical repository URLs and external references used for historical and upstream behavioral research.
- `docs/architecture.md` — architectural constraints that behavior must respect.
- `docs/roadmap.md` — implementation status of behaviors described here.

Repository locations for current, historical, and upstream behavioral references are maintained in `docs/references.md`.

---

# 1. Primary Behavioral Goal

The editor should provide much of the capability and convenience of a modern IDE while remaining understandable, keyboard-oriented, and visually restrained.

The target experience is:

> **IDE capability without persistent clutter.**

The editor should feel familiar to the user's previous LunarVim/Neovim environment without reproducing LunarVim internally.

Behavioral familiarity matters particularly for:

```text
options
keybindings
navigation
buffers
search
editor interaction
diagnostics
UI conventions
language workflows
```

Implementation details may change substantially when a cleaner modern solution exists.

---

# 2. Behavioral Reference Precedence

When deciding how an editor feature should behave, use the following precedence:

```text
1. Explicit current project decisions
                ↓
2. Historical personal LunarVim configuration
                ↓
3. Historical personal standalone Neovim configuration
                ↓
4. Upstream LunarVim defaults where personal config was silent
                ↓
5. Current native Neovim capabilities
                ↓
6. Current mature plugin ecosystem
```

This ordering is especially important for:

```text
core options
keybindings
leader mappings
navigation
buffer behavior
UI defaults
Telescope behavior
diagnostics
statusline expectations
file-management behavior
```

A newer implementation mechanism does not automatically override an intentional familiar behavior.

---

# 3. Current Decisions Always Win

Historical behavior is evidence, not absolute authority.

If a current project decision explicitly changes an old behavior, the current decision wins.

For example:

```text
historical Fish shell setting
        ↓
current decision:
inherit the user's shell environment
```

or:

```text
historical Neovim tabline
        ↓
current decision:
use browser-like buffers instead
```

Historical configuration should never force the project to violate a newer architectural or behavioral decision.

---

# 4. Behavioral Compatibility vs Implementation Compatibility

Historical configuration is primarily a **behavioral specification**.

Preserve where appropriate:

```text
what a key does

how navigation feels

which actions are easy to reach

what information is visible

how buffers behave

how search is resumed

which editor defaults feel familiar
```

Do not automatically preserve:

```text
old plugin managers

deprecated APIs

obsolete plugins

runtime dependency installers

plugin-specific implementation details

historical workarounds that are no longer necessary
```

The question should be:

> How do we reproduce or improve the intended behavior cleanly with the current stack?

not:

> How do we recreate the old configuration line-for-line?

---

# 5. Behavioral Research Sequence

Before implementing or redesigning a significant editor behavior, use this sequence:

```text
current project decisions
        ↓
historical personal LunarVim config
        ↓
historical personal Neovim config
        ↓
upstream LunarVim defaults if relevant
        ↓
current native Neovim behavior
        ↓
current mature plugins if needed
        ↓
choose the simplest reliable implementation
```

This sequence is particularly important when introducing a feature for the first time.

---

# 6. Plugin Replacement Rule

Historical plugins are references to desired behavior, not automatic permanent dependencies.

When considering a historical plugin:

```text
inspect historical configuration
        ↓
identify user-facing behavior
        ↓
determine whether the plugin remains mature
        ↓
check native Neovim capability
        ↓
check mature alternatives
        ↓
choose lowest-complexity reliable option
```

Do not replace familiar working behavior simply because a newer plugin exists.

A replacement should provide a concrete advantage such as:

```text
better maintenance
simpler implementation
fewer dependencies
better native integration
improved reliability
materially better UX
```

---

# 7. Current Core Baseline

The current plugin-free core establishes the default editing experience.

Current behavior includes:

```text
hybrid line numbers

current line highlighted

sign column always available

2-space indentation

smart indentation

smart-case searching

system clipboard integration

mouse enabled

splits open below/right

wrapping disabled by default

scroll context around the cursor

block virtual editing

live substitution preview

confirmation before destructive unsaved actions where supported

persistent undo disabled

swap/backup files disabled

spell language = en_US

spell checking disabled by default

project-local exrc support enabled
```

The core should remain useful even when all optional plugins are unavailable.

---

# 8. Current Core Option Contract

The current settled core options are:

```text
number=true
relativenumber=true
numberwidth=2
cursorline=true
signcolumn=yes

cmdheight=1
showmode=true
termguicolors=true
conceallevel=0

expandtab=true
tabstop=2
shiftwidth=2
softtabstop=2
autoindent=true
smartindent=true

hlsearch=true
ignorecase=true
smartcase=true

mouse=a
clipboard=unnamedplus

swapfile=false
backup=false
writebackup=false
undofile=false

confirm=true
wrap=false
scrolloff=12
sidescrolloff=8
virtualedit=block
inccommand=split

completeopt=menuone,noselect
pumheight=10
timeoutlen=800
updatetime=300

splitbelow=true
splitright=true

spelllang=en_us
spell=false

exrc=true
```

These values may evolve deliberately, but they currently represent accepted editor behavior rather than arbitrary defaults.

---

# 9. Historical Behaviors Intentionally Not Carried Forward

Several historical settings were deliberately rejected or deferred.

## Shell

Do not hard-code:

```text
fish
```

or another specific shell.

Neovim should inherit the user's environment.

---

## Explicit UTF-8 fileencoding

Do not preserve the old global:

```text
fileencoding=utf-8
```

merely for historical compatibility when modern Neovim already provides the intended behavior.

---

## Native tabline as buffer UI

Do not treat native Neovim tabpages as the normal browser-style buffer interface.

A dedicated buffer UI is the target.

---

## Hyphenated word semantics

Do not globally add:

```text
iskeyword+=-
```

The current decision is to retain normal Neovim word semantics.

---

## Premature netrw removal

Do not disable netrw merely because a future file explorer is expected.

The existing fallback should remain available until a real replacement is present.

---

## Always-visible whitespace

Visible whitespace is not enabled globally by default.

A discoverable toggle may be added later.

---

## Persistent undo

Persistent undo remains disabled unless explicitly reconsidered.

If enabled later, its state handling must follow the state-isolation policy.

---

# 10. Keybinding Philosophy

The keybinding model is:

```text
normal Vim grammar
+
small familiar convenience mappings
+
mnemonic leader namespaces
+
which-key-style discovery
```

The project should not replace normal Vim interaction with a completely foreign shortcut system.

Historical muscle memory should be preserved where it remains useful.

Leader mappings should be:

```text
predictable
mnemonic
discoverable
described
```

Keymaps should include useful `desc` metadata so discovery tools and future maintainers can understand their purpose.

---

# 11. Current Core Keybindings

Current native mappings include:

```text
Space
→ leader and local leader

<leader>w
→ save

<leader>q
→ quit current window

<leader>c
→ safe buffer close

<leader>h
→ clear search highlight

Ctrl-h/j/k/l
→ split navigation

Ctrl-arrow keys
→ resize splits

Shift-h/l
→ previous / next buffer

jj
→ leave Insert mode

Alt-j/k
→ move current line

Alt-j/k in Visual mode
→ move selected text

< / > in Visual mode
→ indent while preserving selection

p in Visual mode
→ paste without replacing the yank register

Ctrl-h/j/k/l in terminal mode
→ leave terminal input and navigate windows
```

Future plugin-backed mappings should extend this vocabulary rather than arbitrarily replacing it.

---

# 12. Safe Buffer Closing

Closing a buffer must protect unsaved work and preserve the window layout where practical.

`<leader>c` therefore should not behave like a blind:

```text
:bd
```

The intended behavior is:

```text
buffer modified?
        ↓
yes
        ↓
Save / Discard / Cancel

then
        ↓
select another appropriate listed buffer if possible
        ↓
reuse the current window
        ↓
delete the old buffer
```

Closing a buffer should not unnecessarily destroy a split.

This behavior should remain compatible with the eventual browser-like buffer interface.

---

# 13. Core Automatic Behavior

The plugin-free core intentionally keeps automatic behavior limited.

Current core automatic behavior includes:

```text
brief yank feedback

q closes selected temporary core windows

splits rebalance after outer terminal resize
```

Automatic behavior should generally belong to the feature that owns it.

For example:

```text
format-on-save
→ formatting layer

LSP attach behavior
→ LSP layer

language-specific autocmds
→ language layer
```

Avoid accumulating unrelated automatic behavior in the core.

---

# 14. UI Philosophy

Persistent UI should remain relatively restrained.

The expected persistent interface includes approximately:

```text
statusline

browser-like buffer bar

Git gutter

diagnostic signs / underlines

subtle LSP status
```

Heavier interfaces should normally appear on demand:

```text
file explorer

Telescope

symbols

LazyGit

diagnostic list

notification history

health view

terminal

sessions
```

The editor should expose substantial capability without permanently occupying the screen with panels.

---

# 15. Theme and Appearance

The default visual direction is:

```text
Catppuccin Mocha
```

Catppuccin is the default theme, not the conceptual definition of the theme system.

The user should remain able to select other installed colorschemes without redesigning the configuration.

Desired appearance includes:

```text
dark default theme

Catppuccin-style emphasis

Nerd Font icon support

moderate information density

no animation requirement

readability over decoration
```

Automatic light/dark switching is not required.

Theme behavior should remain replaceable and should not create a hard dependency between unrelated UI components.

---

# 16. Statusline Behavior

The statusline should provide useful information without becoming a dense debugging dashboard.

Desired density is:

```text
moderate
```

Persistent information should favor useful summary state.

For LSP, prefer a compact representation such as:

```text
LSP
```

rather than continuously displaying long server names.

Detailed server information belongs in explicit inspection/health interfaces.

A Python environment indicator may be displayed for Python buffers if it can be done simply and reliably.

---

# 17. Diagnostics Behavior

Diagnostics should resemble a restrained modern IDE experience.

Default presentation:

```text
signs
yes

underlines
yes

icons
yes where appropriate

inline diagnostic prose
no by default
```

Detailed messages should be available through explicit actions such as:

```text
hover

diagnostic list

explicit command
```

The goal is:

```text
visible problem location
+
details on demand
```

rather than constant blocks of diagnostic text inside source code.

Explicit current diagnostic policy overrides historical LunarVim defaults when they differ.

---

# 18. Notifications

Notifications may appear as small transient popups.

There should also be an inspectable notification history.

Desired model:

```text
small popup
+
history command/window
```

Optional dependency failures should be visible without making the editor unusable.

Where simple, a missing optional dependency should normally avoid spamming the same warning repeatedly throughout one Neovim session.

Do not introduce complicated deduplication machinery merely to suppress a small number of duplicate messages.

---

# 19. Navigation

Fuzzy navigation is a first-class workflow.

Telescope is the primary fuzzy-search and discovery interface.

Desired capabilities include:

```text
project files
general files
live grep
type/glob/directory constrained searches
buffers
recent files
open files
help
keymaps
diagnostics
later Treesitter symbols
later LSP symbols/references
```

Resume is a first-class action. File, content, buffer, recent-file, config, and
diagnostic pickers start with a useful preview visible. Compact selection
pickers may omit it.

A search should not feel permanently lost merely because one result was selected.

The initial search namespace is:

```text
<leader>sp  project files at the Git root, or cwd outside Git
<leader>sf  files from cwd
<leader>st  live grep with interactive ripgrep arguments
<leader>sw  current-word or visual-selection grep
<leader>s/  grep open files
<leader>sb  buffers
<leader>sr  resume
<leader>s.  recent files
<leader>sh  help
<leader>sk  keymaps
<leader>ss  Telescope builtins
<leader>sn  editable Neovim config source when available
<leader>sd  diagnostics
```

`<leader>su` owns Telescope interface/search controls. `<leader>sup` hides or
restores the preview only from Telescope Normal mode, leaving Space available
for query input in Insert mode. `<leader>sua` finds all files and `<leader>sug`
greps all content with ignored and hidden paths included deliberately.

Ordinary file and text searches include useful hidden project files, respect
project ignore rules, and exclude common environment/cache trees and lock
files at the `fd`, `rg`, or Git command boundary. The all-files/all-grep controls
are the explicit escape hatch for suppressed paths.

Search scope should avoid noisy environment and cache trees without globally
hiding legitimate project content. Project-owned ignore rules and
configuration remain authoritative where appropriate.

## Symbols / Outline

Symbols should provide a structural outline and integrate with Telescope for
fuzzy navigation. This interface is expected only after a structural backend
such as Treesitter exists; it is not currently implemented. LSP may enrich it
later.

---

# 20. File Exploration

The selected file-exploration model is:

```text
Snacks Explorer
→ daily left-side project tree

Oil
→ secondary on-demand editable filesystem interface
```

These are optional navigation and filesystem surfaces rather than the
foundation of file editing.

Expected behavior:

```text
reveal current file
normal filesystem operations
replaceability
basic editing does not depend on the explorer
```

Snacks Explorer is the daily project tree. `<leader>e` opens it at the Git
repository root (or cwd outside Git), focuses it when it is already open, and
closes it when it is focused. It is a standalone mapping rather than an
Explorer namespace. The tree stays open after a file is selected, returns focus
to the editing window, and follows ordinary buffer navigation only while it is
already open.

The Explorer is a complete filesystem view: hidden and Git-ignored entries are
shown by default. Its upstream toggles may temporarily narrow either category,
but Telescope's curated ordinary-search exclusions do not apply to the tree.
The left sidebar includes icons, Git status, diagnostics, and the standard
Snacks create, rename, delete, move, and copy operations. Snacks Explorer also
owns normal directory opening, including `nvim .`, through its supported netrw
replacement mechanism.

Explorer-local `V` and `B` open the selected file in vertical and horizontal
splits respectively. `<S-CR>` uses Snacks' native window picker to choose an
eligible target window before opening the selection. These do not replace
lowercase `v` or `b`, or the corresponding keys in ordinary editor buffers.

Snacks Picker is enabled only as Explorer infrastructure. Explorer-local
Picker grep and terminal shortcuts are disabled, and the established
Telescope `<leader>s...` workflow remains the user-facing search system.

Opening a supported image or PDF normally from Explorer displays it in a
Snacks image buffer inside Neovim. Explorer-local `o` remains the distinct
system-application action. This direct-file viewer uses Kitty Graphics
Protocol terminal support and Nix-owned conversion tools; it does not enable
inline images or math rendering in document source buffers. While a direct
image view remains open, a parent-directory filesystem watcher refreshes it
after same-path rewrites or atomic replacements. This supports generated plots
without closing and reopening the buffer and also applies to regenerated PDFs.
On first open, source metadata is compared with isolated persistent state so
changes made between Neovim sessions invalidate only that source's derived
Snacks artifacts before rendering. Unchanged sources keep their valid cache.
Direct image/PDF buffers are view-only: external updates refresh silently and
do not leave a modified buffer, while ordinary text buffers retain Neovim's
normal external-change and unsaved-edit safeguards. Switching to ordinary
buffers may hide the terminal placement; returning to the viewer restores its
existing placement without reopening or reconverting the source.

Neither interface should be so deeply coupled to other configuration that
replacing it becomes difficult. Basic fallback file navigation should remain
usable.

---

# 21. Buffer Model

The project does not treat Neovim tabpages as ordinary browser-style editor buffers.

The target model is:

```text
visible browser-like buffer bar
+
fuzzy picker containing all buffers
+
safe handling of modified buffers
+
natural buffer selection after close
```

The visible buffer bar may show the most relevant/recent buffers as space allows.

All buffers should remain discoverable through the buffer picker.

Closing a buffer should produce sensible adjacent/MRU behavior and preserve window structure where practical.

---

# 22. Splits and tmux Navigation

Neovim owns editor splits.

tmux owns long-running terminal workloads.

Desired directional behavior is:

```text
Ctrl-h/j/k/l
```

for movement across:

```text
Neovim split boundaries
and
tmux pane boundaries
```

without requiring different muscle memory.

The intended experience is seamless directional navigation.

The quick Neovim terminal should be a toggleable bottom horizontal panel,
opened in the current project or working directory, for:

```text
quick command
small test
short shell interaction
```

tmux remains the durable terminal and process environment for long-lived
shells, agents, REPLs, logs, and other processes.

Snacks image rendering through tmux depends on Kitty Graphics Protocol
passthrough. Snacks attempts to enable pane-local passthrough, but a future
tmux integration should verify whether the user's external tmux configuration
also needs `allow-passthrough` rather than owning that setting here.

---

# 23. Session Behavior

Neovim sessions are part of the intended editor experience. Their design must
consider project identity and project-root behavior before selecting an
implementation.

They should restore useful editor state without pretending to preserve operating-system processes.

A later project-aware tmux workflow should reconstruct an environment such as:

```text
project
├── tmux layout
├── shell
├── Neovim
├── agent
└── optional REPL/Jupyter process
```

rather than claiming that those processes survived a reboot.

Session persistence must also follow the state-isolation policy.

---

# 24. Completion and Snippets

Completion should be proactive.

Desired behavior:

```text
completion menu appears automatically/aggressively

Tab
→ accept selected completion

Esc
→ dismiss completion

snippets
→ appear in the same completion interface

snippet expansion
→ occurs only when the snippet is selected
```

The completion UI should feel unified rather than requiring separate mental models for LSP suggestions and snippets.

AI completion is not part of deterministic completion behavior.

If AI completion is introduced later, it should preferably remain visually distinguishable from LSP/snippet completion.

---

# 25. Formatting

Formatting should default to:

```text
format on save
```

when appropriate for the file/project.

The critical rule is:

> One authoritative formatter pipeline per file/buffer/project.

Avoid competing simultaneous formatting paths such as:

```text
LSP formatter
+
separate formatter integration
+
another external formatter
```

Project configuration may override global defaults.

Examples include:

```text
pyproject.toml

.editorconfig

project-specific formatter configuration
```

The editor should cooperate with the project's formatter choice rather than impose an unrelated global one.

---

# 26. Project-Local Editor Behavior

Global configuration provides sensible defaults.

Projects may specialize those defaults.

Native trusted:

```text
.nvim.lua
```

is the preferred mechanism for Neovim-specific local overrides.

Portable collaborative conventions should use:

```text
.editorconfig
```

Tool-specific project files remain authoritative.

Examples:

```text
pyproject.toml

latexmkrc

Makefile

language-specific configuration
```

A private `.nvim.lua` does not need to be committed to a collaborator's repository; it may be excluded locally where appropriate.

---

# 27. Project Environment

Neovim should operate inside the same project environment as the shell and tmux.

Conceptually:

```text
project environment
├── Neovim
└── shell / tmux
```

Neovim should not quietly construct a competing package/environment world.

For example, Python project packages belong to the project environment, not to Neovim itself.

Automatic environment orchestration may be added later if it remains transparent and reliable.

---

# 28. Python

Python is a first-class language.

Neovim should support Python development well without becoming a Python package manager.

Preferred environment priority is broadly:

```text
Nix devShell
        ↓
project .venv
        ↓
Conda / legacy environment where needed
```

Interpreter selection should eventually be convenient, similar to an IDE interpreter picker.

Normal shell/project execution remains canonical.

Neovim may expose convenient run actions, but should not create a hidden parallel Python environment.

---

# 29. Python Scientific Workflow

Scientific Python enhancements are useful but are not required to define basic Python editing.

Desired later capabilities include:

```text
.py files with # %% cells

simple cell execution

dedicated output pane/window where mature

external plots/browser where appropriate

optional DataFrame viewing

Jupytext/Jupyter integration
```

Direct rich `.ipynb` editing is not a core requirement.

A variable explorer is low priority.

Scientific integration should build on normal project environments rather than replace them.

---

# 30. LaTeX and Research Writing

LaTeX is a first-class workflow.

Desired behavior includes:

```text
VimTeX-style workflow

main.tex/root detection

multi-file projects

continuous compilation started explicitly

easy compilation control

latexmk

project latexmkrc / Makefile authority

pdflatex and LuaLaTeX support

PDF viewer integration

SyncTeX forward search

SyncTeX inverse search

bibliography search

snippets

spell checking

style/grammar assistance where mature
```

Compiler output is authoritative for compilation failures.

LSP diagnostics supplement compiler output; they do not replace it.

The editor should support serious multi-file research writing rather than treating LaTeX as plain text with syntax highlighting.

Snacks image support can potentially render referenced images and math inside
LaTeX source, but both remain intentionally disabled until this workflow is
designed. Its current direct PDF view is only a quick in-editor preview; the
later workflow must still evaluate VimTeX, an external research-oriented PDF
viewer, and SyncTeX forward/inverse search without assuming Snacks replaces
them.

---

# 31. Markdown

Markdown enhancement should remain moderate.

Useful behavior includes:

```text
good heading editing

checkbox support

table usability

modest conceal/cosmetics

toggleable spelling
```

Source editing should remain recognizable as Markdown source.

Do not turn the normal editing buffer into a heavily rendered document.

Full rendered preview should generally be external/browser-based.

After the relevant Treesitter and document-language infrastructure exists,
optional Snacks inline images may be reconsidered for Markdown. HTML and other
supported document formats may be evaluated when they become relevant, but
document rendering must remain optional and unnecessary for ordinary editing.

---

# 32. Deferred Notes Workflow

A personal notes workflow is a desired Phase 2 capability.

It is **not currently implemented** and should not be pulled into V1 work merely because the behavior is documented here.

The target model is intentionally simple:

```text
plain Markdown notes

normal Markdown links

modular folders under ~/notes

project notes under ~/notes/projects/<ProjectName>/

timestamps and project metadata where useful

fast note capture
```

The notes system should remain based on ordinary files rather than introducing an opaque editor-specific database.

A future quick-capture workflow may integrate the desktop environment with Neovim.

Desired interaction:

```text
Hyprland shortcut
        ↓
open a small floating Neovim note
        ↓
enter Insert mode
        ↓
write note
        ↓
save / close
        ↓
return to previous desktop context
```

This workflow crosses several system boundaries:

```text
Neovim
Hyprland
shell
filesystem
storage / synchronization
```

Those responsibilities should remain explicit.

Neovim should own note editing behavior.

The desktop environment or launcher should own how the note window is invoked.

The filesystem should remain the canonical storage layer.

Synchronization, if introduced, should remain an external storage concern rather than hidden Neovim state.

The notes workflow should preserve the project's broader principles:

```text
plain files over opaque state

normal Markdown over proprietary note formats

project-aware organization

fast capture without forcing a permanent UI

replaceable integrations

basic editing remains independent of the notes system
```

Implementation timing belongs in:

```text
docs/roadmap.md
```

---


# 33. Git

Git remains real Git.

Neovim may provide convenient interfaces for:

```text
gutter signs

hunks

blame

diffs

LazyGit
```

but those interfaces should expose ordinary Git state rather than replace it with editor-specific state.

Users should remain able to understand and inspect repository state using normal Git tools.

The persistent Git-sign layer provides gutter indicators and buffer-local hunk
actions without adding a broader repository-management interface:

```text
<leader>gj
→ next hunk

<leader>gk
→ previous hunk

<leader>gp
→ preview hunk

<leader>gs
→ stage hunk (or selected lines in Visual mode)

<leader>gr
→ reset hunk (or selected lines in Visual mode)

<leader>gu
→ undo staged hunk
```

Current-line blame remains disabled. The statusline may summarize added,
changed, and removed lines while leaving the existing branch display intact.

---

# 34. Health and Inspection

The editor should provide an explicit, inspectable health interface for detailed system state.

Useful information includes:

```text
active LSPs

available external tools

selected formatter

Python environment

missing optional dependencies

Treesitter parser status

Git tooling status
```

Persistent UI should remain concise.

Detailed operational information belongs in an on-demand health/status interface.

Cheap health information may be checked automatically.

Expensive diagnostics should generally be explicit.

---

# 35. AI and Agents

AI should remain optional to basic editing.

The preferred agent model is:

```text
project-specific agent
+
tmux pane/window
```

so the agent can survive Neovim restarts and remain part of the wider project environment.

Neovim may later provide thin conveniences for sending context such as:

```text
current file path

visual selection

diagnostics

Git diff
```

to an external agent.

The editor should not:

```text
require AI for normal editing

silently rewrite files using AI

hide AI modifications from normal filesystem/Git review
```

If AI completion is introduced, it should remain distinguishable from deterministic editor completion where practical.

---

# 36. Optional Failure Behavior

Optional integrations should degrade gracefully.

Examples:

```text
Telescope unavailable
→ basic editing still works

Git UI unavailable
→ Git repository remains usable

LSP unavailable
→ file editing still works

formatter missing
→ save/editing still works with a visible warning where appropriate

notification UI unavailable
→ editor remains usable

symbols UI unavailable
→ editing remains usable
```

A failed convenience feature should not unnecessarily become a failed editor.

---

# 37. Discoverability

Powerful behavior should remain discoverable.

The intended model includes:

```text
mnemonic leader mappings

keymap descriptions

which-key-style discovery

fuzzy search

explicit health/status interfaces
```

The editor should support muscle memory without requiring the user to memorize every command before a feature becomes usable.

Discoverability should not require permanently displaying large help panels.

---

# 38. Visual Restraint

The configuration should prefer useful visual information over decoration.

Desired characteristics include:

```text
moderate density

clear diagnostics

useful Git indicators

readable status

icons where helpful

limited persistent panels

no requirement for animations

on-demand detailed interfaces
```

Visual additions should justify their persistent screen space.

---

# 39. Behavior vs Roadmap

This document records desired behavior even when the implementation does not yet exist.

Therefore a behavioral requirement appearing here does **not** necessarily mean the feature is currently implemented.

For implementation status and sequencing, consult:

```text
docs/roadmap.md
```

Examples of target behavior that may be implemented later include:

```text
browser-like buffer bar

Telescope workflow

seamless tmux navigation

completion/snippets

format-on-save architecture

full Python support

full LaTeX workflow

health interface

Phase 2 notes workflow
```

Before modifying code, inspect the current repository rather than assuming every behavior documented here already exists.

---

# 40. Behavior Review Checklist

When implementing a new editor feature, determine:

```text
1. Is there an explicit current decision?

2. Did the historical LunarVim config define this behavior?

3. Did the later standalone Neovim config refine it?

4. If neither did, what did upstream LunarVim provide?

5. What user-facing behavior actually mattered?

6. Can current native Neovim reproduce it cleanly?

7. If a plugin is required, what is the simplest mature option?

8. Does the proposed behavior preserve familiar muscle memory?

9. Does it add persistent visual clutter unnecessarily?

10. Does it cooperate with project-local configuration?

11. Can the feature fail without breaking basic editing?

12. Is the implementation being confused with the behavioral requirement?
```

The final implementation should preserve the intended behavior without carrying unnecessary historical machinery forward.

---

# 41. Behavioral Invariants

The following should remain true unless deliberately revised.

1. Current explicit decisions override historical defaults.

2. Historical LunarVim is the primary behavioral reference.

3. Historical standalone Neovim is the secondary personal reference.

4. Upstream LunarVim fills gaps where personal historical configuration was silent.

5. Historical behavior should be understood before selecting a modern implementation.

6. Familiar editor muscle memory should be preserved where it remains useful.

7. Normal Vim grammar remains fundamental.

8. Leader mappings should remain mnemonic and discoverable.

9. Buffer handling must protect unsaved work.

10. Buffer UI should represent buffers rather than pretending tabpages are buffers.

11. Persistent UI should remain relatively uncluttered.

12. Detailed information should usually be available on demand.

13. Diagnostics should use signs/underlines with prose on demand by default.

14. Completion should be automatic, with Tab acceptance and Esc dismissal.

15. Snippets should participate in the same completion interface.

16. Formatting should have one authoritative path per project/buffer.

17. Project configuration should override global defaults where appropriate.

18. Neovim should share the project's environment rather than create a hidden competing one.

19. Telescope-style fuzzy navigation is a first-class workflow.

20. Search/picker context should be resumable.

21. File exploration should remain replaceable and non-essential to basic editing.

22. Neovim splits and tmux panes should eventually share directional navigation muscle memory.

23. Python is first-class without Neovim becoming a Python package manager.

24. LaTeX is a first-class research-writing workflow.

25. Git integrations remain interfaces over real Git.

26. AI remains optional and externally inspectable.

27. Optional feature failure should not unnecessarily destroy basic editing.

28. Visual complexity must justify its persistent screen space.

29. A future notes workflow should use ordinary Markdown files and explicit system boundaries rather than opaque editor-owned storage.

---

# 42. One-Screen Behavior Model

```text
                 CURRENT DECISION
                        │
                        ▼
              historical references
                        │
            ┌───────────┴───────────┐
            │                       │
      preserve behavior       modernize mechanism
            │                       │
            └───────────┬───────────┘
                        │
                        ▼
                 editor experience
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
   familiar Vim      IDE capability   low clutter
   interaction          where useful
        │               │                │
        └───────────────┼────────────────┘
                        │
                        ▼
             project-aware behavior
                        │
                        ▼
               graceful degradation
```

---

# 43. Governing Principle

The editor should feel familiar without being trapped by its historical implementation.

The concise model is:

```text
PRESERVE INTENT.
PRESERVE MUSCLE MEMORY.

MODERNIZE IMPLEMENTATION.

KEEP CAPABILITY HIGH.
KEEP CLUTTER LOW.

LET PROJECT CONFIGURATION WIN.
LET OPTIONAL FEATURES FAIL GRACEFULLY.
```

# Stable and Experimental State Isolation

## Purpose

This document defines the mutable-state isolation policy between production Neovim and the experimental Neovim environment.

The central invariant is:

> Experimental editor state must not contaminate production editor state.

This policy applies to Neovim's own mutable state and to mutable state created by plugins or future editor features.

## Related Documentation

- `docs/architecture.md` — architectural requirement for stable/experimental separation.
- `docs/testing.md` — regression-testing policy for state isolation.
- `docs/workflow.md` — how stable and experimental environments are used during development.
- `docs/references.md` — canonical project and upstream Neovim repository locations.

Relevant repository and upstream technical references are maintained in `docs/references.md`.

---

# 1. Application Identities

Production Neovim uses the normal Neovim application identity:

```text
nvim
```

The experimental editor is launched with:

```text
NVIM_APPNAME=nvim-next
```

This gives stable and experimental Neovim different XDG-derived application directories.

Conceptually:

```text
stable
NVIM_APPNAME=<normal nvim identity>

experimental
NVIM_APPNAME=nvim-next
```

The different application identities are the foundation of mutable-state isolation.

---

# 2. Why Isolation Exists

The experimental editor is intentionally allowed to change rapidly.

It may contain:

* incomplete configuration;
* new plugins;
* different plugin versions;
* changed editor behavior;
* experimental persistence;
* broken or abandoned features.

Production Neovim must remain dependable even when an experiment fails.

Therefore mutable editor state should not flow freely between:

```text
nvim
```

and:

```text
nvim-next
```

A broken experimental cache, database, session, history, or plugin state must not silently damage production behavior.

---

# 3. Neovim `stdpath()` Isolation

Neovim derives important application directories from its application identity.

The important state classes are:

| State class | Stable                         | Experimental                        |
| ----------- | ------------------------------ | ----------------------------------- |
| config      | `stdpath("config")` for `nvim` | `stdpath("config")` for `nvim-next` |
| data        | `stdpath("data")` for `nvim`   | `stdpath("data")` for `nvim-next`   |
| state       | `stdpath("state")` for `nvim`  | `stdpath("state")` for `nvim-next`  |
| cache       | `stdpath("cache")` for `nvim`  | `stdpath("cache")` for `nvim-next`  |

Because the application names differ, these paths must resolve to different locations.

The architecture depends on this separation.

---

# 4. Configuration Path vs Configuration Source

`stdpath("config")` describes the mutable XDG configuration location associated with the Neovim application identity.

It does **not** mean that production Neovim loads its actual configuration from that writable directory.

Production configuration is packaged immutably by Nix.

Conceptually:

```text
production nvim
    ↓
immutable packaged config in Nix store
```

Experimental Neovim instead loads configuration live from the active experiment worktree.

Conceptually:

```text
nvim-next
    ↓
dev/init.lua
    ↓
active worktree config/
```

Therefore configuration-source isolation and mutable-XDG isolation are related but distinct concepts.

---

# 5. Data Directory

Mutable application data should normally use:

```lua
vim.fn.stdpath("data")
```

Examples of data that may belong here include plugin-managed persistent data that is not better classified as state or cache.

A plugin that naturally uses `stdpath("data")` inherits stable/experimental isolation automatically.

Do not replace this with a hard-coded normal-Neovim path such as:

```text
~/.local/share/nvim/...
```

when the data is editor-specific and should remain isolated.

---

# 6. State Directory

Persistent editor state should normally use:

```lua
vim.fn.stdpath("state")
```

This is the preferred base for state that should survive editor restarts but remain specific to the Neovim application identity.

Examples may include:

```text
sessions
persistent undo
histories
plugin databases
persistent indexes
generated metadata
other editor-specific persistent state
```

When introducing a stateful feature, prefer a subdirectory derived from `stdpath("state")`.

For example:

```lua
vim.fn.stdpath("state") .. "/sessions"
```

or:

```lua
vim.fn.stdpath("state") .. "/undo"
```

This preserves stable/experimental isolation automatically.

---

# 7. Cache Directory

Regenerable editor/plugin cache data should normally use:

```lua
vim.fn.stdpath("cache")
```

Examples include:

```text
generated caches
temporary indexes
derived metadata
performance caches
```

Experimental cache data should not be written into the production Neovim cache tree.

If a plugin hard-codes the normal `nvim` cache path, configure it explicitly when possible.

---

# 8. ShaDa

ShaDa stores persistent Neovim history/state such as marks, registers, command history, and related information.

When `shadafile` is not explicitly overridden, the effective default is derived from:

```text
stdpath("state")
```

and normally resides under:

```text
stdpath("state")/shada/main.shada
```

Because stable and experimental `stdpath("state")` values differ, their ShaDa files are naturally isolated.

Do not later introduce a shared hard-coded ShaDa file between `nvim` and `nvim-next`.

For example, avoid forcing both environments to use:

```text
~/.local/state/nvim/shada/main.shada
```

---

# 9. Sessions

Persistent sessions are editor-specific mutable state.

When session support is introduced, session files should be placed below a location derived from:

```lua
vim.fn.stdpath("state")
```

For example:

```lua
vim.fn.stdpath("state") .. "/sessions"
```

This ensures:

```text
stable sessions
≠
experimental sessions
```

Do not hard-code a shared session directory unless sharing is explicitly designed, justified, and documented.

---

# 10. Persistent Undo

Persistent undo is not currently part of the core editor configuration.

If it is introduced later, its storage must preserve application isolation.

Preferred base:

```lua
vim.fn.stdpath("state")
```

For example:

```lua
vim.fn.stdpath("state") .. "/undo"
```

Avoid hard-coded paths such as:

```text
~/.local/state/nvim/undo
```

because experimental Neovim would then risk sharing production undo state.

---

# 11. Plugin-Generated Mutable State

Plugins may create mutable state that is not immediately visible from the Lua configuration.

Examples include:

```text
databases
histories
indexes
sessions
caches
generated metadata
bookmarks
navigation history
plugin-specific persistent files
```

Every stateful plugin should be evaluated when introduced.

Preferred behavior is that the plugin naturally uses one of:

```lua
vim.fn.stdpath("data")
vim.fn.stdpath("state")
vim.fn.stdpath("cache")
```

If so, `NVIM_APPNAME` normally provides isolation automatically.

If the plugin instead allows a custom path, configure that path from an appropriate `stdpath()` value.

If a plugin hard-codes normal `nvim` XDG locations and cannot be configured safely, the plugin should be:

```text
overridden
reconsidered
or rejected
```

before promotion.

---

# 12. Stateful Feature Review

Adding a plugin does not automatically require new state-isolation configuration.

The relevant question is:

> Does this feature introduce editor-specific mutable state?

For every potentially stateful feature, determine:

```text
What mutable files does it create?

Where are they stored?

Are those paths derived from NVIM_APPNAME-aware stdpath() values?

Would nvim and nvim-next write to the same location?

Could experimental corruption or schema changes affect production?
```

Only configure additional isolation where necessary.

Do not add custom state directories merely as a precaution when the feature already follows Neovim's isolated standard paths.

---

# 13. Intentionally Shared Resources

Stable and experimental Neovim may intentionally share resources that are not application-specific mutable editor state.

Examples include:

```text
project files
Git repositories
project-local configuration
system clipboard
shell environment
external project environments
immutable Nix store dependencies
language project files
build artifacts owned by the project rather than Neovim
```

Sharing these resources is generally expected.

For example:

```text
nvim
        ┐
        ├── edit the same Git repository
nvim-next
        ┘
```

is normal.

---

# 14. Project-Owned State vs Editor-Owned State

Not every mutable file touched while using Neovim belongs to Neovim.

The useful distinction is:

```text
project-owned state
→ may be intentionally shared

editor-owned state
→ isolated by default
```

Examples of project-owned state include:

```text
source files
.git/
project .venv
project build outputs
project-local tool configuration
Nix devShell state external to Neovim
```

Examples of editor-owned state include:

```text
ShaDa
sessions
undo history
plugin databases
editor navigation history
editor caches
plugin indexes
```

Isolation policy applies primarily to the latter.

---

# 15. Immutable Dependencies May Be Shared

Stable and experimental Neovim may use the same immutable Nix store objects.

This is safe because those objects are not mutable editor state.

Conceptually:

```text
stable nvim ─────┐
                 ├── /nix/store/<immutable dependency>
nvim-next ───────┘
```

Sharing immutable dependencies does not violate state isolation.

The isolation requirement concerns writable state.

---

# 16. Experimental Bootstrap Safety Guard

The experimental bootstrap:

```text
dev/init.lua
```

must only run under the experimental application identity.

It therefore verifies that:

```text
NVIM_APPNAME=nvim-next
```

before continuing.

If the bootstrap is accidentally launched through normal Neovim identity, it should refuse to continue.

This prevents the experimental live configuration from being loaded while Neovim is using production mutable-state paths.

The guard protects against accidental contamination caused by launching the experimental bootstrap incorrectly.

---

# 17. Do Not Defeat `NVIM_APPNAME`

Future configuration should not manually force stable and experimental Neovim back into common XDG paths.

Avoid patterns such as:

```text
hard-coded ~/.local/share/nvim/...

hard-coded ~/.local/state/nvim/...

hard-coded ~/.cache/nvim/...

hard-coded ~/.config/nvim/...
```

for application-specific mutable state.

Prefer application-aware Neovim path derivation.

If a custom path is required, derive it from the appropriate `stdpath()` unless intentional sharing has been explicitly decided.

---

# 18. Environment Variables and External Tools

An external tool launched by Neovim may maintain its own state independently of Neovim's XDG paths.

Not every external tool therefore becomes isolated simply because:

```text
NVIM_APPNAME=nvim-next
```

is set.

When integrating an external program that creates editor-specific mutable state, determine whether its state should:

```text
remain shared as external/project state

or

be isolated between stable and experimental editor instances
```

Do not assume `NVIM_APPNAME` automatically controls software that does not use Neovim's `stdpath()` system.

---

# 19. Isolation Should Remain Minimal

Do not create a large custom isolation framework around Neovim.

The preferred architecture is:

```text
NVIM_APPNAME
        ↓
Neovim stdpath()
        ↓
natural XDG isolation
```

with explicit configuration only for software that does not naturally respect this model.

Use Neovim's native application identity mechanism first.

Custom environment variables, directory trees, wrappers, or state-migration systems should be introduced only when a concrete requirement proves they are necessary.

---

# 20. Regression Testing

Stable/experimental state separation is protected by:

```text
tests/state-isolation.sh
```

The test currently verifies separation of important application state including:

```text
application identity
config path
data path
state path
cache path
ShaDa path
```

Changes involving application identity or editor-specific mutable state should assess whether this regression test needs to be extended.

Detailed testing policy belongs in:

```text
docs/testing.md
```

The testing principle is:

> Extend the regression when a new state path creates a meaningful contamination risk, not merely because a new plugin exists.

---

# 21. State-Isolation Review Checklist

When adding a feature that persists mutable state, determine:

```text
1. What state does the feature create?

2. Who owns that state?
   - project
   - external tool
   - Neovim/plugin

3. Where is the state stored?

4. Does it naturally use stdpath()?

5. Does NVIM_APPNAME therefore isolate it?

6. If not, can its path be configured?

7. Should the state actually be shared?

8. Could experimental state corrupt or alter production behavior?

9. Does tests/state-isolation.sh need new coverage?
```

If the answers show no contamination risk, do not add unnecessary isolation machinery.

---

# 22. Isolation Invariants

The following should remain true unless deliberately redesigned.

1. Experimental Neovim uses:

```text
NVIM_APPNAME=nvim-next
```

2. Stable and experimental `stdpath("config")` locations differ.

3. Stable and experimental `stdpath("data")` locations differ.

4. Stable and experimental `stdpath("state")` locations differ.

5. Stable and experimental `stdpath("cache")` locations differ.

6. Stable and experimental ShaDa files remain separate.

7. Future editor-specific sessions remain separate.

8. Future persistent undo state remains separate.

9. Plugin-generated mutable editor state is isolated where appropriate.

10. Hard-coded normal-`nvim` XDG paths must not accidentally bypass isolation.

11. Shared project files and repositories are intentional and do not constitute editor-state contamination.

12. Immutable Nix dependencies may be shared safely.

13. `dev/init.lua` must refuse to run outside the experimental application identity.

14. New stateful features are reviewed individually rather than forcing all plugins into custom isolation infrastructure.

15. Isolation relies primarily on native `NVIM_APPNAME` and `stdpath()` semantics rather than a parallel custom state system.

---

# 23. One-Screen State Model

```text
                    SAME PROJECT FILES
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼

          stable                       experimental

           nvim                        nvim-next
             │                           │
             │                    NVIM_APPNAME=
             │                       nvim-next
             │                           │
             ▼                           ▼

     stdpath("data") A             stdpath("data") B
     stdpath("state") A            stdpath("state") B
     stdpath("cache") A            stdpath("cache") B
     ShaDa A                        ShaDa B
     sessions A                     sessions B
     plugin state A                 plugin state B

             │                           │
             └─────────────┬─────────────┘
                           │
                  may safely share:
                           │
                           ▼

                    project files
                    Git repository
                    clipboard
                    shell/project env
                    immutable Nix store
```

---

# 24. Governing Principle

The purpose of state isolation is not to duplicate the user's entire computing environment.

It is to prevent experimental editor state from becoming production editor state accidentally.

The concise model is:

```text
SHARE THE PROJECT.
SHARE IMMUTABLE SOFTWARE.

ISOLATE MUTABLE EDITOR STATE.

USE NVIM_APPNAME FIRST.
DERIVE PATHS FROM STDPATH().
```

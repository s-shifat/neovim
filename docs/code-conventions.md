# Code Conventions

## Purpose

This document defines implementation-level coding conventions for the standalone Neovim repository.

Its goal is to make implementation files:

- easy to inspect;
- easy to tweak;
- easy to review;
- easy for humans and coding agents to navigate;
- clearly separated between configuration and execution logic.

These are conventions, not rigid templates.

Prefer clarity over mechanical uniformity.

Do not restructure a small or unusual module merely to make it resemble other files if the result is less readable.

For concerns outside code organization and implementation style, use the owning document explicitly:

```text
Architecture and ownership boundaries
→ docs/architecture.md

Experiment/task/refactor scope and AI workflow
→ docs/workflow.md

Testing and validation expectations
→ docs/testing.md

User-facing editor behavior
→ docs/behavior.md

Mutable editor state and stable/experimental isolation
→ docs/state-isolation.md

Deployment boundaries
→ docs/deployment.md

Implementation sequencing and status
→ docs/roadmap.md

Canonical repository and upstream references
→ docs/references.md
```

---

# 1. Core Principle

Separate **configuration** from **execution**.

When opening a substantial plugin-backed Lua module, the user-tweakable parts should be easy to find near the top of the file without first reading lifecycle, error-handling, or wiring code.

Prefer this conceptual order:

```text
module declaration
→ user-tweakable configuration
→ related tweakable constants
→ mutable internal state
→ internal helpers
→ plugin lifecycle / setup
→ public behavior / mappings
→ return module
```

The exact layout may vary when another structure is clearer.

---

# 2. Plugin Configuration

## 2.1 Static Configuration

When a plugin exposes a conventional setup API such as:

```lua
require("plugin").setup({
  ...
})
```

prefer a named local configuration table near the top of the module:

```lua
local config = {
  option_a = true,

  option_b = {
    value = 123,
  },
}
```

Then pass that table into the setup call later:

```lua
local configured, setup_err = pcall(plugin.setup, config)
```

Prefer this over embedding a substantial configuration table directly inside:

```lua
pcall(plugin.setup, {
  ...
})
```

The intended result is that a maintainer can open the file and quickly answer:

> What can I intentionally tweak here?

without first reading implementation plumbing.

---

## 2.2 Runtime-Dependent Configuration

A static top-level table is not always appropriate.

If configuration depends on a runtime object that is only available after `require(...)`, prefer a small config builder:

```lua
local function make_config(plugin)
  return {
    feature = true,

    on_attach = function(bufnr)
      attach_mappings(plugin, bufnr)
    end,
  }
end
```

Then later:

```lua
local available, plugin = pcall(require, "plugin")

if not available then
  return
end

local configured, setup_err =
  pcall(plugin.setup, make_config(plugin))
```

Use this pattern when callbacks or config values genuinely depend on runtime objects.

Do not force runtime-dependent values into a static table merely for consistency.

---

## 2.3 Composed Configuration

Some subsystems are assembled from multiple configuration fragments.

For example:

```text
base plugin config
+ explorer config
+ image config
→ final config
```

Prefer making that composition explicit:

```lua
local base_config = {
  ...
}

local function make_config(explorer, image)
  return vim.tbl_deep_extend(
    "force",
    base_config,
    explorer,
    image
  )
end
```

Then keep setup separate:

```lua
local config = make_config(explorer, image)

local setup_ok, setup_error =
  pcall(plugin.setup, config)
```

Configuration construction and plugin initialization should remain conceptually distinct.

---

## 2.4 Keep Config Minimal

Configuration tables should represent intentional project decisions.

Do **not** copy upstream setup examples wholesale.

Prefer:

```lua
local config = {
  default_file_explorer = false,

  float = {
    max_width = 0.80,
    max_height = 0.75,
  },
}
```

over a large table that simply reproduces unchanged upstream defaults.

A maintainer should be able to assume:

> If this option appears in the repository config, the project intentionally chose or overrode it.

This keeps the code easier to audit and makes upstream default changes easier to reason about.

---

# 3. User-Tweakable Constants

Other intentionally adjustable values should also be easy to find near the configuration section.

Examples:

```lua
local debounce_ms = 150
local max_width = 0.80
local max_height = 0.75
local preview_delay_ms = 200
```

Keep these near the top when they represent deliberate tuning knobs.

Avoid scattering tweakable constants throughout helper functions unless local placement clearly improves readability.

---

# 4. Internal Mutable State

Keep mutable runtime state visually separate from configuration.

For example:

```lua
local config = {
  ...
}

local debounce_ms = 150

local initialized = false
local initialization_count = 0
local watcher = nil
```

The distinction should remain obvious:

```text
configuration / constants
→ values intentionally chosen by the user or project

runtime state
→ values the module changes while Neovim is running
```

Do not mix mutable runtime state into the user-tweakable config section.

---

# 5. Internal Helpers

Implementation details should normally live below configuration and state.

Examples include:

- filesystem watchers;
- project-root resolution;
- buffer/window lifecycle handling;
- notification helpers;
- cache invalidation;
- deferred initialization;
- attachment callbacks;
- mapping implementation helpers;
- cleanup logic.

This keeps the top of the file focused on what can be intentionally changed, while the lower sections explain how the feature works.

---

# 6. Lifecycle and Setup Logic

Dependency acquisition, initialization, and graceful setup handling should remain separate from the configuration itself.

A typical structure is:

```lua
local config = {
  ...
}

local function ensure_plugin()
  local available, plugin = pcall(require, "plugin")

  if not available then
    return
  end

  local configured, setup_err =
    pcall(plugin.setup, config)

  if not configured then
    return
  end

  return plugin
end
```

The coding convention here is structural:

```text
configuration
→ separate from
dependency acquisition
→ separate from
plugin initialization
→ separate from
public wiring
```

For the project's graceful-degradation and optional-feature policy, see:

```text
docs/architecture.md
docs/behavior.md
```

---

# 7. Deferred Initialization

If a plugin is intentionally initialized on first use, keep that lifecycle below the configuration section.

For example:

```lua
local config = {
  ...
}

local initialized = false

local function ensure_plugin()
  if initialized then
    return package.loaded.plugin
  end

  local available, plugin = pcall(require, "plugin")
  if not available then
    return
  end

  local configured, setup_err =
    pcall(plugin.setup, config)

  if not configured then
    return
  end

  initialized = true
  return plugin
end
```

The important convention is:

```text
user-tweakable config
→ remains easy to find near the top

deferred lifecycle logic
→ stays below state/helpers
```

Do not bury plugin options inside the deferred initializer merely because initialization is delayed.

For architectural ownership of dependencies and runtime behavior, see:

```text
docs/architecture.md
```

For the development and experiment workflow around such changes, see:

```text
docs/workflow.md
```

---

# 8. Public Behavior and Wiring

Public module functions such as:

```lua
function M.toggle()
  ...
end

function M.open()
  ...
end

function M.setup()
  ...
end
```

should generally appear after internal helpers unless the module is so small that another ordering is clearer.

Global project-level mappings belong with public setup/wiring logic rather than inside a plugin's internal configuration table.

For example:

```lua
vim.keymap.set("n", "<leader>f", M.toggle, {
  desc = "Toggle filesystem editor",
})
```

is project-level wiring.

By contrast, mappings that belong only inside a plugin-owned buffer should normally use the plugin's supported buffer-local configuration mechanism when available.

For user-facing keybinding behavior and interaction requirements, see:

```text
docs/behavior.md
```

---

# 9. Plugin Setup Tables Are the Primary Tweak Surface

When upstream documentation shows:

```lua
require("plugin").setup({
  option_a = true,

  option_b = {
    value = 123,
  },
})
```

the corresponding intentional project overrides should normally live in the named config table or config builder for that module.

Use the setup table as the primary place to look for plugin-specific options.

Do not assume every module follows this pattern.

Some plugins:

- do not expose `setup()`;
- use globals;
- use commands or autocmds;
- expose multiple modules;
- require dynamic configuration;
- are too small to justify a dedicated config table.

Use the convention where it improves inspectability.

---

# 10. Preferred Module Layout

For substantial plugin-backed Lua modules, prefer this conceptual structure:

```text
1. MODULE DECLARATION

2. USER-TWEAKABLE CONFIGURATION
   - plugin setup table
   - config builders
   - dimensions
   - timeouts
   - feature toggles
   - other deliberate knobs

3. INTERNAL STATE
   - initialized flags
   - counters
   - caches
   - watchers
   - handles

4. INTERNAL HELPERS
   - notifications
   - path/root resolution
   - mapping helpers
   - lifecycle helpers
   - cleanup
   - refresh/conversion logic

5. PLUGIN LIFECYCLE
   - require
   - setup
   - deferred initialization
   - failure handling

6. PUBLIC BEHAVIOR / WIRING
   - toggle
   - open
   - refresh
   - setup mappings
   - exported helpers

7. return M
```

This is a guideline, not a mandatory template.

Do not add artificial section comments, empty config tables, or unnecessary abstraction just to make every file look identical.

---

# 11. When Not to Apply This Pattern

Do not force this convention when it makes a module less clear.

Examples include:

- a tiny module that only calls `plugin.setup()` with no meaningful options;
- a module that is primarily an architectural coordinator;
- a plugin that does not expose a conventional setup table;
- inherently dynamic configuration that becomes harder to read when artificially separated;
- a module that is already clearer in its existing structure.

The goal is:

```text
inspectability
```

not:

```text
uniformity for its own sake
```

---

# 12. Refactoring Existing Modules

When a task is explicitly a code-layout/style refactor, apply these conventions only where they materially improve readability.

Do not mechanically normalize every file.

A style-only refactor should preserve behavior.

For task scope, experiment boundaries, human acceptance, AI-agent scope, and promotion workflow, see:

```text
docs/workflow.md
```

For validation and regression-test expectations, see:

```text
docs/testing.md
```

For user-facing behavior that must remain unchanged, see:

```text
docs/behavior.md
```

---

# 13. Cross-Document Ownership

This file owns:

```text
implementation layout
plugin-config readability
config-table placement
config builders
tweakable constants
state separation within a module
helper/lifecycle/public-function ordering
```

It does **not** redefine policies owned elsewhere.

Use the exact owning file:

```text
Architecture, dependency ownership, repository boundaries
→ docs/architecture.md

Experiment workflow, task scope, agent workflow, promotion
→ docs/workflow.md

Testing philosophy and validation requirements
→ docs/testing.md

User-facing mappings, UX, editor behavior
→ docs/behavior.md

Stable/experimental mutable-state isolation
→ docs/state-isolation.md

Production deployment
→ docs/deployment.md

Current implementation status and sequencing
→ docs/roadmap.md

Canonical upstream and historical references
→ docs/references.md
```

---

# 14. Agent Guidance

Coding agents modifying implementation files should follow this document where applicable.

Agents should:

- keep intentional configuration easy to find near the top of substantial plugin modules;
- prefer named config tables for static plugin setup;
- use small config builders when runtime objects are required;
- keep tweakable constants separate from mutable runtime state;
- keep lifecycle/wiring logic below configuration;
- avoid copying upstream defaults wholesale;
- avoid mechanical rewrites when the result would be less clear;
- follow existing local style where this document does not define a convention.

For agent task scope, experiment behavior, acceptance, documentation responsibility, and promotion rules, see:

```text
docs/workflow.md
```

For required validation behavior, see:

```text
docs/testing.md
```

When uncertain, prefer the structure that makes intentional project choices easiest to inspect.

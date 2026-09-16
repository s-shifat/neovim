# Project References

## Purpose

This document catalogs the external repositories and source locations used when maintaining, researching, or extending the standalone Neovim project.

It records:

* canonical implementation repositories;
* deployment/integration repositories;
* historical behavioral references;
* upstream behavioral references;
* upstream technical references;
* important dependency/reference repositories;
* the role and authority of each source.

This document answers:

> **Where should a maintainer or agent look for authoritative external information?**

This file is the canonical location for repository URLs and durable external project references.

Other project documentation should refer here rather than repeatedly embedding repository URLs.

---

# 1. Reference Principles

External sources have different roles.

Do not treat every repository as equally authoritative.

The broad distinction is:

```text
current project repositories
→ tell us what the project currently implements

historical personal repositories
→ tell us what behavior the user previously preferred

upstream historical projects
→ fill gaps in historical behavior

modern upstream projects
→ tell us how current implementations and APIs work
```

Historical sources are primarily behavioral references.

They are not automatically implementation templates.

---

# 2. Current Standalone Neovim Repository

## Repository

```text
https://github.com/s-shifat/neovim
```

## Role

**Canonical implementation authority for the editor.**

This repository owns:

```text
Neovim packaging
Lua configuration
plugins
Treesitter dependencies
language servers
formatters
linters
external editor tools
experimental workflow tooling
tests
documentation
health infrastructure
```

Use this repository to determine:

* what is currently implemented;
* current file/module structure;
* current dependencies;
* current flake outputs;
* current tests;
* current editor behavior;
* actual repository state.

When documentation and the current repository disagree about what is implemented, inspect the repository state before assuming the documentation is current.

---

# 3. Current Dotfiles Repository

## Repository

```text
https://github.com/s-shifat/dotfiles
```

## Role

**Deployment and system-integration authority.**

This repository consumes the standalone Neovim project.

It may own:

```text
pinned Neovim revision
Home Manager installation
NixOS integration
EDITOR / VISUAL
terminal integration
desktop integration
host-specific behavior
system-level tmux or launcher integration
```

It should not become the implementation repository for the standalone editor.

The dependency direction remains:

```text
dotfiles
    ↓
neovim
```

not the reverse.

---

# 4. Historical Dotfiles Repository

## Repository

```text
https://github.com/s-shifat/dotfiles-arch
```

## Role

**Historical personal configuration archive.**

This repository contains the editor environments used before the current standalone Nix-managed Neovim project.

It provides surrounding historical context and contains the two most important personal behavioral references:

```text
historical LunarVim configuration
historical standalone Neovim configuration
```

Use the more specific paths below when researching editor behavior.

---

# 5. Historical Personal LunarVim Configuration

## Repository path

```text
https://github.com/s-shifat/dotfiles-arch/tree/main/lvim/.config/lvim
```

## Role

**Primary historical behavioral reference.**

This is the strongest historical source for understanding the user's established editor behavior and muscle memory.

Inspect it before implementing or substantially redesigning behavior involving:

```text
core options
keybindings
leader mappings
which-key organization
navigation
Telescope
statusline behavior
buffer behavior
file-tree behavior
UI conventions
editor interaction
language-specific conveniences
snippets
writing workflow
```

The important distinction is:

```text
historical behavior
→ strong reference

historical implementation
→ not automatically preserved
```

For example, an old plugin may reveal important desired behavior without being the correct plugin to use today.

---

# 6. Historical Personal Standalone Neovim Configuration

## Repository path

```text
https://github.com/s-shifat/dotfiles-arch/tree/main/nvim/.config/nvim
```

## Role

**Secondary historical behavioral reference.**

Use this after the historical LunarVim configuration.

It is especially useful for identifying:

```text
later refinements
post-LunarVim experiments
newer keybinding ideas
standalone-Neovim approaches
behaviors that evolved after the LunarVim setup
```

A behavior found here should not automatically override the historical LunarVim version merely because the file is newer.

Compare:

```text
intent
maturity
current project decisions
```

before choosing which behavior to retain.

---

# 7. Upstream LunarVim

## Repository

```text
https://github.com/LunarVim/LunarVim
```

## Role

**Fallback historical behavioral reference.**

The personal historical LunarVim configuration records explicit user customizations, but it does not restate everything LunarVim provided by default.

When the personal configuration is silent about a historical behavior, inspect upstream LunarVim to determine what the user likely inherited.

Potential areas include:

```text
default options
default mappings
which-key namespaces
Telescope behavior
diagnostic defaults
buffer/navigation behavior
UI defaults
plugin defaults
```

Upstream LunarVim is not an implementation dependency of the current project.

Its role is to help reconstruct historical behavior accurately.

---

# 8. Upstream Neovim

## Repository

```text
https://github.com/neovim/neovim
```

## Role

**Primary native Neovim technical reference.**

Use it when evaluating:

```text
native APIs
editor behavior
LSP APIs
autocmd APIs
diagnostic APIs
runtime behavior
modern replacements for old plugin functionality
```

The preferred implementation direction is generally:

```text
understand desired behavior
        ↓
check native Neovim capability
        ↓
use native implementation when reliable and appropriate
```

## Version caution

Do not assume documentation or code from Neovim `master` applies to the Neovim version packaged by this project.

Before using a native API:

```text
identify packaged Neovim version
        ↓
verify API exists in that version
        ↓
implement
```

The project has already experienced a regression caused by assuming a newer highlight API existed in the packaged release.

---

# 9. Nixpkgs

## Repository

```text
https://github.com/NixOS/nixpkgs
```

## Project input

The standalone flake tracks:

```text
github:NixOS/nixpkgs/nixos-unstable
```

## Role

**Package/dependency source for the standalone Neovim environment.**

Use nixpkgs to research:

```text
Neovim package versions
vimPlugins packages
language servers
formatters
linters
Treesitter-related packages
external executables
package attribute names
package availability
```

The standalone Neovim flake owns its own nixpkgs lifecycle independently of the consuming system/dotfiles flake.

When determining whether a dependency already exists in Nix, inspect nixpkgs before inventing custom packaging.

---

# 10. Catppuccin for Neovim

## Repository

```text
https://github.com/catppuccin/nvim
```

## Role

**Current theme dependency and upstream configuration reference.**

Catppuccin Mocha is the selected default visual direction.

Use this repository when researching:

```text
supported Neovim configuration
current setup options
available flavors
plugin integrations
highlight behavior
upstream defaults
breaking changes
```

Catppuccin is the current default theme.

It is not the architecture of the theme system.

The theme layer should remain replaceable.

---

## Stage 8A Telescope dependencies

Current implementation references adopted for the search foundation:

```text
https://github.com/nvim-telescope/telescope.nvim
https://github.com/nvim-lua/plenary.nvim
https://github.com/nvim-telescope/telescope-fzf-native.nvim
https://github.com/nvim-telescope/telescope-ui-select.nvim
https://github.com/nvim-telescope/telescope-live-grep-args.nvim
https://github.com/BurntSushi/ripgrep
https://github.com/sharkdp/fd
```

These are implementation dependencies or backend tools, not behavioral
authority. Telescope remains the primary fuzzy-search layer; the native sorter
does not require the `fzf` command-line executable.

---

## Stage 8B Snacks Explorer

The daily file explorer uses the already packaged Snacks dependency:

```text
https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md
https://github.com/folke/snacks.nvim/blob/main/docs/image.md
```

This is the implementation reference for Explorer options, filesystem actions,
directory replacement, Git/diagnostic context, its internal Picker dependency,
and direct image/PDF rendering. Repository behavior remains authoritative, and
enabling Picker for Explorer does not make Snacks Picker a general search
interface.

---

# 11. Behavioral Reference Policy

Behavioral reference precedence and the detailed behavioral research sequence are defined in:

```text
docs/behavior.md
```

This document supplies the canonical locations and roles of those sources.

It does not independently define their precedence.

---

# 12. Implementation Authority vs Behavioral Authority

Do not confuse these two concepts.

## Implementation authority

The current:

```text
s-shifat/neovim
```

repository determines what the project actually implements.

---

## Behavioral authority

Historical personal configurations provide evidence about how the editor should behave.

For example:

```text
historical LunarVim
→ tells us how navigation used to feel

current Neovim repository
→ tells us how navigation is currently implemented
```

Both may be relevant to a task, but for different reasons.

For behavioral decision rules, consult:

```text
docs/behavior.md
```

---

# 13. Current Repository State Is Always Checked

External references and project documentation may become stale.

Before implementing a task, inspect the current standalone repository.

Do not assume:

```text
a documented plugin is still installed

a roadmap feature is already implemented

a file path still exists

an old option remains current

a recorded Neovim version is still packaged
```

Current Git/repository state is the authority for implementation status.

---

# 14. Adding Future References

This document should remain selective.

Add a repository or external source when it becomes a durable project reference, such as:

```text
a first-class plugin used by the project

an upstream project whose behavior is regularly consulted

an important standard or tool documentation source

a historical repository needed for behavioral reconstruction
```

Do not add every transient webpage, blog post, Stack Overflow answer, or search result consulted during implementation.

The purpose is to maintain:

```text
durable reference map
```

not:

```text
research browsing history
```

---

# 15. Plugin References

As major long-lived plugins are selected, their upstream repositories may be added here if they become important recurring references.

Examples could eventually include:

```text
Telescope
which-key
statusline implementation
Gitsigns
VimTeX
completion engine
Treesitter-related plugins
Git UI integrations
```

Do not pre-populate references for plugins that have not actually been selected.

Add them when the project adopts them.

---

# 16. Source Roles Summary

| Source                   | Role                                      |
| ------------------------ | ----------------------------------------- |
| `s-shifat/neovim`        | Current implementation authority          |
| `s-shifat/dotfiles`      | Deployment/system-integration authority   |
| `s-shifat/dotfiles-arch` | Historical personal configuration archive |
| historical LunarVim path | Primary historical behavioral reference   |
| historical Neovim path   | Secondary historical behavioral reference |
| `LunarVim/LunarVim`      | Fallback historical behavioral defaults   |
| `neovim/neovim`          | Native Neovim technical/API authority     |
| `NixOS/nixpkgs`          | Nix package/dependency authority          |
| `catppuccin/nvim`        | Current theme upstream reference          |

---

# 17. Governing Principle

References should make research reproducible without turning every project document into a collection of duplicated URLs.

The concise model is:

```text
CURRENT REPO
→ WHAT EXISTS NOW

HISTORICAL PERSONAL CONFIGS
→ WHAT BEHAVIOR MATTERED

UPSTREAM HISTORICAL PROJECT
→ WHAT WAS INHERITED

CURRENT UPSTREAM PROJECTS
→ HOW TO IMPLEMENT IT TODAY
```

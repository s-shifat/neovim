# Stable and Experimental State Isolation

The production and experimental Neovim instances intentionally use separate
mutable application state.

## Application names

Production Neovim uses the normal Neovim application identity:

```text
nvim
```

Experimental Neovim is started with:

```text
NVIM_APPNAME=nvim-next
```

This causes Neovim's XDG application directories to be separated.

## Mutable state

The expected relationship is:

| State class | Stable                         | Experimental                        |
| ----------- | ------------------------------ | ----------------------------------- |
| config      | `stdpath("config")` for `nvim` | `stdpath("config")` for `nvim-next` |
| data        | `stdpath("data")` for `nvim`   | `stdpath("data")` for `nvim-next`   |
| state       | `stdpath("state")` for `nvim`  | `stdpath("state")` for `nvim-next`  |
| cache       | `stdpath("cache")` for `nvim`  | `stdpath("cache")` for `nvim-next`  |
| ShaDa       | stable state tree              | experimental state tree             |


The actual production configuration is packaged immutably in the Nix store.

The experimental configuration is loaded live from the active Git worktree.

`stdpath("config")` describes the application's XDG config location; it does
not imply that production configuration is loaded from that mutable directory.

## ShaDa

When shadafile is not explicitly overridden, the effective default is under:

```text
stdpath("state")/shada/main.shada
```

Because stable and experimental stdpath("state") values differ, their ShaDa
files are isolated.

Do not later hard-code a shared ShaDa file.

## Sessions

No persistent session implementation is currently enabled.

When sessions are added, their mutable files should live under a path derived
from:

```text
stdpath("state")
```

for example:

```text
stdpath("state")
```

This preserves stable/experimental isolation automatically.

## Persistent Undo

Persistent undo is not currently part of the core configuration.

If enabled later, its storage should be placed below:

```text
stdpath("state")
```

for exmaple:

```text
stdpath("state")/undo
```

Do not hard-code a shared `~/.local/state/nvim/...` path.

Plugin-generated mutable state

Plugins may create:

- databases;
- histories;
- indexes;
- caches;
- sessions;
- generated metadata.

Any mutable plugin state must either:

naturally use Neovim's `stdpath("data")`, `stdpath("state")`, or
`stdpath("cache");` or
be configured explicitly to use a path derived from those functions.

A plugin that hard-codes the normal nvim XDG paths must be overridden or
reconsidered before promotion.

## Intentionally shared resources

Stable and experimental Neovim may intentionally share resources that are not
editor-specific mutable state, including:

- project files;
- Git repositories;
- project-local configuration;
- system clipboard;
- shell environment;
- external project environments;
- immutable Nix store dependencies.

Sharing immutable dependencies is safe.

Sharing mutable editor state is not the default.

## Safety guard

dev/init.lua refuses to start unless:

```text
NVIM_APPNAME=nvim-next
```

This prevents accidentally launching the experimental bootstrap through normal
Neovim and contaminating stable mutable state.

## Regression test

Run:

```bash
./tests/state-isolation.sh
```

The test verifies that stable and experimental Neovim use different:

- config paths;
- data paths;
- state paths;
- cache paths;
- ShaDa paths.

The test must pass before state-related infrastructure changes are promoted.




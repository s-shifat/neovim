# Nix-Managed Neovim

A standalone, reproducible Neovim setup for NixOS and other Linux systems with
Nix. It packages Neovim and its dependencies with Nix while keeping editor
behavior in ordinary Lua tailored to the user's workflow and preferences. It
does not depend on a particular dotfiles or host configuration repository.

> **Nix owns what exists. Lua owns how it behaves.**

The project keeps the production editor predictable while providing a separate
worktree-based environment for developing and trying changes.

## Commands

| Command | Role |
| --- | --- |
| `nvim` | Immutable production editor built from the pinned source. |
| `nvim-next` | Experimental editor that loads the active development worktree. |
| `nvim-exp` | Helper for setting up the checkout and managing experiments. |

Stable `nvim` does not require a local clone. Development uses one canonical Lua
configuration tree, with mutable state for `nvim-next` isolated from production.

## Install

Install only the stable editor:

```bash
nix profile install github:s-shifat/neovim#nvim
```

Install the stable editor and the complete development workflow:

```bash
nix profile install github:s-shifat/neovim#full
```

As a flake input, packages can also be added to NixOS or Home Manager directly:

```nix
{
  inputs.neovim.url = "github:s-shifat/neovim";
}
```

Then, in a NixOS module that receives `inputs` and `pkgs`:

```nix
{
  environment.systemPackages = [
    inputs.neovim.packages.${pkgs.system}.full
  ];
}
```

Use `home.packages` instead of `environment.systemPackages` for Home Manager.
The consuming flake lock pins the selected repository revision.

Supported systems are `x86_64-linux` and `aarch64-linux`.

## Flake outputs

| Output | Provides |
| --- | --- |
| `#nvim` | `nvim` only; also the default package. |
| `#workflow-tools` | `nvim-next` and `nvim-exp`. |
| `#full` | `nvim`, `nvim-next`, and `nvim-exp`. |

## Development quick start

After installing `#full` or `#workflow-tools`, configure or create the local
development checkout and start one focused experiment:

```bash
nvim-exp setup
nvim-exp status
nvim-exp new <name>
nvim-next
```

By default, the stable checkout is `~/projects/neovim` and `nvim-exp` creates
the experimental worktree at `~/projects/neovim-next`. Inspect changes with
`git diff`; see the [development workflow](docs/workflow.md) for iteration,
validation, promotion, discard, and recovery details.

## Documentation

- [Architecture](docs/architecture.md) — ownership, packaging, and system boundaries.
- [Behavior](docs/behavior.md) — editor UX, mappings, and historical behavior.
- [Development workflow](docs/workflow.md) — experiments, iteration, and promotion.
- [Testing](docs/testing.md) — validation strategy and checks.
- [State isolation](docs/state-isolation.md) — separation of stable and experimental mutable state.
- [Deployment](docs/deployment.md) — production installation, updates, and rollback.
- [Roadmap](docs/roadmap.md) — current implementation status and sequencing.
- [References](docs/references.md) — related repositories and upstream sources.

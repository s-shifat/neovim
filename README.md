# Nix-Managed Neovim

A standalone, reproducible Neovim configuration built around **Nix + Lua**.

The repository is designed to work in two environments:

* **NixOS**, with or without Home Manager.
* **Other Linux distributions** with the Nix package manager installed.

The repository is self-contained. It does not depend on a particular NixOS configuration or dotfiles repository.

## Design

The configuration follows a simple ownership model:

* **Nix** manages Neovim itself, plugins, parsers, language servers, formatters, linters, and other external dependencies.
* **Lua** manages editor behavior and configuration.
* **Git worktrees** provide an isolated experimental Neovim environment before changes are promoted to the stable configuration.

The goal is to keep the production editor predictable while still making experimentation easy.

```text
stable source
    main
     │
     │ nvim-exp new <name>
     ▼
experiment/<name>
     │
     │ test with nvim-next
     ▼
promote or discard
```

## Flake Outputs

The flake currently exposes the following packages:

| Output            | Contents                            | Intended use                                                  |
| ----------------- | ----------------------------------- | ------------------------------------------------------------- |
| `#nvim`           | Stable Neovim                       | Machines that only need the production editor                 |
| `#workflow-tools` | `nvim-next` and `nvim-exp`          | Machines used to develop or experiment with the configuration |
| `#full`           | `nvim`, `nvim-next`, and `nvim-exp` | Convenient complete installation                              |
| default           | Same as `#nvim`                     | Stable editor                                                 |

Supported Linux architectures:

* `x86_64-linux`
* `aarch64-linux`

---

# Installation

## NixOS with Home Manager

Add this repository as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    neovim.url = "github:s-shifat/neovim";

    # Other inputs...
  };
}
```

Make the flake inputs available to Home Manager. One common approach when Home Manager is used as a NixOS module is:

```nix
{
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };
}
```

Then add the Neovim packages to the user's Home Manager configuration:

```nix
{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.neovim.packages.${pkgs.system}.nvim
    inputs.neovim.packages.${pkgs.system}.workflow-tools
  ];
}
```

This installs:

```text
nvim
nvim-next
nvim-exp
```

If only the stable editor is required:

```nix
home.packages = [
  inputs.neovim.packages.${pkgs.system}.nvim
];
```

The consuming flake's `flake.lock` pins the exact Neovim repository revision, so updating the rest of the system does not implicitly move this configuration to a newer revision.

---

## NixOS without Home Manager

Add the repository as a flake input:

```nix
{
  inputs.neovim.url = "github:s-shifat/neovim";
}
```

Pass the flake inputs to the NixOS modules if they are not already available:

```nix
nixosConfigurations.example = nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
  };

  modules = [
    ./configuration.nix
  ];
};
```

Then install the packages through NixOS:

```nix
{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    inputs.neovim.packages.${pkgs.system}.nvim
    inputs.neovim.packages.${pkgs.system}.workflow-tools
  ];
}
```

For a stable-only installation:

```nix
environment.systemPackages = [
  inputs.neovim.packages.${pkgs.system}.nvim
];
```

---

# Non-NixOS Linux with Nix

A full NixOS installation is not required. The repository can also be installed on another Linux distribution as long as the Nix package manager with flakes is available.

## Stable editor only

If the machine only needs the production editor:

```bash
nix profile install github:s-shifat/neovim#nvim
```

This installs:

```text
nvim
```

The experimental workflow is not required.

## Complete installation

To install the stable editor and experimental workflow tools:

```bash
nix profile install github:s-shifat/neovim#full
```

This provides:

```text
nvim
nvim-next
nvim-exp
```

## Workflow tools only

If stable Neovim is managed separately:

```bash
nix profile install github:s-shifat/neovim#workflow-tools
```

This provides:

```text
nvim-next
nvim-exp
```

---

# Experimental Workflow

The stable editor and experimental editor intentionally use different sources.

```text
nvim
└── immutable Nix-built configuration

nvim-next
└── live configuration from an experimental Git worktree
```

The experiment begins from the same repository structure and Lua files as stable.

There is no separate development configuration.

For example:

```text
stable:
~/projects/neovim/config/lua/...

experiment:
~/projects/neovim-next/config/lua/...
```

Both are Git worktrees of the same repository.

## Preparing a Development Checkout

The workflow tools use the following locations by default:

```text
~/projects/neovim
~/projects/neovim-next
```

Clone the repository:

```bash
mkdir -p ~/projects

git clone https://github.com/s-shifat/neovim.git \
  ~/projects/neovim
```

The second directory should **not** be created manually. `nvim-exp` creates and removes it as a Git worktree.

Different locations can be used by setting:

```bash
export NVIM_STABLE_REPO="/path/to/neovim"
export NVIM_NEXT_WORKTREE="/path/to/neovim-next"
```

---

## Create an Experiment

For example, to experiment with a new file-navigation feature:

```bash
nvim-exp new file-navigation
```

This creates:

```text
stable repository:
~/projects/neovim
branch: main

experimental worktree:
~/projects/neovim-next
branch: experiment/file-navigation
```

The experiment initially contains exactly the same source tree as `main`.

Check the current state with:

```bash
nvim-exp status
```

---

## Open the Experimental Editor

Launch:

```bash
nvim-next
```

`nvim-next` loads:

```text
~/projects/neovim-next/config/
```

directly from the working tree.

The stable `nvim` continues using its immutable Nix-built configuration.

---

## Lua-Only Changes

For normal configuration changes such as:

* keybindings
* options
* plugin configuration
* UI settings
* LSP behavior
* Telescope configuration

edit the files under:

```text
~/projects/neovim-next/config/
```

Then restart:

```bash
nvim-next
```

No Nix rebuild is required for Lua-only changes.

The workflow is:

```text
edit Lua
   ↓
restart nvim-next
   ↓
change is visible
```

Stable `nvim` is unaffected.

---

## Dependency Changes

Some experiments change the Nix dependency graph, for example:

* adding a plugin
* adding a Treesitter parser
* adding an LSP executable
* adding a formatter or linter
* changing the Neovim package

Those changes are made in the experimental worktree's Nix files.

On the next experimental launch, Nix may need to build or obtain the changed development environment.

After the dependencies are available, Lua configuration can again be iterated without rebuilding for every edit.

---

# Promoting an Experiment

When an experiment is ready, commit it inside the experimental worktree:

```bash
cd ~/projects/neovim-next

git status
git add .
git commit -m "feat: add file navigation"
```

Leave the experimental worktree:

```bash
cd ~
```

Then promote it:

```bash
nvim-exp promote
```

Promotion verifies that:

* the stable repository is clean;
* the experiment is committed and clean;
* the experiment is based on the current stable branch;
* the experimental `#nvim` package builds successfully.

It then fast-forwards the experiment into `main` and removes the temporary worktree and experimental branch.

Conceptually:

```text
experiment/file-navigation
          │
          │ build candidate
          ▼
        main
```

`nvim-exp promote` performs **source promotion only**.

It does not automatically update a NixOS system, Home Manager generation, remote Git repository, or separately installed Nix profile.

After promotion, push the stable source normally:

```bash
cd ~/projects/neovim
git push origin main
```

A consuming NixOS configuration can then deliberately update its pinned Neovim flake revision and rebuild.

---

# Discarding an Experiment

If an experiment is not worth keeping:

```bash
cd ~
nvim-exp discard
```

The command shows the experiment and asks for confirmation before removing it.

Discarding removes:

* the experimental Git worktree;
* the `experiment/<name>` branch;
* uncommitted changes inside that discarded experiment.

Stable `main` remains unchanged.

---

# Typical Experiment Cycle

```bash
# Start from known-good main
nvim-exp new feature-name

# Experiment
nvim-next

# Inspect state at any time
nvim-exp status

# If successful:
cd ~/projects/neovim-next
git add .
git commit -m "feat: implement feature"

cd ~
nvim-exp promote

# Push the newly promoted stable source
cd ~/projects/neovim
git push origin main
```

Or reject it:

```bash
cd ~
nvim-exp discard
```

This keeps experimental changes out of the production editor until they have been deliberately accepted.

---

# Repository Structure

```text
.
├── flake.nix
├── flake.lock
├── config/
│   ├── init.lua
│   └── lua/
│       └── user/
├── dev/
│   └── init.lua
├── nix/
│   ├── package.nix
│   ├── dev-shell.nix
│   ├── workflow-tools.nix
│   ├── plugins.nix
│   ├── tools.nix
│   └── checks.nix
├── scripts/
│   ├── nvim-next.sh
│   └── nvim-exp.sh
├── tests/
└── docs/
```

The important boundary is:

```text
config/
```

contains the actual Neovim configuration.

`dev/init.lua` is only a small bootstrap used to load that same configuration from the experimental worktree. It is not a second Neovim configuration.

---

# Development Principles

The configuration is built around several operational rules:

1. Stable Neovim should change only through deliberate promotion.
2. Neovim consumes dependencies managed by Nix rather than silently installing them at runtime.
3. Experimental changes must not modify the production configuration.
4. Stable and experimental configurations use the same Lua structure.
5. Git and Nix should remain the visible mechanisms behind rollback and reproducibility.
6. Optional editor features should not make basic editing unusable when they fail.
7. Changes should be small, testable, and independently promotable.

---

# Current Status

The repository currently provides the infrastructure for:

* reproducible stable Neovim packaging;
* immutable Lua configuration in the stable package;
* standalone flake outputs;
* isolated Git-worktree experiments;
* live Lua iteration through `nvim-next`;
* promotion and discard through `nvim-exp`.

The editor configuration itself is being developed incrementally on top of this foundation.


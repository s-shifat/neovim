# Deployment

## Purpose

This document defines how an accepted standalone Neovim source revision becomes the deployed production editor.

It covers:

* the source-stable → deployed-stable boundary;
* the role of the dotfiles repository;
* production revision pinning;
* NixOS/Home Manager integration;
* deployment validation;
* production switching;
* rollback and recovery;
* standalone installation on other Nix-capable Linux systems;
* deployment responsibilities for humans and agents.

Deployment is deliberately separate from development and experiment promotion.

## Related Documentation

* `docs/architecture.md` — repository boundaries, release states, and dependency direction.
* `docs/workflow.md` — experiment development and experiment → source-stable promotion.
* `docs/testing.md` — testing and validation policy before source promotion.
* `docs/state-isolation.md` — production/experimental mutable-state separation.
* `docs/roadmap.md` — current implementation status and future direction.
* `docs/references.md` — canonical repository URLs and durable external references.

Repository locations referenced by this document are maintained in `docs/references.md`.

---

# 1. Deployment Principle

The project deliberately separates:

```text
experiment
    ↓
source stable
    ↓
deployed stable
```

These are different states with different acceptance boundaries.

The governing principle is:

> **Promoting source is not the same as deploying production.**

An accepted change may exist on the standalone Neovim `main` branch without immediately changing the production editor.

This is intentional.

---

# 2. Deployment Boundary

The development workflow ends with an accepted source-stable revision.

Conceptually:

```text
experiment/<feature>
        ↓
nvim-exp promote
        ↓
neovim/main
        ↓
git push
        ↓
SOURCE STABLE
```

Production deployment begins only after that point:

```text
SOURCE STABLE
        ↓
update consuming dotfiles Neovim pin
        ↓
evaluate/build system
        ↓
switch deliberately
        ↓
DEPLOYED STABLE
```

The two processes must not be collapsed into one automatic operation.

---

# 3. Deployment Authority

The standalone Neovim repository owns:

```text
editor implementation
Lua configuration
plugins
tools
tests
workflow infrastructure
```

The dotfiles repository owns:

```text
which standalone Neovim revision is deployed

Home Manager integration

NixOS/user-environment integration

host-specific integration
```

The dependency direction is:

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
    ▼
dotfiles
```

The standalone editor must remain independently usable.

---

# 4. Production Version Pin

The consuming dotfiles flake references the standalone Neovim flake.

The actual production Neovim revision is recorded in the dotfiles:

```text
flake.lock
```

Therefore the dotfiles lock acts as the production editor version pin.

Conceptually:

```text
neovim/main
    commit B

dotfiles/flake.lock
    commit A
```

is valid.

In that situation:

```text
source stable = B

deployed stable = A
```

The editor does not change merely because `neovim/main` advanced.

This separation is one of the project's primary reliability mechanisms.

---

# 5. Publishing Source Stable

After an experiment has been accepted and promoted, publish the standalone source as appropriate.

Typical flow:

```bash
cd ~/projects/neovim
git push origin main
```

At this point the accepted revision is available remotely.

Production is still unchanged.

Pushing `main` is therefore:

```text
source publication
```

not:

```text
production deployment
```

---

# 6. Updating the Production Pin

When the user decides that the current source-stable Neovim revision should become production, move to the consuming dotfiles repository.

Conceptually:

```bash
cd ~/dotfiles
```

Update only the Neovim flake input:

```bash
nix flake update neovim
```

This should advance the Neovim entry in:

```text
flake.lock
```

to the selected current source revision.

The important principle is:

> Update the Neovim input deliberately rather than allowing an unrelated system update to decide the editor version accidentally.

---

# 7. Inspect the Lock Change

After updating the input, inspect the resulting change before building.

For example:

```bash
git diff -- flake.lock
git status
```

Confirm that the intended Neovim input changed.

Be alert for unrelated lockfile movement.

A deployment task should not silently update unrelated dependencies unless that broader update was explicitly intended.

The desired change is conceptually:

```text
old Neovim revision
        ↓
new accepted Neovim revision
```

not:

```text
Neovim
+
many unrelated flake inputs
```

without a deliberate reason.

---

# 8. Build Before Switch

Do not switch production immediately after changing the deployment pin.

First evaluate/build the candidate system.

For NixOS, use:

```bash
sudo nixos-rebuild build --flake .#<host>
```

For the current primary host, `<host>` corresponds to the configured NixOS flake host.

The important policy is:

```text
update pin
    ↓
build
    ↓
inspect result
    ↓
switch
```

not:

```text
update pin
    ↓
switch blindly
```

If the build fails, production remains on the existing working configuration.

---

# 9. Switching Production

Once the candidate system builds successfully and the deployment is accepted:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

This activates the new system/user configuration, including the newly pinned production Neovim revision.

After a successful switch:

```text
nvim
```

should resolve to the new deployed stable editor.

The experimental environment remains conceptually separate:

```text
nvim
→ deployed stable

nvim-next
→ active experiment, if one exists
```

---

# 10. Deployment Sequence

The normal source-stable → production sequence is:

```text
accepted neovim/main
        ↓
git push
        ↓
open dotfiles repo
        ↓
nix flake update neovim
        ↓
inspect flake.lock diff
        ↓
nixos-rebuild build
        ↓
build succeeds
        ↓
nixos-rebuild switch
        ↓
production nvim
```

In command form:

```bash
cd ~/projects/neovim
git push origin main

cd ~/dotfiles
nix flake update neovim

git diff -- flake.lock
git status

sudo nixos-rebuild build --flake .#<host>
sudo nixos-rebuild switch --flake .#<host>
```

The exact host identifier belongs to the consuming dotfiles configuration.

---

# 11. Deployment Timing

Deployment does not need to happen immediately after source promotion.

All of the following are valid:

```text
experiment accepted
        ↓
promote to main
        ↓
push
        ↓
deploy immediately
```

or:

```text
experiment accepted
        ↓
promote to main
        ↓
push
        ↓
continue using existing production
        ↓
deploy later
```

This allows source development to progress independently from the production editor.

The production editor can therefore remain deliberately conservative.

---

# 12. Home Manager Integration

The dotfiles repository integrates the standalone Neovim flake into the user environment.

The intended installed commands include:

```text
nvim
nvim-next
nvim-exp
```

Their roles remain:

```text
nvim
→ deployed production editor

nvim-next
→ experimental editor

nvim-exp
→ experiment workflow tooling
```

The standalone Neovim repository owns those packages.

Home Manager consumes and installs them.

Do not duplicate the actual editor implementation inside Home Manager configuration.

---

# 13. Independent Editor and System Lifecycles

The standalone Neovim flake maintains its own nixpkgs lifecycle.

The wider dotfiles/system flake maintains the operating-system lifecycle.

Conceptually:

```text
Neovim dependency lifecycle
        ≠
system dependency lifecycle
```

This separation is intentional.

A general operating-system update should not necessarily upgrade the editor ecosystem at the same time.

Likewise, deploying a new accepted Neovim revision should not require a broad unrelated system dependency update.

Preserve this independence unless the architecture is deliberately changed.

---

# 14. Production Immutability

The deployed production editor uses an immutable Nix-built configuration.

Therefore:

```text
editing ~/projects/neovim/config/
```

must not alter the already deployed:

```text
nvim
```

A production behavior change occurs only after a new standalone revision is:

```text
accepted
        ↓
pinned by deployment
        ↓
built
        ↓
switched
```

This is a core deployment guarantee.

---

# 15. Deployment Validation vs Development Validation

Development validation occurs before and during experiment promotion.

That includes the checks described in:

```text
docs/testing.md
```

and the promotion gate described in:

```text
docs/workflow.md
```

Deployment adds another distinct validation layer:

```text
Can the consuming system successfully evaluate/build with this new pinned Neovim revision?
```

Therefore:

```text
nvim-exp promote succeeds
```

does not eliminate the need for:

```text
nixos-rebuild build
```

before switching the consuming system.

The two operations validate different integration boundaries.

---

# 16. Build Failure

If:

```bash
sudo nixos-rebuild build --flake .#<host>
```

fails, do not switch.

The existing production editor remains untouched.

Investigate the failure at the appropriate boundary:

```text
standalone Neovim issue
dotfiles integration issue
Nix evaluation issue
system dependency issue
```

Do not weaken unrelated architecture merely to force the deployment through.

---

# 17. Switch Failure

If activation/switching fails, use ordinary NixOS/Home Manager recovery mechanisms.

The project should not create custom editor-specific deployment recovery machinery when normal Nix mechanisms already provide rollback.

Potential recovery mechanisms include:

```text
previous NixOS generation

previous Home Manager generation

previous dotfiles commit

previous flake.lock revision

previous known-good Neovim pin
```

The exact recovery path depends on which layer failed.

---

# 18. Rollback Philosophy

Do not create a parallel:

```text
nvim-old
nvim-backup
last-known-good-nvim
```

deployment system merely for rollback.

The project already has durable recovery mechanisms:

```text
Git history
flake.lock history
Nix store immutability
NixOS generations
Home Manager generations
```

Use those mechanisms first.

Custom rollback infrastructure should be introduced only if normal Git/Nix recovery proves inadequate in practice.

---

# 19. Rolling Back the Neovim Pin

If a newly deployed Neovim revision must be reverted, restore a previously known-good dotfiles state or Neovim lock revision.

Conceptually:

```text
bad deployed Neovim revision
        ↓
restore previous dotfiles / flake.lock revision
        ↓
build
        ↓
switch
        ↓
previous production Neovim
```

This may be achieved through normal Git operations appropriate to the situation.

Avoid manually copying old configuration files around the filesystem.

The production version should remain represented declaratively by the consuming configuration.

---

# 20. NixOS Generation Rollback

Because deployment occurs through NixOS, previous system generations provide an additional recovery boundary.

A failed or undesirable new generation does not erase prior generations.

This allows the wider operating-system deployment mechanism to recover the previously working environment.

The editor should benefit from this existing system mechanism rather than create a competing one.

---

# 21. Source Rollback vs Deployment Rollback

These are different operations.

## Source rollback

Changes:

```text
neovim/main
```

using normal Git history.

Use when the accepted standalone source itself should be changed or reverted.

---

## Deployment rollback

Changes which Neovim revision the consuming system deploys.

Use when production should return to an older known-good revision regardless of whether standalone `main` has moved forward.

Conceptually:

```text
neovim/main
    commit C

dotfiles pin
    commit A
```

is valid.

Production does not have to track source `main`.

---

# 22. Deployment Must Remain Inspectable

The deployment state should be explainable through ordinary files and commands.

Important state includes:

```text
standalone Neovim Git revision

dotfiles Git revision

dotfiles flake.lock

Nix build result

active NixOS/Home Manager generation
```

Do not hide the deployed editor version in an opaque custom database or agent-only state file.

The deployment must remain understandable without AI tooling.

---

# 23. Agent Deployment Boundary

An AI agent may assist with:

```text
inspecting the selected source revision

updating the Neovim flake input when explicitly requested

reviewing the lockfile diff

running a candidate build when explicitly requested

diagnosing deployment failures
```

However, implementation completion does not itself authorize deployment.

A normal implementation ticket should stop before production deployment unless deployment is explicitly included in the task.

In particular, an agent should not automatically:

```text
update the dotfiles production pin

run nixos-rebuild switch

change active production generations
```

merely because a Neovim implementation task succeeded.

Deployment remains an explicit acceptance boundary.

---

# 24. Production Switch Is a Human-Significant Action

The distinction between:

```text
build
```

and:

```text
switch
```

should remain meaningful.

Building is validation.

Switching changes the active production environment.

Therefore an automated or AI-assisted workflow may reasonably build a candidate when requested, while activation should remain deliberate.

This preserves the project's conservative production model.

---

# 25. Standalone Stable Installation

The standalone Neovim flake is intended to remain usable outside the primary NixOS deployment.

A machine with the Nix package manager may install only the stable editor:

```bash
nix profile install github:s-shifat/neovim#nvim
```

This provides production Neovim without requiring a writable Git checkout.

The stable package is the primary standalone product.

---

# 26. Standalone Full Installation

A machine that should also support the experimental workflow may install:

```bash
nix profile install github:s-shifat/neovim#full
```

This provides:

```text
nvim
nvim-next
nvim-exp
```

Installing the workflow tools does not automatically clone the development repository.

A writable checkout is established only when experimentation is actually requested.

This preserves minimal installation side effects.

Canonical repository URLs are maintained in:

```text
docs/references.md
```

---

# 27. Stable Consumption Does Not Require Development State

A consumer of the production editor should not need:

```text
~/projects/neovim
~/projects/neovim-next
experiment branches
development worktrees
```

to run:

```text
nvim
```

The stable editor is a packaged product.

Development state is optional infrastructure for people actively changing the editor.

This separation should remain true for both NixOS and non-NixOS Nix installations.

---

# 28. Host-Specific Integration

The standalone repository should not contain host-specific deployment details.

Examples that belong to the consuming configuration include:

```text
NixOS hostname

Home Manager user integration

desktop shortcuts

terminal integration

Hyprland bindings

host-specific environment variables

system-specific launchers
```

Deployment documentation may describe the boundary, but the standalone editor should not depend on these details.

---

# 29. Deployment Scope Discipline

A Neovim deployment should ideally change only what is necessary to deploy the selected editor revision.

Avoid combining:

```text
new Neovim revision
+
large unrelated NixOS upgrade
+
unrelated desktop changes
+
unrelated Home Manager migration
```

unless that combined deployment is intentional.

Smaller deployment scope makes failures easier to understand and rollback.

---

# 30. Deployment Checklist

Before changing production:

```text
1. Is the desired Neovim revision already accepted into source stable?

2. Has source stable been published if the consuming flake requires the remote revision?

3. Is the dotfiles working tree in an understood state?

4. Was only the intended Neovim input updated?

5. Was the lockfile diff inspected?

6. Does the candidate NixOS configuration build?

7. Are any build failures understood?

8. Is the user ready to change the active production editor?

9. After switching, does `nvim` resolve to the expected deployed editor?

10. Is rollback available through ordinary Git/Nix mechanisms if needed?
```

---

# 31. Deployment Invariants

The following should remain true unless deliberately revised.

1. Source promotion does not automatically deploy production.

2. The dotfiles repository controls which standalone Neovim revision is deployed.

3. The production Neovim revision is represented declaratively through the consuming flake lock.

4. Source stable may legitimately be newer than deployed stable.

5. Deployment updates the Neovim input deliberately.

6. Unrelated flake inputs should not be changed accidentally as part of a Neovim-only deployment.

7. Candidate system configuration is built before switching.

8. A failed build does not replace the existing production editor.

9. Production activation remains a deliberate action.

10. The standalone Neovim implementation is not duplicated into the dotfiles repository.

11. The standalone editor remains independently installable on other Nix-capable Linux systems.

12. Stable use does not require a development checkout.

13. Rollback relies primarily on Git, flake-lock history, and Nix generations.

14. Custom editor-specific rollback infrastructure is not introduced without demonstrated need.

15. Deployment state remains inspectable through ordinary Git/Nix mechanisms.

16. AI implementation completion does not automatically authorize production deployment.

---

# 32. One-Screen Deployment Model

```text
                    STANDALONE NEOVIM

                     experiment
                         │
                         ▼
                 nvim-exp promote
                         │
                         ▼
                    neovim/main
                   source stable
                         │
                      git push
                         │
                         ▼
                DEPLOYMENT BOUNDARY
                         │
                         ▼
                  DOTFILES REPOSITORY
                         │
               nix flake update neovim
                         │
                         ▼
                     flake.lock
                  production pin
                         │
                   inspect diff
                         │
                         ▼
                nixos-rebuild build
                         │
                    ┌────┴────┐
                    │         │
                  fail      success
                    │         │
                    ▼         ▼
             production    deliberate
              unchanged       switch
                              │
                              ▼
                     deployed stable
                           nvim
```

---

# 33. Governing Principle

Deployment exists to make production intentionally slower to change than development.

The concise model is:

```text
PROMOTION ACCEPTS SOURCE.

THE DOTFILES LOCK SELECTS PRODUCTION.

BUILD BEFORE SWITCH.

DEPLOY ONLY WHEN INTENDED.

ROLL BACK WITH GIT AND NIX,
NOT WITH PARALLEL CONFIGURATION COPIES.
```


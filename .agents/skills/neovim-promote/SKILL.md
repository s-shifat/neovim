---
name: neovim-promote
description: Commit and promote the currently active Neovim experiment after explicit human acceptance. Never push or deploy.
---


# Neovim Promote

Use only after explicit user invocation.

This invocation authorizes:

* final inspection of the active accepted experiment;
* committing that experiment;
* running `nvim-exp promote`;
* verifying source-stable `main`.

It does not authorize push, dotfiles pin updates, deployment, discard, or unrelated changes.

## Procedure

1. Read the applicable promotion/lifecycle rules from `AGENTS.md`.

2. Run:

   ```bash
   nvim-exp status
   ```

   Use the status output to identify the active experiment and the source-stable checkout.

3. Inspect the final experiment:

   ```bash
   git status
   git diff --check
   git diff
   git ls-files --others --exclude-standard
   ```

   Include untracked files in the review.

4. Stop if:

   * there are unrelated or suspicious changes;
   * source-stable `main` is not in a promotable state;
   * the accepted task appears incomplete.

5. Otherwise create one focused commit.

   * Use a user-supplied commit message if provided.
   * Otherwise inspect recent commit style and choose a concise Conventional Commit message.

   ```bash
   git add -A
   git commit -m "<message>"
   ```

6. Confirm the experiment is clean.

7. Before invoking the promotion gate, move the shell outside the experimental worktree and into the source-stable checkout.

   Prefer the source-stable checkout reported by:

   ```bash
   nvim-exp status
   ```

   For the normal repository layout this is:

   ```bash
   cd ~/projects/neovim
   ```

   Do not run `nvim-exp promote` while the current working directory is inside:

   ```text
   ~/projects/neovim-next
   ```

   Changing to the source-stable checkout is normal promotion preparation. It does not modify, discard, or otherwise alter the accepted experiment.

8. Run:

   ```bash
   nvim-exp promote
   ```

   Treat this as the authoritative promotion gate. Do not duplicate or bypass its validation.

9. If promotion fails:

   * If the failure is only a harmless invocation precondition that can be corrected without modifying repository state, correct it and retry `nvim-exp promote` once.
   * Examples include:

     * the shell is still inside the experimental worktree;
     * the promotion command needs to be launched from the source-stable checkout.
   * Do not treat validation failures as harmless preconditions.
   * If the promotion gate fails validation, or fixing the failure would require modifying the accepted experiment, stop and report the failing gate.
   * Preserve the experiment.

10. If promotion succeeds, verify:

```bash
nvim-exp status
cd ~/projects/neovim
git status
git log -1 --oneline
```

Confirm that source-stable `main` contains the promoted experiment and is in the expected clean state.

11. Stop. Do not push or deploy.

## Report

Report:

* commit hash and message;
* promotion result;
* source-stable status;
* experiment cleanup status;
* push: not performed;
* deployment: not performed.

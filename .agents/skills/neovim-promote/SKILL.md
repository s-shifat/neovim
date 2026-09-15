---
name: neovim-promote
description: Commit and promote the currently active Neovim experiment after explicit human acceptance. Never push or deploy.
---

# Neovim Promote

Use only after explicit user invocation.

This invocation authorizes:

- final inspection of the active accepted experiment;
- committing that experiment;
- running `nvim-exp promote`;
- verifying source-stable `main`.

It does not authorize push, dotfiles pin updates, deployment, discard, or unrelated changes.

## Procedure

1. Read the applicable promotion/lifecycle rules from `AGENTS.md`.

2. Run:

   ```bash
   nvim-exp status
   ```

3. Inspect the final experiment:

   ```bash
   git status
   git diff --check
   git diff
   git ls-files --others --exclude-standard
   ```

   Include untracked files in the review.

4. Stop if:
   - there are unrelated or suspicious changes;
   - source-stable `main` is not in a promotable state;
   - the accepted task appears incomplete.

5. Otherwise create one focused commit.
   - Use a user-supplied commit message if provided.
   - Otherwise inspect recent commit style and choose a concise Conventional Commit message.

   ```bash
   git add -A
   git commit -m "<message>"
   ```

6. Confirm the experiment is clean.

7. Run:

   ```bash
   nvim-exp promote
   ```

   Treat this as the authoritative promotion gate. Do not duplicate or bypass its validation.

8. If promotion fails, stop and report the failing gate. Preserve the experiment.

9. If promotion succeeds, verify:

   ```bash
   nvim-exp status
   cd ~/projects/neovim
   git status
   git log -1 --oneline
   ```

10. Stop. Do not push or deploy.

## Report

Report:

- commit hash and message;
- promotion result;
- source-stable status;
- experiment cleanup status;
- push: not performed;
- deployment: not performed.

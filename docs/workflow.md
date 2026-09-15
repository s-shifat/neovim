# Development Workflow

## Purpose

This document defines the normal development and experimentation workflow for the standalone Neovim repository.

It covers:

- development checkout setup;
- the roles of `nvim`, `nvim-next`, and `nvim-exp`;
- Git worktree experiments;
- starting, inspecting, discarding, and promoting experiments;
- Lua-only and dependency-changing development loops;
- validation during development;
- Git review and commit expectations;
- AI-assisted implementation;
- the boundary between implementation, acceptance, promotion, and deployment.

## Related Documentation

- `docs/architecture.md` — architectural boundaries the workflow must preserve.
- `docs/testing.md` — testing and validation policy.
- `docs/state-isolation.md` — mutable-state isolation rules.
- `docs/behavior.md` — user-facing behavioral contract.
- `docs/deployment.md` — source-stable to deployed-stable procedure.
- `docs/roadmap.md` — current implementation status and future direction.
- `docs/references.md` — canonical repository URLs and durable external references.

Repository locations referenced by this workflow are maintained in `docs/references.md`.

---

# 1. Workflow Principle

Normal development follows:

```text
inspect
    ↓
create one focused experiment
    ↓
implement
    ↓
validate with nvim-next
    ↓
assess test impact
    ↓
assess documentation impact
    ↓
assess roadmap impact
    ↓
inspect the complete change
    ↓
commit accepted experiment
    ↓
nvim-exp promote
    ↓
source stable
    ↓
push
    ↓
deploy separately when desired
```

The central operational principle is:

> Experiment freely. Promote deliberately. Deploy intentionally.

A working-tree edit must never directly become a production change.

---

# 2. User-Facing Commands

The workflow revolves around three commands:

```text
nvim
nvim-next
nvim-exp
```

Their roles are intentionally distinct.

## `nvim`

```text
production editor
```

Use `nvim` for normal work.

Its configuration is immutable and Nix-packaged.

Development changes in the source repository or experiment worktree do not immediately change this editor.

---

## `nvim-next`

```text
experimental editor
```

Use `nvim-next` to test the active experiment.

It loads configuration live from the experiment worktree and uses isolated Neovim application state.

This is where editor changes should be exercised before promotion.

---

## `nvim-exp`

```text
experiment lifecycle manager
```

Use `nvim-exp` for:

```text
setup
new
status
discard
promote
```

It is intentionally a thin interface over ordinary Git worktrees, Git branches, and Nix operations.

It does not replace Git or create a separate hidden project-state system.

---

# 3. Local Development Layout

The normal layout is:

```text
~/projects/neovim
    branch: main
    role: source stable

~/projects/neovim-next
    branch: experiment/<name>
    role: active experiment
```

The experiment directory exists only while an experiment is active.

The paths above are defaults.

`nvim-exp` may be configured to use another development checkout location.

The selected repository path is remembered in:

```text
~/.config/nvim-exp/repo-path
```

There is only one canonical configuration path inside the repository:

```text
config/
```

The experiment contains a different Git revision of that same configuration.

There is no separate development configuration.

---

# 4. Initial Development Setup

Stable Neovim does not require a writable Git checkout.

A machine may use the production `#nvim` package without cloning this repository.

A writable checkout is required only when development or experimentation is requested.

Initialize the development environment with:

```bash
nvim-exp setup
```

`setup` may:

* adopt an existing checkout;
* clone the repository;
* accept an HTTPS Git URL;
* accept an SSH Git URL;
* use the default checkout location;
* remember a non-default checkout location.

The default repository is:

```text
https://github.com/s-shifat/neovim.git
```

The normal default checkout is:

```text
~/projects/neovim
```

Setup should have minimal side effects beyond establishing the development checkout required for experimentation.

---

# 5. Inspect Before Changing

Before beginning a task, inspect the current development state.

Use:

```bash
nvim-exp status
```

and, when needed:

```bash
git status
```

The purpose is to determine:

* which development repository is active;
* current branch;
* current commit;
* whether source stable is clean;
* whether an experiment already exists;
* experiment branch;
* experiment cleanliness.

Do not assume that `main` is clean or that no experiment exists.

`nvim-exp status` is observational.

It should not mutate, clone, create, discard, or promote anything.

---

# 6. One Coherent Experiment at a Time

Each experiment should represent one understandable task.

Preferred examples:

```text
experiment/which-key
experiment/telescope-layout
experiment/lsp-python
experiment/formatting
```

Avoid experiments such as:

```text
experiment/rewrite-everything
```

A focused experiment improves:

* debugging;
* review;
* rollback;
* testing;
* AI-assisted implementation;
* understanding of why a change exists.

Do not bundle unrelated roadmap features into an experiment merely because they are convenient to implement together.

---

# 7. Starting an Experiment

Create an experiment with:

```bash
nvim-exp new <name>
```

For example:

```bash
nvim-exp new which-key
```

Conceptually this creates:

```text
branch:
experiment/which-key

worktree:
~/projects/neovim-next
```

The experiment is based on source-stable `main`.

Source stable must be clean before a new experiment is created.

The experiment worktree is ordinary Git state and may be inspected with normal Git commands.

---

# 8. Implementation Loop

Once the experiment exists, implementation happens in the experiment worktree.

Conceptually:

```text
~/projects/neovim-next
```

The normal loop is:

```text
edit
    ↓
run nvim-next
    ↓
observe
    ↓
diagnose
    ↓
edit again
```

Production `nvim` remains available throughout the experiment.

This is important: a broken experiment should not remove the dependable editor needed to troubleshoot it.

---

# 9. Lua-Only Changes

Lua-only changes alter editor behavior without changing the dependency set.

Examples include:

```text
options
keymaps
autocmds
plugin configuration
Telescope layout
LSP behavior configuration
theme configuration when the theme already exists
UI behavior
```

Edit the experimental configuration:

```text
~/projects/neovim-next/config/
```

Then launch or restart:

```bash
nvim-next
```

A Nix rebuild is normally unnecessary.

The development cycle remains:

```text
edit Lua
    ↓
restart nvim-next
    ↓
observe behavior
```

Do not add unnecessary Nix work to a Lua-only iteration.

---

# 10. Dependency-Changing Changes

Some changes alter what software exists in the editor environment.

Examples include:

```text
new plugin
new Treesitter parser
new language server
new formatter
new linter
new external executable
Neovim package/version change
```

These changes require Nix declarations.

The experiment therefore changes both:

```text
Nix
→ dependency availability

Lua
→ dependency behavior
```

`nvim-next` enters the development environment from the active experiment revision.

Conceptually:

```text
experimental worktree
        ↓
nix develop
        ↓
experimental dependencies
        ↓
nvim-next
```

Nix prepares the changed development environment as required.

This does not require rebuilding the entire NixOS system.

Once the dependency environment is available, further Lua configuration iterations can again remain fast.

---

# 11. Dependency Ownership During Development

Do not work around a missing dependency by introducing runtime installation.

If the editor requires a new:

* plugin;
* language server;
* formatter;
* parser;
* executable;
* linter;

declare it through Nix.

The workflow must preserve:

```text
Nix owns availability.
Lua owns behavior.
```

A dependency-changing experiment should make the dependency change explicit in the Git diff.

---

# 12. Manual Validation

Use:

```bash
nvim-next
```

for interactive validation of editor behavior.

Relevant validation depends on the task.

Examples:

```text
keymap change
→ exercise the mapping

colorscheme change
→ launch the editor and inspect theme behavior

autocmd change
→ trigger the actual event

Telescope change
→ open the affected picker

LSP change
→ open a relevant language buffer and exercise the behavior
```

Startup success alone is not sufficient evidence for behavior that is triggered later.

Do not claim that visual or interactive behavior was validated unless it was actually exercised.

Production `nvim` should remain unaffected during this process.

---

# 13. Test-Impact Assessment

Every meaningful change should include a test-impact assessment.

The implementation workflow asks:

```text
What new failure could this change introduce?

Does an existing test already detect it?

If not, is a new regression test warranted?
```

Tests should be added or updated only when they protect a meaningful structural or integration invariant or a likely regression.

Detailed policy belongs in:

```text
docs/testing.md
```

The workflow should not accumulate brittle tests merely because a setting changed.

## Roadmap-Impact Assessment

Every meaningful change should also include a roadmap-impact assessment before the experiment is considered complete or ready for promotion.

The implementation workflow asks:

```text
Does this change project implementation status?

Does it materially change the scope of a roadmap stage?

Does it change what should be worked on next?

Does it make any existing roadmap statement inaccurate?
```

Update `docs/roadmap.md` when the task:

- completes or materially advances a roadmap stage;
- changes what a roadmap stage actually implements;
- changes which stage should be marked `CURRENT`;
- adds, removes, splits, combines, renames, reorders, or defers planned work;
- makes an existing roadmap statement inaccurate.

When a stage is completed, its roadmap section should stop describing only expected work and should instead record what actually landed.

The completed stage should be marked:

```text
COMPLETE
```

and the appropriate next stage should become:

```text
CURRENT
```

Ordinary bug fixes, refactors, test changes, documentation corrections, or implementation details that do not affect roadmap status, scope, or sequencing do not require a roadmap change.

When a roadmap update is required, make it inside the active experiment before the final experiment commit and before `nvim-exp promote`.

The roadmap should describe meaningful implementation state rather than track every commit. Exact Git revisions should be determined from the repository when needed.

---

# 14. Required Checks vs Diagnostic Checks

Not every development iteration requires the complete validation suite.

During debugging or dependency work, it may be useful to run:

```bash
nix flake check path:. --print-build-logs
```

manually.

However, this is not a mandatory command before every commit.

The reason is that:

```bash
nvim-exp promote
```

already acts as an enforced validation gate.

During iteration, prefer the narrowest check that provides useful feedback.

Use broader checks when:

* debugging packaging;
* changing Nix infrastructure;
* changing dependencies;
* investigating a failing promotion gate;
* validating a new structural invariant.

Do not repeatedly run expensive checks without a reason when the authoritative promotion workflow already runs them.

---

# 15. Inspect the Change Before Acceptance

Before deciding that an experiment is ready, inspect the entire repository change.

Use:

```bash
git status
git diff
```

Review for:

* requested behavior;
* accidental unrelated edits;
* unexpected generated files;
* unnecessary dependency changes;
* lockfile changes;
* debug code;
* temporary workarounds;
* test changes;
* required documentation updates;
* required roadmap updates.

The final diff should represent one coherent task.

Do not treat successful execution as a substitute for reviewing what changed.

---

# 16. Commit the Experiment

Promotion requires the experiment to be committed and clean.

Once the behavior is understood and accepted for promotion:

```bash
git add <relevant-files>
git commit -m "<appropriate message>"
```

The experiment commit should contain the coherent implementation being promoted.

Before promotion:

```bash
git status
```

should show a clean experiment worktree.

Uncommitted experiments are development state, not promotion candidates.

After human review and acceptance, explicit invocation of the repo-local
`$neovim-promote` skill may perform this commit and promotion boundary:

```text
implementation
        ↓
human review / acceptance
        ↓
explicit $neovim-promote
        ↓
commit
        ↓
nvim-exp promote
        ↓
source-stable main
        ↓
stop
```

The skill is a convenience wrapper around the accepted workflow, not a second
promotion mechanism. `nvim-exp promote` remains the authoritative mechanical
validation and promotion gate. Push and deployment remain separate explicit
actions, and the skill does not authorize discard, dotfiles pin changes, or
unrelated edits.

---

# 17. `nvim-exp promote`

Promotion moves an accepted experiment into source-stable `main`.

Before entering the promotion gate, all required code, tests, and documentation—including any required roadmap update—must already be committed in the experiment.

It does not deploy production Neovim.

The current promotion gate verifies, in substance:

```text
source stable is clean
        ↓
experiment is committed and clean
        ↓
experiment descends from current main
        ↓
nix flake check candidate
        ↓
build candidate #nvim
        ↓
run stable-vs-experimental state-isolation regression
        ↓
fast-forward main
        ↓
remove experiment worktree
        ↓
delete experiment branch
```

Promotion therefore performs both:

```text
validation
+
source-stable transition
```

It is the authoritative experiment → source-stable mechanism.

Do not manually reproduce the normal promotion sequence unless troubleshooting the workflow itself.

---

# 18. Why Promotion Requires Ancestry

The experiment must descend from the current source-stable `main`.

Conceptually:

```text
main
  \
   experiment/feature
```

must still represent a valid fast-forward relationship.

If source stable changes independently after the experiment was created, promotion should stop rather than silently merge divergent histories.

The workflow should make that situation visible so it can be resolved deliberately using normal Git mechanisms.

The promotion helper should not hide or invent conflict-resolution policy.

---

# 19. After Promotion

Successful:

```bash
nvim-exp promote
```

results in:

```text
experiment/<feature>
        ↓
main
```

and the temporary experiment worktree/branch are removed.

At this point:

```text
source stable
```

contains the accepted change.

Production `nvim` is still unchanged unless the deployment repository is updated separately.

---

# 20. Push Source Stable

After successful promotion, source stable may be pushed:

```bash
cd ~/projects/neovim
git push origin main
```

This publishes the accepted standalone Neovim source.

Pushing `main` still does not automatically change the deployed editor.

Source publication and production deployment remain separate actions.

---

# 21. Production Deployment Is Separate

The workflow intentionally distinguishes source acceptance from production deployment.

Conceptually:

```text
experiment
    ↓
source stable
    ↓
push
```

is development/promotion.

Then separately:

```text
source stable
    ↓
dotfiles pin update
    ↓
build
    ↓
switch
```

is deployment.

Detailed deployment procedures and rollback belong in:

```text
docs/deployment.md
```

Deployment may happen immediately after promotion or much later.

That delay is valid.

---

# 22. Discarding an Experiment

If an experiment is rejected:

```bash
nvim-exp discard
```

removes the experimental worktree and experiment branch after confirmation.

It does not modify source-stable `main`.

Conceptually:

```text
experiment
    ↓
reject
    ↓
discard

main
→ unchanged
```

Discarding is appropriate when:

* the approach is no longer wanted;
* the experiment is being abandoned;
* implementation should restart from source stable.

Do not create custom rollback infrastructure for a normal rejected experiment.

---

# 23. Recovery Philosophy

The workflow relies on ordinary Git and Nix mechanisms rather than custom rollback systems.

Relevant mechanisms include:

```text
discarding an experiment
Git commits
Git revert/reset where deliberately appropriate
source-stable history
deployment lock revisions
Nix generations
```

Do not introduce parallel `nvim-old`, backup-config, or hidden snapshot systems unless normal Git/Nix recovery mechanisms prove insufficient.

The underlying state should remain inspectable.

---

# 24. Fresh-Machine Workflow

Stable consumption and development setup are intentionally separate.

A machine may install only the stable editor:

```bash
nix profile install github:s-shifat/neovim#nvim
```

without a repository clone.

A machine that installs the full workflow receives the relevant commands but still does not need to clone the repository automatically.

Only when development is requested does the workflow establish a writable checkout through:

```bash
nvim-exp setup
```

This preserves a low-side-effect stable installation model.

---

# 25. AI-Assisted Task Workflow

AI-assisted implementation follows the same experiment architecture as manual development.

The AI agent does not get a separate development model.

The current task flow is:

```text
user + ChatGPT
    ↓
discuss design / behavior
    ↓
lock one coherent task
    ↓
generate structured implementation ticket
    ↓
paste ticket into Codex CLI
    ↓
Codex inspects repository state
    ↓
Codex works through the normal experiment workflow
    ↓
implementation + relevant validation
    ↓
review resulting diff
    ↓
user accepts, revises, or rejects
```

There is no required GitHub issue, ticket database, or task file in the repository.

The structured ticket is execution context for the current Codex session.

Durable project rules belong in:

```text
AGENTS.md
```

and durable project knowledge belongs in:

```text
docs/
```

## AI Documentation Responsibility

Documentation-impact assessment is part of AI-assisted implementation even when the task specification does not explicitly request documentation changes.

Before considering a task complete or ready for promotion, Codex should determine whether the implementation requires updates to durable project documentation.

This includes a mandatory roadmap-impact assessment using the rules defined earlier in this document.

The task specification does not need to repeat:

```text
update docs/roadmap.md if necessary
```

for every implementation task.

Roadmap-impact assessment is a standing workflow responsibility.

When a roadmap update is required, Codex should make that change inside the same experiment before the final experiment commit.

When reporting completion, Codex should state one of:

```text
Roadmap impact: updated
```

or:

```text
Roadmap impact: none — <brief reason>
```

This report records that roadmap impact was considered; it does not create a separate task-tracking system.

The ticket should therefore describe the current task rather than duplicate the entire project architecture.

---

# 26. AI Scope Discipline

An AI implementation task should represent one coherent change.

Codex should not use a ticket as permission to:

* implement unrelated roadmap features;
* redesign established architecture;
* perform broad cleanup;
* replace working components without need;
* create new workflow infrastructure;
* introduce a second experiment mechanism.

The requested task defines the scope.

Existing project architecture and documentation define the constraints.

If an unrelated improvement is discovered, it should be reported separately rather than silently folded into the task.

---

# 27. AI and the Existing Experiment Workflow

Codex should use the existing mechanisms rather than create agent-specific equivalents.

Use:

```text
nvim-exp
Git
Nix
existing tests
```

Do not create parallel mechanisms such as:

```text
codex-exp
agent-worktree
AI-only config tree
hidden task-state database
```

The same workflow should remain understandable whether the implementation was written manually or with an agent.

---

# 28. Human Acceptance Boundary

AI implementation does not imply acceptance.

The user remains responsible for deciding whether an experiment should be:

```text
revised
discarded
promoted
pushed
deployed
```

A normal Codex implementation task should produce a reviewable experiment.

Promotion or deployment should occur only when the current task explicitly includes that action or the user performs it separately.

This preserves the distinction between:

```text
agent says implementation is complete
```

and:

```text
user accepts implementation into stable source
```

---

# 29. Normal Task Lifecycle

A complete feature task can therefore be summarized as:

```text
1. Define one coherent task.

2. Inspect current source/experiment state.

3. Create or use the appropriate experiment.

4. Implement the requested change.

5. Validate through nvim-next.

6. Assess test impact.

7. Run relevant automated checks.

8. Assess documentation impact.

9. Assess roadmap impact.

10. Update required documentation, including docs/roadmap.md when applicable.

11. Inspect git status and diff.

12. Review the behavior/change.

13. Commit the accepted experiment.

14. Run nvim-exp promote.

15. Push source-stable main.

16. Deploy separately when desired.
```

Not every step must be performed by the same actor.

For example:

```text
ChatGPT
→ specification

Codex
→ implementation + validation

user
→ review + acceptance

nvim-exp
→ enforced promotion gate

dotfiles/Nix
→ deliberate deployment
```

The underlying workflow remains the same.

---

# 30. Workflow Invariants

The following should remain true unless the workflow is deliberately redesigned.

1. Production `nvim` is not the development target.

2. Normal feature work happens in an experiment.

3. Experiments are ordinary Git branches/worktrees.

4. One experiment should represent one coherent change.

5. `nvim-exp status` remains observational.

6. Lua-only changes normally require only restarting `nvim-next`.

7. Dependency-changing work declares dependencies through Nix.

8. The experimental environment may rebuild without requiring a full NixOS rebuild.

9. Manual validation uses `nvim-next`.

10. Every meaningful task includes a test-impact assessment.

11. Every meaningful task includes a documentation-impact assessment.

12. Every meaningful task includes a roadmap-impact assessment.

13. Required roadmap changes are made inside the experiment before promotion.

14. Broad checks are run when useful; they are not repeated mechanically without reason.

15. Promotion requires a clean committed experiment.

16. Promotion verifies the experiment before updating source-stable `main`.

17. Promotion must not automatically deploy production.

18. Successful promotion removes the temporary experiment worktree and branch.

19. Source stable may be newer than deployed stable.

20. Rejected experiments may be discarded without changing `main`.

21. Recovery relies primarily on ordinary Git and Nix mechanisms.

22. AI agents use the same workflow as human development.

23. AI implementation does not by itself constitute user acceptance.

---

# 31. One-Screen Workflow

```text
                         TASK
                           │
                           ▼
                    nvim-exp status
                           │
                           ▼
                  nvim-exp new <task>
                           │
                           ▼
              experiment/<task> worktree
                           │
                 ┌─────────┴─────────┐
                 │                   │
             Lua change        dependency change
                 │                   │
             edit config/       edit Nix + Lua
                 │                   │
                 └─────────┬─────────┘
                           │
                           ▼
                       nvim-next
                           │
                    edit / validate
                           │
                           ▼
                 test-impact assessment
                           │
                           ▼
                  relevant validation
                           │
                           ▼
             documentation-impact assessment
                           │
                           ▼
                roadmap-impact assessment
                           │
                           ▼
             update docs when required
                           │
                           ▼
                  git status / diff
                           │
                     ┌─────┴─────┐
                     │           │
                   reject      accept
                     │           │
                     ▼           ▼
              nvim-exp discard  commit
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
                        deployment boundary
                                 │
                                 ▼
                         deployed production
                                nvim
```

---

# 32. Governing Principle

The development workflow exists to make experimentation cheap while keeping production conservative.

The concise model is:

```text
DISCUSS CLEARLY.
CHANGE ONE THING.
TEST IN ISOLATION.
REVIEW THE DIFF.
PROMOTE DELIBERATELY.
DEPLOY SEPARATELY.
```

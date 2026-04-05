# TraceForge CLI-First Demo Readiness Plan

## Purpose

This is the active execution plan for turning TraceForge into a first-place-caliber JacHacks submission.

The product direction is now explicit:

- TraceForge is an **AI-coding-first CLI tool**
- the primary users are operators inside **Codex CLI** and **Claude Code**
- the primary value is **better trajectory analysis through better evidence structure**
- the UI is secondary and should be treated as an optional appendix and fallback demo surface

This plan is intentionally more detailed than the earlier completion plans because we need two things at once:

1. a terminal-first product story strong enough to win the hackathon
2. a coordination model that lets multiple agents work in parallel without overwriting each other

## Mission

Ship a version of TraceForge that a developer or coding agent can install from the GitHub URL alone, run from the terminal, and use immediately to transform raw coding-agent trajectories into structured evidence packs that Codex or Claude Code can reason over more effectively.

The winning story is not:

> we built a nicer trace browser

The winning story is:

> developers already work in Codex CLI and Claude Code, and TraceForge upgrades that workflow by compiling raw trajectories into graph-backed evidence packs that are easier for agents to analyze correctly

## Product Positioning

TraceForge should be presented as:

> a graph-backed CLI for compiling coding-agent trajectories into structured evidence packs, critical-step localizations, recurring-failure clusters, and reusable memory rules

It should not be presented primarily as:

> a UI for browsing logs

That means the default user journey is:

1. clone repo
2. run install/bootstrap
3. run `traceforge doctor`
4. analyze a sample or uploaded batch
5. inspect a run or cluster in the terminal
6. generate `raw` and `structured` evidence packs
7. feed those packs into Claude Code or Codex
8. optionally run built-in comparison or export artifacts

## Winning Demo Thesis

The strongest sentence in the demo should be:

> same failed run, same outer model, better evidence pack

That is a cleaner and more defensible story than "our model beats their model."

The built-in provider-backed comparison is still useful, but it should support the story rather than define it.

## First-Place Success Criteria

To feel like a first-place submission, TraceForge needs to hit all of these:

1. The repo can be understood without reading source.
2. A coding agent can install and run the tool from the docs alone.
3. The CLI is clearly the primary product surface.
4. The Jac graph is visibly essential to the core value.
5. The raw-versus-structured evidence difference is obvious in one terminal session.
6. Provider-backed comparison works when available and fails clearly when unavailable.
7. The demo has a safe fallback path that still lands the thesis.
8. The repo and docs look deliberate, not hacky.

## Current Baseline

The repo already has:

- Jac-native parsing, graph compilation, clustering, and critical-step localization
- graph-backed walkers for batch, run, cluster, comparison, and report flows
- sample and local upload ingestion
- provider config support for OpenAI, Anthropic, and Codex CLI
- exports for blinded evaluation, rigorous summaries, gold annotations, and reports
- a working UI path and a stronger visual layer than before

The underlying engine is strong enough.
The product surface is what now needs to be shaped.

## Main Gaps

### Gap 1: The public interface is still Jac-internal

`jac enter main.jac ...` is acceptable for development and weak for product use.
It exposes walkers, positional argument quirks, and Jac-specific mechanics that users should never need to know.

### Gap 2: Pack generation is not yet the primary product surface

The most valuable workflow is:

- show me the raw evidence pack
- show me the structured evidence pack
- let my coding agent reason over the difference

That workflow exists internally but is not yet the center of the tool.

### Gap 3: Provider execution is not demo-safe enough

Provider-backed evaluation can degrade into deterministic fallback.
That is acceptable for local development and dangerous in a live demo if not surfaced clearly.

### Gap 4: The repo docs are not yet operator-grade

A user should be able to paste the GitHub URL into Codex or Claude Code and have the agent install and run TraceForge from the README and CLI docs alone.
The current docs still read like a Jac project README, not a polished tool manual.

### Gap 5: The demo story is still split between UI and CLI

That makes the product feel undecided.
We need one primary demo path and one fallback path.

### Gap 6: Parallel implementation is still underspecified

If multiple agents work at the same time, they can still collide on shared files, docs, and public command surfaces unless we define ownership and merge rules tightly.

## Product Contract

By demo time, the product should behave like this:

### Primary operator workflow

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter --input demo_runs/starter_batch
traceforge overview --batch sample-starter
traceforge run --batch sample-starter --run invalid_patch
traceforge pack --batch sample-starter --run invalid_patch --mode raw --format md
traceforge pack --batch sample-starter --run invalid_patch --mode structured --format md
```

### Optional provider-backed workflow

```bash
traceforge compare --batch sample-starter --run invalid_patch --provider codex --strict-provider
traceforge export-eval --batch sample-starter --provider openai --strict-provider
```

### Artifact workflow

```bash
traceforge export-report --batch sample-starter
traceforge export-eval --batch sample-starter
```

## What The CLI Must Expose

The public CLI surface should be intentionally small.

### Core commands

- `traceforge doctor`
- `traceforge analyze-batch`
- `traceforge overview`
- `traceforge run`
- `traceforge cluster`
- `traceforge pack`
- `traceforge compare`
- `traceforge export-report`
- `traceforge export-eval`
- `traceforge auth status`
- `traceforge auth use`
- `traceforge auth clear`

### Output modes

Every command that matters should support:

- human-readable terminal output by default
- `--json` for automation

### Guarantees

The CLI should provide:

- stable exit codes
- stable field names in JSON mode
- no Python-dict-style stdout as the public interface
- clear mode reporting:
  - provider-backed
  - deterministic fallback
  - export-only

## Workstreams

## Workstream 1: Public CLI Wrapper

### Objective

Ship a first-party `traceforge` entrypoint so users no longer operate the product through raw Jac walker calls.

### Deliverables

- wrapper entrypoint
- named flags
- normalized output rendering
- `--json`
- consistent exit codes
- mapping from CLI subcommands to Jac walkers

### Required behavior

- the CLI should hide walker names
- the CLI should hide positional Jac argument quirks
- error messages should be operator-friendly

### Candidate files

- `main.jac`
- [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)
- [provider_config.jac](/home/gb10/Projects/JacHacks/traceforge/provider_config.jac)
- new wrapper files such as:
  - `traceforge/cli.jac`
  - `traceforge/cli.py` packaging shim
  - `scripts/traceforge`
  - package entrypoint metadata

### Done when

- the primary README never needs `jac enter` in the first-run flow
- users can discover the product from `traceforge --help`

## Workstream 2: Pack-First Product Surface

### Objective

Make evidence-pack generation the center of the product.

### Deliverables

- `pack --mode raw`
- `pack --mode structured`
- markdown output optimized for pasting into Codex or Claude Code
- JSON output optimized for automation

### Required structured-pack contents

- task summary
- failure-family guess
- localized critical-step candidates
- exact evidence windows
- top files, errors, and tests
- cluster context
- memory rule or patch hint if available

### Required raw-pack contents

- compressed trajectory
- canonical step mapping
- enough context for a baseline analysis

### Done when

- the pack commands can carry the demo even if live provider-backed compare is unavailable

## Workstream 3: Provider And Auth Hardening

### Objective

Make provider execution explicit, reliable, and demo-safe.

### Deliverables

- `traceforge doctor`
- `traceforge auth status`
- `traceforge auth use codex|openai|anthropic`
- `traceforge auth clear`
- `--strict-provider`
- clear exit codes and error messages

### Required checks in `doctor`

- Codex CLI installed or missing
- Codex CLI logged in or not
- OpenAI key present or absent
- Anthropic key present or absent
- active provider selection
- resolved provider
- strict-mode viability
- path to config file

### Required behavior

- strict mode must exit non-zero on provider failure
- no silent fallback in strict mode
- explicit warning when non-strict mode falls back
- output must clearly distinguish:
  - live provider verdict
  - deterministic fallback verdict
  - no-provider mode

### Done when

- an operator cannot accidentally misstate what produced a result

## Workstream 4: Installation And Bootstrap

### Objective

Make installation simple enough that a coding agent can infer the setup from the repo docs alone.

### Deliverables

- one clear setup path for macOS and Linux
- one bootstrap script or Make target
- one "quick install" sequence near the top of the README
- a working `doctor` command immediately after install

### Required operator experience

A user should be able to instruct Codex or Claude Code:

> clone the repo, install TraceForge, run the sample batch, and show me the structured pack for one failed run

and the agent should succeed without reading implementation files.

### Done when

- install fits in a short Quickstart section
- setup errors are caught by `doctor`

## Workstream 5: Output Normalization

### Objective

Make outputs stable enough for both humans and agents.

### Deliverables

- normalized JSON schemas
- readable terminal rendering
- consistent field names
- artifact metadata on all export-producing commands

### JSON fields that should exist consistently

- `status`
- `mode`
- `provider`
- `provider_available`
- `strict_provider`
- `batch_id`
- `run_id`
- `cluster_id`
- `artifact_paths`
- `comparison_mode`
- `warning`
- `error`

### Done when

- Claude Code or Codex can parse outputs reliably
- the public interface no longer leaks internal development formatting

## Workstream 6: Docs Rewrite

### Objective

Rewrite the docs so the repo reads like a polished CLI tool for AI coding workflows.

### README must answer these questions immediately

1. What is TraceForge?
2. Who is it for?
3. Why would I use it inside Codex CLI or Claude Code?
4. How do I install it?
5. How do I run one sample workflow?
6. How do I generate raw and structured packs?
7. How do I use provider-backed compare if I want it?
8. Where do artifacts land?

### New docs to add

- `docs/cli/quickstart.md`
- `docs/cli/provider_setup.md`
- `docs/cli/agent_workflows.md`
- `docs/cli/demo_playbook.md`
- `docs/cli/output_schema.md`

### Existing docs to rewrite

- [README.md](/home/gb10/Projects/JacHacks/README.md)
- [demo_script.md](/home/gb10/Projects/JacHacks/docs/submission/demo_script.md)
- [devpost_outline.md](/home/gb10/Projects/JacHacks/docs/submission/devpost_outline.md)
- [judging_notes.md](/home/gb10/Projects/JacHacks/docs/submission/judging_notes.md)

### Required documentation standard

Every public command should have:

- one-line purpose
- one copy-paste example
- expected output form
- failure mode notes

### Done when

- the repo can onboard a new user without source diving
- the docs feel like product docs, not internal notes

## Workstream 7: Demo Hardening

### Objective

Make the terminal demo survive provider issues, quota issues, and operator mistakes.

### Deliverables

- one canonical live demo path
- one canonical fallback path
- one canonical sample run
- precomputed backup artifacts
- a short operator cheat sheet

### Primary demo flow

1. `traceforge doctor`
2. `traceforge analyze-batch --batch sample-starter ...`
3. `traceforge run --batch sample-starter --run invalid_patch`
4. `traceforge pack --batch sample-starter --run invalid_patch --mode raw`
5. `traceforge pack --batch sample-starter --run invalid_patch --mode structured`
6. `traceforge compare ... --strict-provider` if live provider is available

### Fallback demo flow

1. `traceforge doctor`
2. `traceforge run ...`
3. `traceforge pack ... --mode raw`
4. `traceforge pack ... --mode structured`
5. open exported comparison JSON or rigorous markdown summary

### Done when

- the demo still lands even if provider-backed compare cannot run live

## Workstream 8: Submission Story Rewrite

### Objective

Make the pitch, README, and Devpost all tell the same terminal-first story.

### Story to emphasize

- developers already work in Codex and Claude Code
- TraceForge plugs into those workflows
- Jac is essential because it provides the graph model and walkers
- the value is better evidence structure, not just another UI

### Demo soundbite

> same failed run, same outer model, better evidence pack

### Done when

- the product story feels focused and memorable

## Workstream 9: Minimal UI Strategy

### Objective

Keep the UI healthy enough for backup use without spending product energy there.

### Rules

- no large new feature work in the UI unless it supports the CLI story directly
- the UI remains a fallback artifact viewer and optional judge appendix
- README should not lead with the UI

### Done when

- the UI does not distract from the main CLI product

## Workstream 10: Verification And Acceptance

### Objective

Define what "done" means in a way that multiple agents can work against cleanly.

### Acceptance checks

- sample install flow works from docs
- `traceforge doctor` reports correct mode
- sample batch can be analyzed from CLI
- raw pack renders cleanly
- structured pack renders cleanly
- compare either:
  - runs live in strict mode, or
  - fails clearly and predictably
- report and eval exports land in documented paths
- README quickstart matches actual commands

## Parallel Execution Model

This repo should now be treated as a multi-agent workspace with strict ownership.

The rule is:

> one workstream owns a file set at a time; shared integration files are edited only by the integrator unless explicitly handed off

## Roles

### Integrator

Owns:

- `README.md`
- `main.jac`
- public CLI entrypoint wiring
- public command naming
- final merge decisions
- final demo path

Responsibilities:

- keep product shape coherent
- resolve interface conflicts
- merge worker output
- guard the public CLI contract

### Worker A: CLI Wrapper And Output

Owns:

- new CLI wrapper files
- output renderer
- CLI help text
- JSON schema docs draft

### Worker B: Pack Surface

Owns:

- pack builders
- run/cluster human-readable renderers
- structured-pack and raw-pack formatting

### Worker C: Provider And Auth

Owns:

- provider config behavior
- `doctor`
- auth commands
- strict-provider enforcement

### Worker D: Docs And Demo

Owns:

- CLI quickstart docs
- provider setup docs
- demo playbook
- submission docs rewrites

### Worker E: Export And Artifact Polish

Owns:

- export-report UX
- export-eval UX
- output file naming polish
- fallback artifact packaging

## File Ownership Matrix

The following ownership should be observed during implementation.

### Integrator-owned files

- `README.md`
- `main.jac`
- packaging entrypoint config
- any repo-root bootstrap file

### Worker A-owned files

- new `traceforge/cli.jac`
- thin `traceforge/cli.py` packaging shim
- new `scripts/traceforge`
- new CLI formatting helpers

### Worker B-owned files

- [analysis.jac](/home/gb10/Projects/JacHacks/traceforge/analysis.jac)
- [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)
- new pack renderer helpers

### Worker C-owned files

- [provider_config.jac](/home/gb10/Projects/JacHacks/traceforge/provider_config.jac)
- [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- provider-related slices of [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)

### Worker D-owned files

- `docs/cli/*.md`
- [demo_script.md](/home/gb10/Projects/JacHacks/docs/submission/demo_script.md)
- [devpost_outline.md](/home/gb10/Projects/JacHacks/docs/submission/devpost_outline.md)
- [judging_notes.md](/home/gb10/Projects/JacHacks/docs/submission/judging_notes.md)

### Worker E-owned files

- [reporting.jac](/home/gb10/Projects/JacHacks/traceforge/reporting.jac)
- export-related slices of [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)

## Shared-File Rules

These files are shared-risk files and should not be edited casually by multiple agents:

- `main.jac`
- `README.md`
- `traceforge/api.jac`
- `traceforge/eval.jac`

Rules:

1. Only the integrator edits `main.jac` and `README.md`.
2. `api.jac` changes must be queued and merged by the integrator unless one worker is explicitly assigned sole ownership for a time window.
3. `eval.jac` must be split by responsibility before parallel work starts. If that is not practical, only one worker edits it per cycle.
4. If two workstreams need `eval.jac`, one of them must first extract helper functions into new files so ownership becomes clean.

## Branch And Worktree Strategy

Each parallel agent should work in its own branch or worktree.

Recommended branch names:

- `thread/integrator-cli-shape`
- `thread/cli-wrapper`
- `thread/pack-surface`
- `thread/provider-hardening`
- `thread/docs-demo`
- `thread/export-polish`

Recommended rule:

- never have two agents committing to the same branch

Recommended worktree rule:

- one worktree per active agent if possible
- otherwise one branch per agent with disciplined rebases and merges

## Merge Protocol

Every merge cycle should follow this exact order:

1. worker finishes a small vertical slice in owned files
2. worker writes a short handoff summary:
   - commands added
   - files touched
   - interfaces changed
   - assumptions
3. integrator reviews for public-surface conflicts
4. integrator merges into the main working branch
5. integrator updates shared docs only after merge
6. next worker picks up only after shared-surface conflicts are resolved

Do not allow giant parallel branches to diverge for long.
Merge frequently and keep slices small.

## Handoff Template For Parallel Agents

Every worker handoff should include:

- objective completed
- files changed
- public commands added or changed
- JSON fields added or changed
- known limitations
- docs impact

This should be written in plain text in the handoff message or commit body.

## No-Overwrite Guardrails

To prevent overwrite damage:

1. never have two agents editing `README.md` simultaneously
2. never have two agents editing `main.jac` simultaneously
3. do not let docs workers rewrite command names while CLI workers are still renaming commands
4. do not let provider workers change default command semantics without the integrator updating docs in the same merge cycle
5. if a worker needs a shared file unexpectedly, stop and reassign ownership first

## Phase Plan

## Phase 1: Product Surface Lock

### Goal

Freeze the CLI shape before broad implementation.

### Tasks

- finalize command list
- finalize flag naming
- finalize JSON-mode contract
- finalize strict-provider behavior

### Must happen before

- major docs rewrite
- help text polish
- demo script finalization

## Phase 2: Wrapper And Pack MVP

### Goal

Ship the first usable public CLI for the core demo path.

### Tasks

- add wrapper
- expose `doctor`
- expose `run`
- expose `pack`
- expose `compare`
- normalize output

### Outcome

The CLI demo becomes viable even before all exports are polished.

## Phase 3: Provider Hardening

### Goal

Make live compare trustworthy and optional.

### Tasks

- strict mode
- better errors
- auth commands
- doctor details

### Outcome

Live provider-backed compare becomes safe to use in a demo.

## Phase 4: Docs Rewrite

### Goal

Make the repo self-explanatory from the GitHub URL alone.

### Tasks

- rewrite README
- add CLI docs
- update submission docs

### Outcome

A coding agent can install and run TraceForge from the docs alone.

## Phase 5: Export And Demo Backup

### Goal

Make the product resilient under demo conditions.

### Tasks

- polish report export
- polish eval export
- prepare fallback artifacts
- finish terminal demo playbook

### Outcome

The demo still works even if live providers fail.

## Risks And Mitigations

### Risk: CLI wrapper becomes too thin and leaks Jac internals

Mitigation:

- forbid raw walker names from the README quickstart
- require stable command aliases and help text

### Risk: provider fallback causes ambiguous demo output

Mitigation:

- require `--strict-provider` in all judge-facing live compare examples
- surface mode clearly in command output

### Risk: multiple agents overwrite each other on shared files

Mitigation:

- enforce ownership zones
- use separate branches/worktrees
- route shared-file changes through the integrator

### Risk: docs drift from real commands

Mitigation:

- docs update happens only after command names are frozen
- one docs owner per cycle

### Risk: UI work distracts from CLI work

Mitigation:

- freeze major UI work
- treat UI only as fallback or appendix

## Definition Of Demo Ready

TraceForge is demo ready when:

1. a fresh clone can be installed from the docs
2. `traceforge doctor` works
3. a sample batch can be analyzed from CLI
4. raw and structured packs can be produced from CLI
5. the difference between those packs is obvious
6. provider-backed compare either works clearly or fails clearly
7. export artifacts are prepared and documented
8. the README matches the live demo path exactly

## Definition Of First-Place Ready

TraceForge is first-place ready when:

- the product surface matches real AI-coding workflow
- the technical depth is visible through the CLI itself
- Jac feels essential rather than decorative
- the docs make onboarding feel intentional and professional
- the demo is simple, robust, and memorable

## Immediate Next Slice

The first implementation slice should be:

1. lock the public CLI command surface
2. implement the wrapper with `doctor`, `run`, `pack`, and `compare`
3. make pack generation the primary demo path
4. then rewrite the top of the README and add CLI quickstart docs

This slice has the highest leverage because it changes the product shape, the docs shape, and the demo shape at the same time.

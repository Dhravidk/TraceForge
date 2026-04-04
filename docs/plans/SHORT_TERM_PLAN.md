# TraceForge Short-Term Plan

## Purpose

This is the **get-started execution plan** for the first phase of JacHacks 2026.
It is aligned with the longer brief in [LONG_TERM_PLAN.md](/home/gb10/Projects/JacHacks/LONG_TERM_PLAN.md), but it is optimized for:

- getting a stable demo skeleton running fast,
- keeping the repo clean for a public JacHacks submission,
- maximizing parallel Codex throughput,
- and preventing overwrite conflicts between threads.

This plan is based on the live JacHacks 2026 public guide:

- Jac must be used in a meaningful, non-trivial way.
- Code must be written during the hackathon.
- The event is 24 hours.
- Submission closes at **11:00 AM on Sunday, April 5, 2026**.
- The pitch is **3 minutes**.
- Judging weights are:
  - 35% technical depth
  - 30% Jac integration
  - 20% real-world impact
  - 15% presentation

## Short-Term Goal

In the first working block, we are not trying to finish the product.
We are trying to make the repo ready for fast, safe, parallel implementation.

At the end of this short-term phase, we should have:

- a clean repo layout,
- a Jac-first app skeleton,
- sample data locations defined,
- clear module boundaries,
- named workstreams with non-overlapping write ownership,
- and a merge/integration protocol that prevents threads from fighting over the same files.

## Target Repo Layout

This is the structure we should create first before heavy coding starts:

```text
JacHacks/
  LONG_TERM_PLAN.md
  README.md
  jac.toml
  main.jac
  .gitignore
  docs/
    plans/
      SHORT_TERM_PLAN.md
    submission/
      demo_script.md
      devpost_outline.md
      judging_notes.md
  traceforge/
    __init__.jac
    schema.jac
    api.jac
    ingest.jac
    analysis.jac
    llm_ops.jac
    ui.jac
  py/
    parser.py
    features.py
    similarity.py
    utils.py
  demo_runs/
    README.md
  uploads/
    .gitkeep
  exports/
    .gitkeep
  tests/
    README.md
```

## Why This Layout

- `main.jac` stays thin and stable. It should mostly wire imports and app startup.
- `traceforge/` holds the Jac-native core so Jac remains visibly central.
- `py/` holds helper code only where it saves time materially.
- `LONG_TERM_PLAN.md` stays at the root as the canonical brief for humans and coding agents.
- `docs/plans/` holds active execution plans and coordination notes.
- `docs/submission/` keeps hackathon submission assets easy to find late in the event.
- `demo_runs/`, `uploads/`, and `exports/` make the live demo path explicit.
- `tests/` gives us a visible place for acceptance checks even if they start lightweight.

## Non-Overwrite Rule

We should treat this repo as a **multi-thread workspace with exclusive ownership zones**.

The rule is simple:

> one thread owns a file or module at a time; shared files are edited only by the integrator thread unless a handoff is explicit.

## Coordination Model

Use one **integrator thread** and multiple **worker threads**.

### Integrator thread

Owns:

- `README.md`
- `jac.toml`
- `main.jac`
- repo-level structure
- final merge decisions
- final naming and interface consistency

Responsibilities:

- create the skeleton,
- keep imports and public entrypoints coherent,
- merge worker output,
- resolve conflicts,
- and maintain the demo path.

### Worker threads

Each worker gets a **disjoint write set**.
Workers should not edit files owned by another worker unless reassigned.

## Recommended Parallel Workstreams

If we use 4 concurrent Codex threads, split the work like this.

### Thread A — Integrator / App Shell

Owns:

- `jac.toml`
- `main.jac`
- `traceforge/__init__.jac`
- `traceforge/api.jac`
- `README.md`

Tasks:

- scaffold Jac app boot path,
- define public walkers and their signatures,
- wire package imports,
- define startup instructions,
- keep root structure clean.

### Thread B — Data Ingest

Owns:

- `traceforge/ingest.jac`
- `py/parser.py`
- `py/utils.py`
- `demo_runs/README.md`

Tasks:

- implement mini-SWE-agent loader assumptions,
- parse `.traj.json`,
- segment decision steps,
- expose clean ingest outputs for Jac walkers.

### Thread C — Core Analysis

Owns:

- `traceforge/analysis.jac`
- `py/features.py`
- `py/similarity.py`
- `tests/README.md`

Tasks:

- define fingerprints,
- implement failure-family scoring,
- implement similarity functions,
- define clustering and critical-step heuristics.

### Thread D — Schema / LLM / UI Support

Owns:

- `traceforge/schema.jac`
- `traceforge/llm_ops.jac`
- `traceforge/ui.jac`
- `docs/submission/demo_script.md`
- `docs/submission/devpost_outline.md`
- `docs/submission/judging_notes.md`

Tasks:

- define graph schema and typed objects,
- define `by llm()` result contracts,
- scaffold a minimal UI shell,
- keep submission-facing messaging aligned with the build.

## File Ownership Guardrails

To avoid collisions:

- `main.jac` is integrator-only after initial creation.
- `jac.toml` is integrator-only unless dependency changes are explicitly requested.
- `traceforge/schema.jac` is schema-owner only.
- `traceforge/api.jac` is integrator-only.
- `README.md` is integrator-only until late polish.
- `docs/plans/*.md` are planning-owner only.

If a worker needs a new interface:

1. add it in their owned module,
2. document the expected import/call shape in a short note or commit message,
3. let the integrator wire it into `main.jac` or `api.jac`.

## Branch / Worktree Strategy

Use a separate branch or worktree per Codex thread.

Recommended branch names:

- `thread/integrator-shell`
- `thread/ingest`
- `thread/analysis`
- `thread/schema-llm-ui`

Recommended rule:

- each thread merges into the integrator branch only after its owned files are coherent and runnable in isolation.

## Merge Protocol

Every merge cycle should follow this order:

1. worker finishes a small vertical slice in owned files,
2. worker writes a short summary of interfaces added or changed,
3. integrator reads the diff,
4. integrator merges into the main working branch,
5. integrator runs the narrowest useful verification command,
6. only then does the next cross-module wiring happen.

Do not wait for giant feature branches.
Merge small and often.

## First 3 Execution Blocks

These are the concrete startup steps.

### Block 1 — Repo Skeleton

Owner: Integrator

Deliverables:

- create the repo structure above,
- add `jac.toml`,
- add `main.jac`,
- add `traceforge/` package shell,
- add placeholder submission docs,
- add root `README.md`.

Done when:

- `jac start --dev` has a valid entrypoint path,
- the repo tree is understandable to a judge in under 30 seconds,
- and every major folder has a clear purpose.

### Block 2 — Contracts Before Features

Owners: Integrator + Schema + Analysis + Ingest

Deliverables:

- lock node/edge/type names,
- lock public walker names,
- lock parser output shape,
- lock fingerprint field names,
- lock diagnosis object shape.

Done when:

- threads can code in parallel without guessing each other’s interfaces.

### Block 3 — First Runnable Slice

Owners: all threads

Deliverables:

- load one sample batch,
- parse at least one run,
- display or return one run summary,
- stub one diagnosis object,
- show one placeholder cluster or analysis response.

Done when:

- the app proves the architecture is real,
- even if the analysis is still shallow.

## Immediate Priority Order

For the next work session, do this in order:

1. scaffold repo structure and Jac entrypoint,
2. define module ownership,
3. create schema and API contracts,
4. implement parser on one real sample,
5. return one end-to-end run view,
6. then scale to clustering and patch synthesis.

## What Not To Do Yet

Do not spend the first block on:

- fancy UI polish,
- broad benchmark claims,
- multi-format ingestion,
- embeddings or vector DBs,
- export systems,
- or generalized observability features.

The shortest path to a strong JacHacks submission is:

- clean repo,
- clear Jac-native architecture,
- working ingest,
- visible graph reasoning,
- one strong demo flow.

## Acceptance Criteria For This Short-Term Plan

The startup phase is complete when:

- the repo layout is in place,
- thread ownership is explicit,
- no critical file has two simultaneous owners,
- Jac is clearly central in the architecture,
- one runnable app skeleton exists,
- and the next coding wave can proceed in parallel without merge chaos.

## Next Step After This Plan

After this document is in place, the next execution move should be:

1. integrator thread creates the repo skeleton,
2. worker threads start only after file ownership is acknowledged,
3. each thread stays inside its write zone,
4. integrator merges the first round before any shared-file expansion.

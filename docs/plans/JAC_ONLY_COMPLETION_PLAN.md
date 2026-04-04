# TraceForge Jac-Only Completion Plan

## Purpose

This is the active execution plan for completing TraceForge from the current scaffold to a JacHacks-ready submission.

It does four things at once:

1. keeps the project aligned with the locked scope in [LONG_TERM_PLAN.md](/home/gb10/Projects/JacHacks/LONG_TERM_PLAN.md),
2. forces the runtime architecture to become Jac-only,
3. keeps the repo organized enough for public judging,
4. and lets multiple Codex threads work in parallel without overwriting each other.

This document replaces the earlier assumption that Python helpers were acceptable during implementation.

## Non-Negotiables

### Product

- We are building the exact MVP from the long-term brief.
- We do not add side quests before clustering, critical-step localization, typed diagnosis, and `AGENTS.md` patch synthesis work.
- If polish conflicts with shipping the demo path, shipping the demo path wins.

### Architecture

- All application logic must end in `.jac`.
- No runtime `import from py...` is allowed in the final repo.
- Jac remains central for schema, walkers, orchestration, graph traversal, typed `by llm()` calls, and UI.

### Repo Hygiene

- The public repo should read like a real Jac project, not a mixed prototype.
- Every major feature must land behind an executable Jac surface.
- New work must respect file ownership so parallel threads do not fight each other.

## Current State

The repo is useful but not MVP-complete.

### What Exists

- `main.jac`, `jac.toml`, and a runnable Jac shell
- Jac schema in `traceforge/schema.jac`
- public walkers in `traceforge/api.jac`
- starter sample trajectories in `demo_runs/starter_batch/`
- Jac-native sample load, parse, graph compilation, fingerprint, clustering, critical-step, report export, and comparison flows
- planning and submission docs

### What Is Still Wrong

- diagnosis and patch synthesis currently use deterministic scaffolds rather than full typed `by llm()` evidence-pack flows
- the baseline comparison is now wired but still heuristic rather than same-model dual prompting
- the client now loads live starter-batch data, but it is still a raw shell rather than the final polished demo UI

### Progress Against The Long-Term Plan

- Phase 0: done
- Phase 1: done
- Phase 2: done on the starter graph path
- Phase 3: starter-path prototype
- Phase 4: starter-path prototype
- Phase 5: starter-path prototype
- Phase 6: partial
- Phase 7: prototype only
- Phase 8: starter-path shell only
- Phase 9: partial

## Required End State

At submission time, the repo should look conceptually like this:

```text
JacHacks/
  LONG_TERM_PLAN.md
  README.md
  jac.toml
  main.jac
  docs/
    plans/
      SHORT_TERM_PLAN.md
      JAC_ONLY_COMPLETION_PLAN.md
    submission/
      demo_script.md
      devpost_outline.md
      judging_notes.md
  traceforge/
    __init__.jac
    schema.jac
    api.jac
    ingest.jac
    parser.jac
    graph_build.jac
    features.jac
    clustering.jac
    critical.jac
    llm_ops.jac
    reporting.jac
    ui.jac
  demo_runs/
  uploads/
  exports/
  tests/
```

The `py/` directory is not part of the required end state.

## Completion Strategy

Work in phase order. Do not skip a gate that later phases depend on.

### Gate 0 - Repo Stabilization

Goal:
- make the repo predictable for parallel work and normal Git usage

Tasks:
- reconcile local `main` and `origin/main` without rewriting remote history
- confirm branch naming for worker threads
- freeze file ownership rules
- confirm the plan docs are the source of truth

Done when:
- future pushes are normal Git pushes
- everyone knows which files they own
- no one is editing shared entry files casually

### Gate 1 - Jac-Only Migration

Goal:
- remove Python runtime dependencies before deeper feature work continues

Tasks:
- add `traceforge/parser.jac`
- add `traceforge/features.jac`
- add `traceforge/clustering.jac`
- add `traceforge/critical.jac`
- add `traceforge/graph_build.jac`
- port step segmentation from `py/parser.py`
- port fingerprint and summary helpers from `py/features.py`
- port similarity helpers from `py/similarity.py`
- port shared helpers from `py/utils.py`
- rewire `traceforge/ingest.jac` and `traceforge/analysis.jac` to use Jac imports only
- remove `py/` from the runtime path

Verification:
- `rg "import from py" /home/gb10/Projects/JacHacks/traceforge /home/gb10/Projects/JacHacks/main.jac` returns nothing
- `jac check /home/gb10/Projects/JacHacks/main.jac` passes
- sample load, parse, batch overview, and run view still work

Done when:
- the app works without any Python runtime helpers

### Gate 2 - Real Graph Compilation

Goal:
- build the actual graph instead of only returning summaries

Tasks:
- create `Batch`, `Run`, and `Step` nodes from parsed trajectories
- create `FileArtifact`, `Patch`, `TestEvent`, and `ErrorEvent` nodes
- add `HasRun`, `HasStep`, `NextStep`, `TouchesFile`, `ProducesPatch`, `PatchesFile`, `RunsTest`, and `RaisesError` edges
- store fingerprints and digests on `Run`
- persist parsed summaries on nodes so later walkers can traverse graph state instead of reparsing raw files

Verification:
- one sample batch produces a real graph
- `GetRunView` reads graph-backed data
- `GetBatchOverview` reads graph-backed data

Done when:
- the graph is the system of record for analysis

### Gate 3 - Deterministic Failure Analysis

Goal:
- complete the non-LLM analysis core from the long-term brief

Tasks:
- compute the full run fingerprint in Jac
- compute run digests in Jac
- implement failure-family scoring heuristics
- create `FailureHypothesis` nodes
- set `Run.primary_failure`
- expose top files, top errors, top tests, and score summaries

Verification:
- every run gets a top-level failure family
- the starter batch yields plausible family counts
- fingerprints are visible on the run detail surface

Done when:
- deterministic analysis is useful even with no LLM calls

### Gate 4 - Similarity Graph And Clustering

Goal:
- turn families into real, explainable clusters

Tasks:
- compute within-family pairwise similarities in Jac
- create `SimilarRun` edges
- keep top-k neighbors only
- threshold the edge set
- compute connected components
- create `Cluster` nodes
- add `InCluster` edges
- select medoids

Verification:
- starter and larger demo batches show visible clusters
- `GetClusterView` returns real medoid and recurring-signal data

Done when:
- clusters are stable enough for the demo narrative

### Gate 5 - Critical-Step Localization

Goal:
- find the likely first irreversible mistake in each failed run

Tasks:
- generate candidate steps
- compute critical-step scores
- choose `Run.critical_step_idx`
- store evidence windows
- surface the highlighted step and neighboring evidence in the run view

Verification:
- failed runs stop showing `-1` as the critical step
- the highlighted step is explainable from visible evidence

Done when:
- the run detail view can support the postmortem story

### Gate 6 - Typed LLM Reasoning

Goal:
- use `by llm()` only on compact evidence packs

Tasks:
- build run evidence packs in Jac
- implement typed run diagnosis
- implement typed cluster label generation
- implement typed memory patch synthesis
- cache outputs so the demo is stable

Verification:
- `DiagnoseRun` returns a structured diagnosis
- `DiagnoseCluster` returns a real label and summary
- `CompileMemoryPatch` returns a coherent cluster-level patch

Done when:
- the model is validating and synthesizing, not doing the whole pipeline

### Gate 7 - Baseline Comparison

Goal:
- implement the strongest demo comparison from the long-term brief

Tasks:
- build raw compressed baseline inputs
- build structured evidence-pack inputs
- run the same model in both conditions
- store side-by-side outputs
- render the comparison cleanly

Verification:
- at least one run shows a clear raw-vs-structured contrast

Done when:
- the value of the graph and retrieval layer is obvious in one screen

### Gate 8 - Demo UI

Goal:
- implement the actual demo surfaces and not just backend responses

Tasks:
- batch overview screen
- cluster explorer screen
- run detail screen
- baseline comparison screen
- patch display and copy/export surface

Verification:
- the app alone can support the full 3-minute walkthrough

Done when:
- the demo can be recorded without switching tools

### Gate 9 - Submission Polish

Goal:
- finish the public submission package

Tasks:
- tighten `README.md`
- update Devpost copy and judging notes
- add report export
- capture screenshots
- remove placeholders and dead code
- verify the repo tells a coherent Jac-first story

Verification:
- the repo, app, README, demo script, and video all agree on what the product is

Done when:
- the project is clean enough to judge quickly

## Parallel Thread Structure

Use one integrator thread and three worker threads.

Do not let two threads edit the same module family at the same time.

### Thread A - Integrator

Owns:

- `main.jac`
- `jac.toml`
- `traceforge/__init__.jac`
- `traceforge/api.jac`
- `README.md`
- `docs/plans/*.md`

Responsibilities:

- repo reconciliation
- import wiring
- walker signatures
- module naming and file structure
- merge integration
- removal of obsolete files after Jac migration

### Thread B - Parser And Graph Builder

Owns:

- `traceforge/ingest.jac`
- `traceforge/parser.jac`
- `traceforge/graph_build.jac`

Responsibilities:

- Jac-native parsing
- step segmentation
- artifact extraction primitives
- graph node creation
- graph edge creation

### Thread C - Deterministic Analysis

Owns:

- `traceforge/features.jac`
- `traceforge/clustering.jac`
- `traceforge/critical.jac`
- `tests/`

Responsibilities:

- fingerprints
- failure-family heuristics
- similarity scoring
- cluster formation
- medoid selection
- critical-step scoring

### Thread D - LLM, UI, And Reporting

Owns:

- `traceforge/llm_ops.jac`
- `traceforge/reporting.jac`
- `traceforge/ui.jac`
- `docs/submission/`

Responsibilities:

- typed evidence packs
- diagnosis
- cluster labels
- memory patch synthesis
- baseline comparison presentation
- export/report flow

## Non-Overwrite Rules

- Only Thread A edits `main.jac`.
- Only Thread A edits `traceforge/api.jac`.
- Only the owner thread edits a module family unless the work is handed off explicitly.
- No thread adds new Python runtime logic.
- No thread changes schema names casually once Gate 1 starts.
- Shared contracts must be discussed in docs before code lands if more than one thread depends on them.

## Merge Protocol

### Branch Naming

- `main` for the integration branch only
- `codex/integrator-*` for Thread A
- `codex/parser-*` for Thread B
- `codex/analysis-*` for Thread C
- `codex/llm-ui-*` for Thread D

### Merge Order

1. schema and module contracts
2. Jac-only parser and graph build
3. deterministic analysis
4. clustering and critical-step logic
5. typed LLM and patch synthesis
6. UI wiring and polish

### Safe Merge Rules

- merge small vertical slices, not giant rebases
- do not refactor another thread's module as a side effect
- if a contract changes, Thread A updates the shared import and walker surface after the owning thread lands
- delete `py/` only after all importing modules have been converted and verified

## Immediate Work Plan

These are the next moves in order.

### Block 1

- reconcile local and remote `main`
- protect the current scaffold from accidental overlap
- create the missing Jac module files with stubbed exports

### Block 2

- port parsing and feature logic from `py/` into Jac
- rewire `traceforge/ingest.jac` and `traceforge/analysis.jac`
- verify that the current sample flows still work

### Block 3

- build graph compilation on top of the new Jac parser
- persist graph-backed batch and run views
- stop relying on raw-file recomputation for every read

### Block 4

- implement failure scoring, clustering, medoid selection, and critical-step localization
- make cluster and run views real

### Block 5

- implement typed `by llm()` diagnosis, labels, and patch synthesis
- add baseline comparison
- finish the demo UI

### Block 6

- clean the repo
- tighten README and submission docs
- record the demo on the stable path only

## Verification Checklist

The plan is only complete when all of the following are true:

- `rg "import from py" /home/gb10/Projects/JacHacks/traceforge /home/gb10/Projects/JacHacks/main.jac` returns nothing
- `py/` is removed from the runtime path
- `jac check /home/gb10/Projects/JacHacks/main.jac` passes
- `jac start /home/gb10/Projects/JacHacks/main.jac --no_client` runs
- sample batch load works
- sample batch analysis works
- clusters are visible
- failed runs show critical steps
- typed diagnoses work
- cluster-level `AGENTS.md` patches work
- baseline comparison works
- the UI can carry the full demo

## Practical Guardrail

If a choice is ambiguous, choose the version that:

- keeps Jac central,
- reduces token-heavy LLM dependency,
- makes the demo clearer,
- reduces file collisions between threads,
- and removes Python rather than expanding it.

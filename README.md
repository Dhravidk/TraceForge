# TraceForge

TraceForge is a Jac-native batch failure compiler for coding-agent trajectories.
It ingests mini-SWE-agent `*.traj.json` files, compiles them into a graph, groups recurring failure motifs, localizes likely critical steps, and synthesizes reusable memory updates such as `AGENTS.md` patches.

## Why This Exists

Coding-agent trajectories are long, repetitive, and difficult to compare at batch scale.
TraceForge is meant to turn those runs into something judges and users can inspect quickly:

- failure families,
- representative clusters,
- critical-step evidence,
- and reusable operational memory rules.

## Current Status

This repo currently contains the Phase 0 scaffold:

- Jac-first module structure
- public walker placeholders
- graph schema and typed diagnosis scaffolding
- minimal client app shell
- planning and submission docs

The parsing, clustering, and patch synthesis logic are still in progress.

## Repo Layout

```text
.
├── LONG_TERM_PLAN.md
├── README.md
├── jac.toml
├── main.jac
├── docs/
│   ├── plans/
│   └── submission/
├── traceforge/
│   ├── __init__.jac
│   ├── schema.jac
│   ├── ingest.jac
│   ├── analysis.jac
│   ├── llm_ops.jac
│   ├── api.jac
│   └── ui.jac
├── py/
├── demo_runs/
├── uploads/
├── exports/
└── tests/
```

## Why Jac

Jac is central to the design:

- graph-native schema for runs, steps, files, patches, tests, and clusters
- walkers as the public API surface and orchestration layer
- typed `by llm()` outputs for diagnoses and memory patches
- a local full-stack path with a small demo UI

This is important for JacHacks because meaningful Jac usage is part of the judging criteria.

## Planned Demo Flow

1. Load a sample batch of mini-SWE-agent trajectories.
2. Parse runs into structured steps and artifacts.
3. Compute failure-family signals and cluster similar failures.
4. Open one representative run and highlight a critical step.
5. Show a typed diagnosis and a generated `AGENTS.md` patch.
6. Compare raw-baseline analysis versus structured analysis.

## Local Run

The intended local startup command is:

```bash
jac start --dev
```

This environment does not currently have the Jac CLI installed, so the scaffold has been created without runtime verification.

Expected project settings are in [jac.toml](/home/gb10/Projects/JacHacks/jac.toml).

## Planning Docs

- Long-term architecture brief: [LONG_TERM_PLAN.md](/home/gb10/Projects/JacHacks/LONG_TERM_PLAN.md)
- Short-term execution plan: [SHORT_TERM_PLAN.md](/home/gb10/Projects/JacHacks/docs/plans/SHORT_TERM_PLAN.md)

## Submission Notes

The JacHacks site and participant guide emphasize:

- meaningful Jac integration,
- a working demo,
- technical depth,
- real-world impact,
- and a clear 3-minute presentation.

Relevant docs are kept under [docs/submission](/home/gb10/Projects/JacHacks/docs/submission).


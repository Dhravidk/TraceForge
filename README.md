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

This repo is now past the initial scaffold and running a graph-backed Jac demo path for the starter sample batch.

- Jac-native parsing for mini-SWE-agent sample trajectories
- Jac-native deterministic fingerprints and failure-family scoring
- graph compilation into `Batch`, `Run`, `Step`, artifact, hypothesis, and cluster nodes
- graph-backed batch, run, cluster, diagnosis, patch, comparison, and report walkers
- Jac smoke tests for the starter demo path
- a readable demo UI that loads live data from the starter batch

The remaining major work is deeper typed `by llm()` synthesis, stronger baseline comparison, and polishing the current demo UI into the final JacHacks presentation surface.

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
│   ├── parser.jac
│   ├── features.jac
│   ├── clustering.jac
│   ├── critical.jac
│   ├── graph_build.jac
│   ├── analysis.jac
│   ├── llm_ops.jac
│   ├── reporting.jac
│   ├── api.jac
│   └── ui.jac
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

Verified locally:

```bash
jac check main.jac
jac test tests/smoke.jac
jac enter main.jac AnalyzeBatch sample-starter
jac enter main.jac LoadSampleBatch starter
jac enter main.jac GetBatchOverview sample-starter
jac enter main.jac GetRunView premature_completion
jac enter main.jac GetClusterView sample-starter:premature_completion:0
jac enter main.jac CompileMemoryPatch sample-starter:premature_completion:0
jac enter main.jac CompareBaseline premature_completion
jac enter main.jac ExportBatchReport sample-starter
```

Expected project settings are in [jac.toml](/home/gb10/Projects/JacHacks/jac.toml).

## Planning Docs

- Long-term architecture brief: [LONG_TERM_PLAN.md](/home/gb10/Projects/JacHacks/LONG_TERM_PLAN.md)
- Short-term execution plan: [SHORT_TERM_PLAN.md](/home/gb10/Projects/JacHacks/docs/plans/SHORT_TERM_PLAN.md)
- Jac-only completion plan: [JAC_ONLY_COMPLETION_PLAN.md](/home/gb10/Projects/JacHacks/docs/plans/JAC_ONLY_COMPLETION_PLAN.md)

## Submission Notes

The JacHacks site and participant guide emphasize:

- meaningful Jac integration,
- a working demo,
- technical depth,
- real-world impact,
- and a clear 3-minute presentation.

Relevant docs are kept under [docs/submission](/home/gb10/Projects/JacHacks/docs/submission).

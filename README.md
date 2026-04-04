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

This repo is now running a submission-ready Jac demo path for sample and local upload batches.

- Jac-native parsing for mini-SWE-agent sample trajectories
- Jac-native deterministic fingerprints and failure-family scoring
- graph compilation into `Batch`, `Run`, `Step`, artifact, hypothesis, and cluster nodes
- graph-backed batch, run, cluster, diagnosis, patch, comparison, and report walkers
- discovered batch catalog with switching between sample and local upload batches
- local upload support for both folders and zip archives containing `*.traj.json`
- credential-gated typed `by llm()` reasoning with deterministic fallback when no model key is present
- Jac smoke tests for the starter demo path
- a readable demo UI organized around batch overview, cluster explorer, run forensics, and baseline comparison
- live cluster diagnosis and batch-report export surfaced directly in the Jac UI
- stronger baseline-vs-structured comparison with explicit blind spots, support points, and evidence-window grounding
- markdown batch report export that doubles as a demo and Devpost backup artifact

The remaining major work is deeper typed `by llm()` synthesis and any last-mile demo recording polish. The current repo already supports the full judge-facing path: batch overview, cluster explorer, run forensics, baseline comparison, cluster diagnosis, and markdown report export.

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
2. Show failure families, top files, top errors, and cluster counts.
3. Open one representative cluster and inspect recurring signals plus the generated `AGENTS.md` patch.
4. Open one representative run and highlight the likely critical step.
5. Show run diagnosis and cluster diagnosis.
6. Compare raw-baseline analysis versus structured analysis.
7. Export the markdown batch report as a demo fallback artifact.

## Local Run

The intended local startup command is:

```bash
jac start --dev
```

Verified locally:

```bash
jac check main.jac
jac test tests/smoke.jac
jac enter main.jac GetBatchCatalog
jac enter main.jac UploadBatch local_demo_batch
jac enter main.jac UploadBatch local_zip_demo.zip
jac enter main.jac ParseBatch upload-local_demo
jac enter main.jac AnalyzeBatch upload-local_demo
jac enter main.jac GetRunView premature_completion --batch_id upload-local_demo
jac enter main.jac AnalyzeBatch sample-starter
jac enter main.jac LoadSampleBatch starter
jac enter main.jac GetBatchOverview sample-starter
jac enter main.jac GetRunView premature_completion
jac enter main.jac GetClusterView sample-starter:premature_completion:0
jac enter main.jac CompileMemoryPatch sample-starter:premature_completion:0
jac enter main.jac CompareBaseline premature_completion
jac enter main.jac ExportBatchReport sample-starter
```

Local upload batches are discovered from folders under [uploads](/home/gb10/Projects/JacHacks/uploads) that contain `*.traj.json` files, or from zip archives that get extracted into a top-level upload batch directory. The repo includes [local_demo_batch](/home/gb10/Projects/JacHacks/uploads/local_demo_batch) as a fixture for the folder path, and the smoke suite generates a zip fixture at runtime for the archive path.
The demo UI now exposes a batch catalog so sample and upload batches can be browsed without changing commands.

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

Recommended judge path:

1. Start the app and open the starter batch.
2. Show the failure-family overview and top recurring artifacts.
3. Open the first cluster and read one recurring signal plus the generated patch.
4. Open the medoid run and point to the highlighted critical-step window.
5. Compare the raw baseline against the structured diagnosis.
6. Export the batch report and show the generated markdown path as the backup artifact.

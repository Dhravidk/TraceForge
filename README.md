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
- external folder uploads now get managed aliases under `uploads/` so they can be analyzed through the normal batch flow
- credential-gated typed `by llm()` reasoning with deterministic fallback when no model key is present
- Jac smoke tests for the starter demo path
- a readable demo UI organized around batch overview, cluster explorer, run forensics, and baseline comparison
- live cluster diagnosis and batch-report export surfaced directly in the Jac UI
- fair same-schema raw-transcript-vs-TraceForge comparison with explicit blind spots, support points, verifier output, and evidence-window grounding
- blinded evaluation export for side-by-side judging of raw transcript analysis versus TraceForge retrieval
- gold annotation template export for a manually labeled evaluation subset
- rigorous batch evaluation export with provider-aware Anthropic/OpenAI API support and gold-score uplift summaries
- markdown batch report export that doubles as a demo and Devpost backup artifact

The remaining major work is deeper typed `by llm()` synthesis and any last-mile demo recording polish. The current repo already supports the full judge-facing path: batch overview, cluster explorer, run forensics, fair baseline comparison, blinded evaluation export, gold annotation template export, rigorous uplift scoring, cluster diagnosis, and markdown report export.

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
│   ├── eval.jac
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
6. Compare a raw-transcript diagnosis versus TraceForge retrieval under the same output schema.
7. Export the blinded evaluation sheet and markdown batch report as demo fallback artifacts.

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
jac enter main.jac ExportBlindedEvaluation sample-starter --limit 2
jac enter main.jac ExportGoldAnnotationTemplate sample-starter --substantive_limit 2 --startup_limit 0
jac enter main.jac RunRigorousEvaluation sample-starter --substantive_limit 2 --startup_limit 0
jac enter main.jac ExportBatchReport sample-starter
```

If you want model-backed evaluation instead of deterministic fallback, set one provider key plus a model name before running the eval walkers:

```bash
export OPENAI_API_KEY=...
export TRACEFORGE_OPENAI_MODEL=gpt-5.4

# or

export ANTHROPIC_API_KEY=...
export TRACEFORGE_ANTHROPIC_MODEL=claude-sonnet-4-20250514
```

For a local Codex CLI preliminary evaluation that uses the machine's logged-in Codex account instead of API keys:

```bash
export TRACEFORGE_CODEX_MODEL=gpt-5.4
```

Then run the same walkers with an explicit provider if you want to lock the evaluation:

```bash
jac enter main.jac CompareBaseline premature_completion --batch_id sample-starter --provider openai
jac enter main.jac ExportBlindedEvaluation sample-starter --limit 10 --provider anthropic
jac enter main.jac RunRigorousEvaluation sample-starter --provider openai --substantive_limit 20 --startup_limit 5
jac enter main.jac CompareBaseline premature_completion sample-starter codex
jac enter main.jac RunRigorousEvaluation sample-starter codex gpt-5.4 20 5 exports/evals/sample-starter_gold_template.json
```

Explicit provider runs now namespace their eval artifacts so deterministic, API, and Codex outputs can coexist. For example, a Codex run writes files such as `sample-starter_codex_gpt_5_4_comparison.json` instead of overwriting `sample-starter_comparison.json`.

After exporting the gold worksheet and filling it in, score the evaluation against the labeled subset:

```bash
jac enter main.jac ScoreRigorousEvaluation \
  --comparison_json_path exports/evals/sample-starter_comparison.json \
  --annotation_path exports/evals/sample-starter_gold_template.json
```

Local upload batches are discovered from folders under [uploads](/home/gb10/Projects/JacHacks/uploads) that contain `*.traj.json` files, or from zip archives that get extracted into a top-level upload batch directory. The repo includes [local_demo_batch](/home/gb10/Projects/JacHacks/uploads/local_demo_batch) as a fixture for the folder path, and the smoke suite generates a zip fixture at runtime for the archive path.
If you point `UploadBatch` at an external folder outside `uploads/`, TraceForge now creates a managed alias under `uploads/` so later `ParseBatch`, `AnalyzeBatch`, and `GetRunView` calls work through a stable upload batch ID.
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
5. Compare the raw transcript arm against the TraceForge retrieval arm and read the verifier verdict.
6. Export the blinded eval sheet and batch report and show the generated markdown paths as backup artifacts.

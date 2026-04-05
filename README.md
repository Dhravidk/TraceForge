# TraceForge

TraceForge is a Jac-native batch failure compiler for coding-agent trajectories.
It ingests mini-SWE-agent `*.traj.json` files, compiles them into a graph, groups recurring failure motifs, localizes likely critical steps, and synthesizes reusable memory updates such as `AGENTS.md` patches.

TraceForge is now being shaped primarily as a **CLI-first tool for Codex CLI and Claude Code workflows**.
The core job is not to replace those coding agents. The core job is to give them better structured evidence than a raw trajectory dump.

## Why This Exists

Coding-agent trajectories are long, repetitive, and difficult to compare at batch scale.
TraceForge is meant to turn those runs into something judges and users can inspect quickly:

- failure families,
- representative clusters,
- critical-step evidence,
- and reusable operational memory rules.

The most important product loop is:

1. generate a `raw` evidence pack
2. generate a `structured` TraceForge evidence pack
3. let Codex or Claude Code analyze the difference

The thesis is:

> same failed run, same outer model, better evidence pack

## GitHub Handoff

If another coding agent should operate this repo from the GitHub URL alone, point it at:

- the repo URL: `https://github.com/Dhravidk/TraceForge`
- [AGENTS.md](/home/gb10/Projects/JacHacks/AGENTS.md)
- [quickstart.md](/home/gb10/Projects/JacHacks/docs/cli/quickstart.md)
- [repo_handoff_prompts.md](/home/gb10/Projects/JacHacks/docs/cli/repo_handoff_prompts.md)

The intended fresh-clone path is:

```bash
git clone https://github.com/Dhravidk/TraceForge.git
cd TraceForge
./scripts/bootstrap
source .venv/bin/activate
traceforge doctor
```

## CLI Quickstart

From a fresh clone:

```bash
git clone https://github.com/Dhravidk/TraceForge.git
cd TraceForge
./scripts/bootstrap
source .venv/bin/activate
```

Then run TraceForge from the repo root:

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode raw
traceforge pack --batch sample-starter --run premature_completion --mode structured
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

For automation-friendly output, add `--json`.

Provider resolution follows one rule across the CLI:
- explicit `--provider` wins
- otherwise a saved preference from `traceforge auth use` wins
- otherwise logged-in Codex is preferred
- otherwise API-key-backed OpenAI or Anthropic is used if configured

To save a pack artifact for downstream use:

```bash
traceforge pack --batch sample-starter --run premature_completion --mode structured --save
```

To save a compare artifact for downstream use:

```bash
traceforge compare --batch sample-starter --run premature_completion --save
```

To generate the whole sample demo bundle in one command:

```bash
traceforge demo --batch sample-starter --run premature_completion
```

To analyze your own trajectories instead of the sample batch:

```bash
traceforge analyze-batch --input /path/to/my_batch
traceforge overview --batch upload-my_batch
traceforge run --batch upload-my_batch --run my_run_id
traceforge pack --batch upload-my_batch --run my_run_id --mode structured
```

The detailed terminal-first guides are:

- [AGENTS.md](/home/gb10/Projects/JacHacks/AGENTS.md)
- [quickstart.md](/home/gb10/Projects/JacHacks/docs/cli/quickstart.md)
- [provider_setup.md](/home/gb10/Projects/JacHacks/docs/cli/provider_setup.md)
- [agent_workflows.md](/home/gb10/Projects/JacHacks/docs/cli/agent_workflows.md)
- [command_reference.md](/home/gb10/Projects/JacHacks/docs/cli/command_reference.md)
- [demo_playbook.md](/home/gb10/Projects/JacHacks/docs/cli/demo_playbook.md)
- [output_schema.md](/home/gb10/Projects/JacHacks/docs/cli/output_schema.md)
- [repo_handoff_prompts.md](/home/gb10/Projects/JacHacks/docs/cli/repo_handoff_prompts.md)
- [troubleshooting.md](/home/gb10/Projects/JacHacks/docs/cli/troubleshooting.md)

## Current Status

This repo now supports a CLI-first Jac demo path for sample and local upload batches.

- Jac-native parsing for mini-SWE-agent sample trajectories
- Jac-native deterministic fingerprints and failure-family scoring
- graph compilation into `Batch`, `Run`, `Step`, artifact, hypothesis, and cluster nodes
- graph-backed batch, run, cluster, diagnosis, patch, comparison, and report walkers
- discovered batch catalog with switching between sample and local upload batches
- local upload support for both folders and zip archives containing `*.traj.json`
- external folder uploads now get managed aliases under `uploads/` so they can be analyzed through the normal batch flow
- credential-gated typed `by llm()` reasoning with deterministic fallback when no model key is present
- Jac smoke tests for the starter demo path
- a public `traceforge` CLI wrapper for doctor, run, pack, compare, and export flows
- pack-first analysis for raw versus structured evidence on the same failed run
- fair same-schema raw-transcript-vs-TraceForge comparison with explicit blind spots, support points, verifier output, and evidence-window grounding
- blinded evaluation export for side-by-side judging of raw transcript analysis versus TraceForge retrieval
- gold annotation template export for a manually labeled evaluation subset
- rigorous batch evaluation export with provider-aware Anthropic/OpenAI API support and gold-score uplift summaries
- markdown batch report export that doubles as a demo and Devpost backup artifact

The remaining major work is deeper typed `by llm()` synthesis, final CLI polish, and last-mile demo recording polish. The current repo already supports the judge-facing CLI path: run inspection, raw-versus-structured pack generation, provider-aware comparison, blinded evaluation export, gold annotation export, rigorous uplift scoring, and markdown report export.

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
- a CLI-first operator path with an optional appendix UI

This is important for JacHacks because meaningful Jac usage is part of the judging criteria.

## Planned Demo Flow

1. Run `traceforge doctor`.
2. Analyze the sample batch.
3. Open one failed run in the terminal.
4. Show the `raw` pack.
5. Show the `structured` pack.
6. Explain that the outer model is the same and the evidence pack is better.
7. If provider access is healthy, run strict compare.
8. End on the markdown report as a fallback artifact.

## Local Run

The preferred product path is now the CLI:

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode structured
```

After a fresh clone:

```bash
./scripts/bootstrap
source .venv/bin/activate
```

Core CLI examples:

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter
traceforge overview --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge cluster --cluster sample-starter:premature_completion:0
traceforge pack --batch sample-starter --run premature_completion --mode raw
traceforge pack --batch sample-starter --run premature_completion --mode structured
traceforge compare --batch sample-starter --run premature_completion --strict-provider
traceforge export-report --batch sample-starter
traceforge export-eval --batch sample-starter --kind blind
```

Provider-backed examples:

```bash
traceforge auth use codex --model gpt-5.4
traceforge compare --batch sample-starter --run premature_completion --strict-provider

traceforge auth use openai --model gpt-5.4 --openai-api-key "$OPENAI_API_KEY"
traceforge compare --batch sample-starter --run invalid_patch --provider openai --strict-provider

traceforge auth use anthropic --model claude-sonnet-4-20250514 --anthropic-api-key "$ANTHROPIC_API_KEY"
traceforge compare --batch sample-starter --run invalid_patch --provider anthropic --strict-provider
```

Explicit provider runs now namespace their eval artifacts so deterministic, API, and Codex outputs can coexist. For example, a Codex run writes files such as `sample-starter_codex_gpt_5_4_comparison.json` instead of overwriting `sample-starter_comparison.json`.

## Internal Jac Appendix

Developer-only Jac entrypoints still exist underneath the wrapper, but they are now the internal API layer rather than the recommended operator interface.

After exporting the gold worksheet and filling it in, the supported operator path for rigorous scoring is the CLI:

```bash
traceforge export-eval \
  --batch sample-starter \
  --kind rigorous \
  --provider openai \
  --annotation-path exports/evals/sample-starter_gold_template.json
```

The lower-level scoring helper still lives in [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac), but it is not exposed as a public CLI subcommand beyond `export-eval --kind rigorous`.

Local upload batches are discovered from folders under [uploads](/home/gb10/Projects/JacHacks/uploads) that contain `*.traj.json` files, or from zip archives that get extracted into a top-level upload batch directory. The repo includes [local_demo_batch](/home/gb10/Projects/JacHacks/uploads/local_demo_batch) as a fixture for the folder path, and the smoke suite generates a zip fixture at runtime for the archive path.
If you point `UploadBatch` at an external folder outside `uploads/`, TraceForge now creates a managed alias under `uploads/` so later `ParseBatch`, `AnalyzeBatch`, and `GetRunView` calls work through a stable upload batch ID.

Expected project settings are in [jac.toml](/home/gb10/Projects/JacHacks/jac.toml).

## Optional UI Appendix

The UI is intentionally secondary to the CLI product.
Use it only when you explicitly want a visual appendix or a backup demo surface.

Start it with:

```bash
jac start --dev
```

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

1. Start in the terminal, not the UI.
2. Show `doctor`.
3. Show one failed run.
4. Show `raw` versus `structured` evidence packs.
5. If available, run strict provider compare.
6. End on exported markdown artifacts as backup.

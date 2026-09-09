# TraceForge

**Turn coding-agent trajectories into inspectable evidence.**

TraceForge is a Jac-native, CLI-first failure-analysis tool for mini-SWE-agent runs. It compiles trajectory files into a graph, groups recurring failure patterns, retrieves critical observations, and exports evidence packs for human reviewers, Codex CLI, and Claude Code.

[Quickstart](docs/cli/quickstart.md) · [Command reference](docs/cli/command_reference.md) · [Validation notes](docs/cli/validation_notes.md) · [Architecture](traceforge/schema.jac)

## What it does

| Input | Processing | Output |
| --- | --- | --- |
| `*.traj.json` files or a batch folder/zip | Parse turns, tool calls, observations, exit status, and model statistics | Searchable runs and steps |
| A compiled batch | Graph-backed fingerprints, clusters, and critical-step retrieval | Failure families with supporting observations |
| The same failed run | Raw transcript and structured evidence-pack generation | Comparable review inputs |
| Reviewed run evidence | Provider-backed or explicitly identified deterministic analysis | Diagnoses, blinded evaluation exports, reports, and memory-rule proposals |

The central experiment is to hold the failed run and outer model fixed while changing the evidence representation. Improved analysis is a hypothesis to evaluate; producing a structured pack alone does not establish an accuracy gain.

## Try the sample

```bash
git clone https://github.com/Dhravidk/TraceForge.git
cd TraceForge
./scripts/bootstrap
source .venv/bin/activate
traceforge doctor
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode raw
traceforge pack --batch sample-starter --run premature_completion --mode structured
```

The checked-in sample is a small smoke-test fixture. Add `--json` for machine-readable output or `--save` to a pack command to retain an artifact. If the package entrypoint is not installed, use `./scripts/traceforge` from the repository root.

## Inspect your own runs

```bash
traceforge analyze-batch --input /path/to/my_batch
traceforge overview --batch upload-my_batch
traceforge run --batch upload-my_batch --run my_run_id
traceforge pack --batch upload-my_batch --run my_run_id --mode structured --save
```

Use the batch identifier returned by ingestion. See the [output schema](docs/cli/output_schema.md) for downstream tooling and the [agent workflows](docs/cli/agent_workflows.md) guide for using packs inside another coding agent.

## Compare evidence with a model

Check provider readiness before requesting a live comparison:

```bash
traceforge doctor
traceforge auth status
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

Strict mode makes provider unavailability explicit. Without strict mode, deterministic fallback may be used; that output must not be described as a live model comparison. Provider configuration and resolution order are documented in [provider setup](docs/cli/provider_setup.md). A provider-backed operation can use the configured provider's paid service.

For an inspectable offline fallback, save raw and structured packs and export the report:

```bash
traceforge pack --batch sample-starter --run invalid_patch --mode raw --save
traceforge pack --batch sample-starter --run invalid_patch --mode structured --save
traceforge export-report --batch sample-starter
```

## Architecture

- **Jac graph model:** batches, runs, steps, artifacts, hypotheses, and clusters in [schema.jac](traceforge/schema.jac).
- **Ingestion and compilation:** trajectory parsing, deterministic fingerprints, and graph construction in `traceforge/`.
- **Evidence retrieval:** run, cluster, diagnosis, patch, comparison, and report walkers.
- **Typed reasoning:** credential-gated `by llm()` operations with identified deterministic fallback.
- **Operator interface:** a Python CLI wrapper over the Jac implementation; the optional UI is secondary.

## What has been validated

The repository's [validation notes](docs/cli/validation_notes.md) document an external 100-trajectory batch: 47 submissions, 38 process errors, 13 limit exits, and 2 retry errors. Those are recorded exit-status categories, **not task-success scores**. The exercise demonstrated ingestion, batch inspection, and useful separation of infrastructure, budget, and provider failures.

The tiny checked-in sample supports smoke tests and demo rehearsal. The external batch report is operational evidence; it does not establish benchmark uplift, optimal clustering, or production readiness. Fully inspectable efficacy evidence remains a separate requirement.

## Navigate the repository

| Location | Purpose |
| --- | --- |
| `traceforge/` | Jac schemas, parsing, graph operations, analysis, and reporting |
| `scripts/` | Bootstrap and CLI entrypoint |
| `demo_runs/` | Starter trajectories |
| `uploads/` | Managed local input batches |
| `exports/` | Generated evidence, evaluation, and report artifacts |
| `tests/` | Implementation and smoke checks |
| `docs/cli/` | Current operator documentation |
| `docs/plans/` | Historical design context |

For a reproducible handoff, start with [AGENTS.md](AGENTS.md), the [quickstart](docs/cli/quickstart.md), and [repository handoff prompts](docs/cli/repo_handoff_prompts.md). Troubleshooting and demo guidance are in [troubleshooting](docs/cli/troubleshooting.md) and the [demo playbook](docs/cli/demo_playbook.md).

# Validation Notes

This repo ships a very small checked-in starter fixture for smoke tests and deterministic demo rehearsal. That starter batch is not the strongest evidence for real-batch usefulness.

The stronger validation story so far is an external CLI run against a 100-trajectory mini-SWE-agent batch from:

`Agent-X/v2/runs_iclr/iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417`

## Observed external run

The observed operator flow was:

```bash
traceforge analyze-batch --input /path/to/iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417
traceforge overview --batch upload-trajectories
traceforge cluster --cluster upload-trajectories:tool_misuse:0
traceforge run --batch upload-trajectories --run django__django-12184
traceforge pack --batch upload-trajectories --run django__django-12184 --mode structured --save
```

## Observed batch-level results

Across all 100 `*.traj.json` files in that run directory, the observed exit-status breakdown was:

- `Submitted`: `47`
- `CalledProcessError`: `38`
- `LimitsExceeded`: `13`
- `RetryError`: `2`

The important operational takeaway was that the tool did not just ingest the batch. It separated materially different failure surfaces:

- zero-turn container/bootstrap failures
- long-running budget or step-limit failures
- provider/network retry failures
- successful submissions

## What the analysis surfaced

The observed analysis sessions consistently found:

- `CalledProcessError` runs had `messages=[]` and failed before any agent loop, indicating container/bootstrap infrastructure failure rather than reasoning failure
- `LimitsExceeded` runs showed long histories and hard budget ceilings, indicating budget/step limits rather than a single localized patch bug
- `RetryError` runs were network/provider failures, not code-under-test regressions

That is a useful batch-forensics outcome: it helps an operator distinguish infra failures from agent failures before they waste time debugging the wrong thing.

## What this validates

- TraceForge can ingest a materially larger external mini-SWE-agent batch than the checked-in starter fixture
- run-level and cluster-level summaries remain usable on a 100-trajectory batch
- structured packs can still be generated for representative failed runs from a real batch
- the CLI-first workflow is viable outside the toy sample path

## What this does not yet prove

- that the current clustering pipeline is the final form of global motif discovery
- that the current memory patch generation is fully cluster-derived rather than partially template-guided
- that provider-backed uplift evidence is fully check-in ready and inspectable in-repo

So the honest read is:

- starter fixture: smoke/demo proof
- external 100-run batch: real operational validation
- final product-grade evidence: still in progress

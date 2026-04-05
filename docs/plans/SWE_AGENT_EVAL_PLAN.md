# SWE-Agent Evaluation Plan

> Historical planning note: this document captures evaluation planning details. The current public operator interface is the `traceforge` CLI. For install and usage, start with [README.md](/home/gb10/Projects/JacHacks/README.md) and the guides under `docs/cli/`.

## Goal

Test TraceForge on a real batch outside the starter fixtures and evaluate whether the output is:

- ingestible at batch scale,
- internally consistent,
- useful for clustering recurring failure motifs,
- plausible for critical-step localization,
- and better than a raw compressed-log baseline.

## Candidate batch

Source run directory:

`../SWE-Agent/Agent-X/v2/runs_iclr/iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417`

## What is currently on disk

Current observed state in that directory:

- `100` non-empty `*.traj.json` files
- status mix from trajectory metadata:
  - `Submitted`: `47`
  - `LimitsExceeded`: `13`
  - `CalledProcessError`: `38`
  - `RetryError`: `2`
- message-count distribution:
  - minimum: `0`
  - median: `22`
  - maximum: `503`

Important note:

- This does **not** currently match the assumption of `66` non-empty trajectories.
- If `66` is the intended subset, define that subset explicitly before evaluation.

## Current product behavior

TraceForge can now ingest:

- folders under `uploads/`
- zip archives that get extracted into `uploads/`
- arbitrary external folders, which are automatically aliased into `uploads/` for stable reuse

Current managed upload behavior:

- `UploadBatch` on an external directory creates a managed alias under `uploads/`
- later `ParseBatch`, `AnalyzeBatch`, `GetBatchOverview`, and `GetRunView` can use the returned `upload-*` batch ID directly

Observed on the candidate batch:

- `UploadBatch` discovered all `100` non-empty trajectories
- cold `AnalyzeBatch` completed in about `4s` after lazy graph hydration and reduced similarity-edge construction
- `ExportBatchReport` completed in about `6.61s`
- `38` runs have `messages=[]` and `api_calls=0`; these are container-start failures, not parser misses

## Recommended ingestion path

Use either the direct external path or a symlink/local copy under `uploads/`.

Recommended local alias:

`uploads/iclr_pilot100_batch -> ../SWE-Agent/Agent-X/v2/runs_iclr/iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417`

Example setup if you want an explicit alias:

```bash
ln -s ../SWE-Agent/Agent-X/v2/runs_iclr/iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417 uploads/iclr_pilot100_batch
```

Then run:

```bash
.venv/bin/jac enter main.jac UploadBatch iclr_pilot100_batch
.venv/bin/jac enter main.jac ParseBatch upload-iclr_pilot100
.venv/bin/jac enter main.jac AnalyzeBatch upload-iclr_pilot100
.venv/bin/jac enter main.jac GetBatchOverview upload-iclr_pilot100
```

Zip-based fallback:

```bash
cd ../SWE-Agent/Agent-X/v2/runs_iclr
zip -r /home/gb10/Projects/JacHacks/uploads/iclr_pilot100.zip iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417
cd /home/gb10/Projects/JacHacks
.venv/bin/jac enter main.jac UploadBatch iclr_pilot100.zip
```

Direct external-path ingestion also works now:

```bash
.venv/bin/jac enter main.jac UploadBatch ../SWE-Agent/Agent-X/v2/runs_iclr/iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417
```

That currently returns:

- `batch_id=upload-iclr_summary_baseline_pilot100_baseline_w2p300_t5400_r01-20260307-040417`
- `run_count=100`
- `managed_alias_created=True`

## Current observed results

First-pass evaluation on the candidate batch currently yields:

- family counts:
  - `TOOL_MISUSE`: `48`
  - `INVALID_PATCH`: `14`
  - `UNKNOWN`: `38`
- zero-step runs: `38`
- non-zero-step runs: `62`
- cluster count from a fresh graph-backed overview: `4`
  - `INVALID_PATCH`: `14`
  - `TOOL_MISUSE`: `34`
  - `TOOL_MISUSE fallback`: `14`
  - `UNKNOWN`: `38`

Interpretation:

- the `UNKNOWN` family is largely explained by container startup failures with empty message histories
- the real remaining evaluation question is cluster quality on the `62` runs that actually executed agent steps
- fallback clustering is currently used to ensure that every analyzed run lands in a visible cluster, even when the similarity graph leaves a failure-family remainder unassigned

## Test phases

### Phase 1: Ingestion coverage

Goal:

- verify that TraceForge can ingest and parse the full batch without manual file repair

Checks:

- `UploadBatch` returns `status=ready`
- `ParseBatch` returns the expected run count
- `AnalyzeBatch` completes without crashing
- `GetBatchOverview` returns a non-empty overview

Success criteria:

- parsed run count matches on-disk non-empty trajectory count
- no parser crashes
- batch overview is produced in one pass

## Phase 2: Structural sanity

Goal:

- confirm that the graph-backed summary is internally coherent

Checks:

- `family_counts` sum to total run count
- cluster count is non-zero
- representative runs exist for non-empty clusters
- every sampled failed run has a timeline and fingerprint
- every sampled failed run has either a localized critical step or an explicit reason it could not be localized

Success criteria:

- family-count sum equals run count
- at least `3` multi-run clusters exist
- at least `85%` of non-trivial failed runs receive a critical-step index

## Phase 3: Status-family sanity

Goal:

- check whether TraceForge’s failure families roughly align with obvious run outcomes

Suggested expectations:

- `LimitsExceeded` should often map to:
  - `OSCILLATION_LOOP`
  - `STALE_CONTEXT_OR_BAD_PLAN`
- `CalledProcessError` and `RetryError` should often map to:
  - `TOOL_MISUSE`
  - `INVALID_PATCH`
- `Submitted` should often map to:
  - `PREMATURE_COMPLETION`
  - `WRONG_FILE_FOCUS`
  - `INVALID_PATCH`

This is not a gold-label test. It is a plausibility check.

Success criteria:

- the cross-tab looks explainable rather than random
- there is visible skew by status family rather than a flat distribution

## Phase 4: Weak proxy evaluation

Goal:

- use existing trajectory metadata as a weak correctness signal

Suggested proxy:

- for `Submitted` runs, parse file paths from `info.submission` diffs
- compare those diff paths against:
  - run `top_files`
  - critical-window touched files
  - cluster recurring files

Why this helps:

- it checks whether TraceForge is surfacing files that the agent actually edited in its final submission
- it is not perfect, but it is a real anchor from the source data

Success criteria:

- for a majority of `Submitted` runs, at least one surfaced file overlaps the final diff file set

## Phase 5: Human audit

Goal:

- judge whether the output is useful, not just internally consistent

Audit sample:

- `20` runs total, stratified by status:
  - `8` Submitted
  - `6` CalledProcessError
  - `4` LimitsExceeded
  - `2` RetryError

For each sampled run, score:

- cluster fit:
  - does the assigned cluster actually look like the same motif?
- critical-step plausibility:
  - is the highlighted step a believable first irreversible mistake?
- evidence grounding:
  - does the explanation point to the right local evidence?
- patch usefulness:
  - would the cluster-level `AGENTS.md` rule plausibly reduce recurrence?

Use a simple 0/1 or 1-5 rubric.

Recommended minimum quality bar:

- cluster fit: at least `70%` acceptable
- critical-step plausibility: at least `70%` acceptable
- patch usefulness: at least `60%` acceptable

## Phase 6: Baseline comparison

Goal:

- verify that the structured path is actually better than the raw compressed baseline

Sample:

- `10` runs from the audit sample

For each run, compare:

- raw baseline diagnosis
- structured diagnosis

Judge on:

- specificity
- actionability
- evidence grounding
- whether a concrete pivot step is identified

Count a structured win when it is clearly more specific and better grounded than the raw baseline.

Recommended threshold:

- structured path should win on at least `8/10` audited cases

## What to record

Create one short evaluation note with:

- run count ingested
- family-count table
- cluster count
- status-by-family cross-tab
- number of runs with localized critical steps
- weak proxy file-overlap rate for `Submitted` runs
- baseline win rate on the audit sample
- top 3 strongest clusters
- top 3 weakest or most confusing outputs

## How to interpret results

Good result:

- ingestion succeeds on the full batch
- there are multiple non-trivial clusters
- critical steps are usually localized
- the baseline comparison clearly favors the structured path
- the patches are concrete and operational

Mixed result:

- ingestion succeeds but clusters are mostly singletons
- critical-step localization is inconsistent
- baseline wins are not decisive

Bad result:

- parse coverage is poor
- family assignments look random
- critical steps are mostly missing or obviously wrong
- patches are generic and unsupported

## Recommended immediate next step

Run the full ingestion on a managed alias inside `uploads/`, then generate:

1. `GetBatchOverview`
2. `ExportBatchReport`
3. a small human-audit table for `20` stratified runs

That will tell us quickly whether TraceForge is ready for a real external batch demo or whether we need one more iteration on clustering and localization before relying on it.

# TraceForge Next Steps Completion Plan

## Purpose

This is the active short-horizon completion plan for the remaining high-value work before JacHacks submission.

It is narrower than [LONG_TERM_PLAN.md](/home/gb10/Projects/JacHacks/LONG_TERM_PLAN.md) and more execution-focused than [JAC_ONLY_COMPLETION_PLAN.md](/home/gb10/Projects/JacHacks/docs/plans/JAC_ONLY_COMPLETION_PLAN.md).

Its goal is to turn the current graph-backed demo into a submission-ready Jac app without destabilizing the parts that already work.

## Current Baseline

The repo already has:

- Jac-only parsing, fingerprinting, clustering, and critical-step localization
- graph-backed batch, run, cluster, patch, comparison, and report walkers
- sample and local-upload batch ingestion
- multi-batch demo browsing in the Jac client
- graph persistence for generated memory patches
- smoke coverage for the starter and upload fixture paths

The biggest remaining gaps are:

- real typed `by llm()` reasoning instead of deterministic-only scaffolds
- final UI polish for the JacHacks demo story
- stronger export and submission-facing artifacts

## Execution Order

Work in this order.

### Step 1 - Safe Typed LLM Path

Goal:
- add real typed `by llm()` validation and synthesis without breaking no-credential local runs

Tasks:
- add evidence-pack builders for runs and clusters
- gate all model calls behind `OPENAI_API_KEY`
- keep deterministic fallback as the default when credentials are absent or the model call fails
- expose whether the response was deterministic or LLM-backed

Files:
- `traceforge/llm_ops.jac`
- `tests/smoke.jac`
- `README.md`

Done when:
- no-credential runs still pass smoke tests
- `DiagnoseRun`, `DiagnoseCluster`, and `CompileMemoryPatch` can switch to typed `by llm()` output when credentials exist

### Step 2 - Demo UI Polish

Goal:
- make the client read like a real demo surface rather than a developer dashboard

Tasks:
- tighten layout hierarchy for batch overview, cluster explorer, run detail, and baseline comparison
- make active batch, active cluster, and active run more visually obvious
- reduce dense raw-text blocks where summarized cards would work better
- keep the UI within Jac client code only

Files:
- `traceforge/ui.jac`
- `traceforge/__init__.jac`
- `README.md`

Done when:
- the UI can support the 3-minute script without explaining the interface itself

### Step 3 - Report And Submission Polish

Goal:
- make the exported markdown and repo docs strong enough to serve as demo backup and Devpost support material

Tasks:
- enrich batch report structure
- ensure report includes representative clusters, critical-step evidence, and patch outputs
- tighten README sections to match the actual demo path
- align `docs/submission/` with the implemented product

Files:
- `traceforge/reporting.jac`
- `README.md`
- `docs/submission/demo_script.md`
- `docs/submission/devpost_outline.md`
- `docs/submission/judging_notes.md`

Done when:
- a judge could understand the product path from the repo and the exported markdown alone

## Guardrails

- Do not weaken the deterministic path while adding `by llm()`.
- Do not introduce non-Jac runtime code.
- Do not remove the current upload or multi-batch demo path.
- Prefer small commits that leave the repo runnable after each slice.

## Immediate Priority

The next implementation slice is Step 1.

That is the best tradeoff because it upgrades one of the most visible missing pieces in the long-term plan while preserving the now-stable graph and UI paths.

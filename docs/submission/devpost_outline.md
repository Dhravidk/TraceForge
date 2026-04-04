# Devpost Outline

## Problem

Coding-agent trajectories are long, repetitive, and hard to compare across many runs.

## Solution

TraceForge compiles batches of mini-SWE-agent trajectories into a Jac graph, clusters repeated failure motifs, localizes likely critical steps, and synthesizes reusable memory patches.

## How It Works

1. Ingest a sample or uploaded batch of mini-SWE-agent trajectories.
2. Parse each run into decision steps, artifacts, tests, patches, and errors.
3. Compile those objects into a Jac graph.
4. Score failure families and cluster similar failures.
5. Localize the likely first irreversible step in representative failed runs.
6. Generate cluster-level memory patches such as `AGENTS.md` diffs.
7. Compare a raw compressed baseline against the structured evidence-pack path.

## Why Jac

- graph-native storage for runs, steps, files, and clusters
- walkers as the analysis and API surface
- typed `by llm()` outputs for diagnosis and memory patch synthesis
- local full-stack demo path in one Jac-first repo

## Current build status

- Jac-native parser and fingerprint pipeline for mini-SWE-agent trajectories
- Graph compilation into `Batch`, `Run`, `Step`, artifact, hypothesis, cluster, and memory-patch nodes
- Batch overview, cluster explorer, run forensics, and baseline comparison UI in Jac
- Local upload-batch support alongside sample demo batches
- Zip upload-batch support for local archive ingestion
- Credential-gated typed `by llm()` hooks with deterministic fallback
- Cluster diagnosis surfaced in the Jac UI
- Markdown batch report export for demo and Devpost backup artifacts

## What judges can see immediately

- recurring failure families across a batch
- a representative cluster with recurring signals
- a failed run with a localized critical step
- an `AGENTS.md` patch synthesized from the cluster motif
- a raw-baseline versus structured-analysis comparison
- a markdown batch report export that can stand in for the UI if needed

## What Makes It Different

- It is not a trace viewer; it is a batch failure compiler.
- The LLM path is intentionally constrained to compact evidence packs instead of raw trajectories.
- Cluster-level memory patches turn repeated failures into reusable operational rules.
- Jac is central to the schema, graph traversal, typed outputs, API walkers, and UI.

## Challenges

- Keeping the project Jac-first while still shipping quickly.
- Making clustering and critical-step localization deterministic enough to explain in a 3-minute demo.
- Handling local upload folders and zip archives without turning the project into a generic ingestion platform.

## Accomplishments

- Shipped a Jac-only runtime path for parsing, graph build, clustering, localization, comparison, and export.
- Built a live multi-batch demo surface in Jac.
- Added a reliable markdown fallback artifact for demo and Devpost use.

## What’s Next

- Stronger typed `by llm()` synthesis when credentials are available.
- Broader trajectory-schema support beyond mini-SWE-agent.
- Repeated-batch learning and memory retrieval across historical failure corpora.

# Devpost Outline

## Problem

Coding-agent trajectories are long, repetitive, and hard to analyze once a coding agent fails. Developers already work inside tools like Codex CLI and Claude Code, but those tools still have to reason over noisy raw traces.

## Solution

TraceForge is a CLI-first trajectory compiler for AI coding workflows. It compiles batches of mini-SWE-agent trajectories into a Jac graph, localizes likely critical steps, clusters repeated failure motifs, and emits structured evidence packs that Codex or Claude Code can reason over more effectively than a raw trace dump.

## How It Works

1. Ingest a sample or uploaded batch of mini-SWE-agent trajectories.
2. Parse each run into decision steps, artifacts, tests, patches, and errors.
3. Compile those objects into a Jac graph.
4. Score failure families and cluster similar failures.
5. Localize the likely first irreversible step in representative failed runs.
6. Generate a `raw` evidence pack and a graph-backed `structured` evidence pack for the same failed run.
7. Let the outer coding agent or an optional built-in compare path analyze the difference.

## Why Jac

- graph-native storage for runs, steps, files, and clusters
- walkers as the analysis and API surface
- typed `by llm()` outputs for diagnosis and memory patch synthesis
- a Jac-native backend that powers a CLI-first product surface

## Current build status

- Jac-native parser and fingerprint pipeline for mini-SWE-agent trajectories
- Graph compilation into `Batch`, `Run`, `Step`, artifact, hypothesis, cluster, and memory-patch nodes
- CLI wrapper for doctor, run, pack, compare, and export flows
- Local upload-batch support alongside sample demo batches
- Zip upload-batch support for local archive ingestion
- Credential-gated typed `by llm()` hooks with deterministic fallback
- Provider configuration support for Codex CLI, OpenAI, and Anthropic
- Markdown batch report export for demo and Devpost backup artifacts

## What judges can see immediately

- a failed run with a localized critical step
- a raw evidence pack
- a structured graph-backed evidence pack
- a strict provider-backed compare when credentials are available
- a markdown batch report export that can stand in for the live compare path if needed

## What Makes It Different

- It is not a trace viewer; it is a trajectory compiler for coding agents.
- The main product loop is not "host the model." It is "improve the evidence pack."
- The LLM path is intentionally constrained to compact evidence packs instead of raw trajectories.
- Cluster-level memory patches turn repeated failures into reusable operational rules.
- Jac is central to the schema, graph traversal, typed outputs, and backend walkers that power the CLI.

## Challenges

- Keeping the project Jac-first while shaping it into a clean CLI product rather than a research demo.
- Making provider-backed compare explicit enough that it never silently misrepresents fallback behavior.
- Handling local upload folders and zip archives without turning the project into a generic ingestion platform.

## Accomplishments

- Shipped a Jac-native runtime path for parsing, graph build, clustering, localization, comparison, and export.
- Repositioned the product around a CLI-first workflow that fits Codex CLI and Claude Code usage.
- Added reliable markdown fallback artifacts for demo and Devpost use.

## What’s Next

- Stronger strict-mode provider handling and clearer JSON output contracts.
- Broader trajectory-schema support beyond mini-SWE-agent.
- Repeated-batch learning and memory retrieval across historical failure corpora.

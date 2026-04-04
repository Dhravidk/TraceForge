# Devpost Outline

## Problem

Coding-agent trajectories are long, repetitive, and hard to compare across many runs.

## Solution

TraceForge compiles batches of mini-SWE-agent trajectories into a Jac graph, clusters repeated failure motifs, localizes likely critical steps, and synthesizes reusable memory patches.

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
- Credential-gated typed `by llm()` hooks with deterministic fallback
- Markdown batch report export for demo and Devpost backup artifacts

## What judges can see immediately

- recurring failure families across a batch
- a representative cluster with recurring signals
- a failed run with a localized critical step
- an `AGENTS.md` patch synthesized from the cluster motif
- a raw-baseline versus structured-analysis comparison

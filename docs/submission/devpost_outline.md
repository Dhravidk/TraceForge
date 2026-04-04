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

This outline tracks the repo scaffold and should be updated alongside implementation.


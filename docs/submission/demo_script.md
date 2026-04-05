# Demo Script

## 3-minute terminal-first draft

### 0:00-0:20

"Developers already work inside Codex CLI and Claude Code. The problem is that when those agents fail, the trajectory is too long and noisy to analyze well. TraceForge turns raw agent runs into a Jac graph and then emits better evidence packs for the outer coding agent to reason over."

### 0:20-0:40

"I start with `traceforge doctor`. This shows whether I can use a live provider-backed compare, but the core product does not depend on that. The core product is the evidence pack."

### 0:40-1:05

"Now I analyze the sample batch and open one failed run. TraceForge has already compiled the run into graph objects, localized the likely first irreversible step, and summarized the dominant failure family."

### 1:05-1:35

"Here is the raw pack. This is roughly what a coding agent normally gets from compressed trajectory text. Now here is the structured TraceForge pack. It adds critical-step candidates, exact evidence windows, top files, top tests, top errors, and cluster context."

### 1:35-2:05

"This is the key idea: same failed run, same outer model, better evidence pack. We are not claiming a stronger model. We are claiming that structure improves the quality of analysis."

### 2:05-2:35

"If `doctor` says live Codex compare is ready, I run a strict compare on the same run. That live compare is illustrative, not the whole proof, because single-run judgments can be noisy. The quantitative uplift claim comes from the saved gold-scored batch evaluation artifacts."

### 2:35-3:00

"Jac is central here. The schema is graph-native, the walkers power the backend analysis surface, and the CLI is a thin product layer over Jac-native compilation and retrieval. TraceForge is not a trace viewer. It is a trajectory compiler for coding agents."

## Demo order

1. Run `traceforge doctor`.
2. Run `traceforge analyze-batch --batch sample-starter`.
3. Run `traceforge run --batch sample-starter --run premature_completion`.
4. Run `traceforge pack --batch sample-starter --run premature_completion --mode raw`.
5. Run `traceforge pack --batch sample-starter --run premature_completion --mode structured`.
6. Optionally run `traceforge compare --batch sample-starter --run premature_completion --strict-provider`.
7. End on `traceforge export-report --batch sample-starter` if a fallback artifact is needed.

## Live demo lock

When `traceforge doctor` reports `recommended_demo_mode: codex_cli_live_compare`, use the strict Codex compare as the primary demo path.
When it reports `pack_first_with_export_fallback`, skip live compare and stay on saved raw pack, structured pack, compare artifact, and markdown report.
For the current sample batch, prefer `premature_completion` over `invalid_patch` as the single-run live demo case.

# TraceForge Agent Workflows

TraceForge is meant to be used inside existing AI coding workflows rather than replacing them.

The intended operator is already in Codex CLI or Claude Code.
TraceForge supplies better evidence.

## Workflow A: Pack-first analysis

This is the default and most robust workflow.

```bash
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run invalid_patch
traceforge pack --batch sample-starter --run invalid_patch --mode raw
traceforge pack --batch sample-starter --run invalid_patch --mode structured
```

Then give both outputs to the outer coding agent and ask:

> Compare the raw trajectory evidence pack to the structured TraceForge evidence pack. Explain which gives a more grounded diagnosis and why.

## Workflow A2: Bring your own batch

If the operator already has local mini-SWE-agent trajectory files:

```bash
traceforge analyze-batch --input /path/to/my_batch
traceforge overview --batch upload-my_batch
traceforge run --batch upload-my_batch --run my_run_id
traceforge pack --batch upload-my_batch --run my_run_id --mode structured
```

This is the likely real-world workflow for teams using Codex CLI or Claude Code on their own runs.

If the outer agent should consume a saved artifact instead of terminal text:

```bash
traceforge pack --batch upload-my_batch --run my_run_id --mode structured --save
```

## Workflow B: JSON automation

For scripted agent use:

```bash
traceforge run --batch sample-starter --run invalid_patch --json
traceforge pack --batch sample-starter --run invalid_patch --mode structured --json
traceforge compare --batch sample-starter --run invalid_patch --provider openai --json
```

This is useful when the outer agent wants to parse structured output instead of reading terminal text.

If the outer agent should consume a saved compare artifact instead of stdout:

```bash
traceforge compare --batch sample-starter --run invalid_patch --save
```

## Workflow C: Strict live compare

If the provider is available:

```bash
traceforge compare --batch sample-starter --run invalid_patch --strict-provider
```

Strict mode is important because it prevents silent fallback during a live demo.

## Prompt you can hand to Codex or Claude Code

This repo should support a prompt like:

> Clone this repository, run TraceForge on the sample batch, generate the raw and structured evidence packs for one failed run, and explain why the structured pack is more useful for analysis.

## Practical guidance

- use `run` first to orient on a failure
- use `pack --mode raw` to show the baseline context
- use `pack --mode structured` to show TraceForge's value
- treat provider-backed compare as optional evidence, not the core product

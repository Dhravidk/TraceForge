# TraceForge CLI Command Reference

This is the compact reference for the public `traceforge` command.

## `traceforge doctor`

Purpose:
- show provider and environment readiness before a live session

Example:

```bash
traceforge doctor
traceforge doctor --json
```

## `traceforge auth status`

Purpose:
- inspect saved provider state and current provider readiness

Example:

```bash
traceforge auth status
```

## `traceforge auth use`

Purpose:
- save the preferred provider and optional model or key material

Examples:

```bash
traceforge auth use codex --model gpt-5.4
traceforge auth use openai --model gpt-5.4 --openai-api-key "$OPENAI_API_KEY"
traceforge auth use anthropic --model claude-sonnet-4-20250514 --anthropic-api-key "$ANTHROPIC_API_KEY"
```

## `traceforge auth clear`

Purpose:
- clear saved API keys and reset provider selection

Example:

```bash
traceforge auth clear
```

## `traceforge analyze-batch`

Purpose:
- analyze the sample batch or ingest and analyze a local folder or zip archive

Examples:

```bash
traceforge analyze-batch --batch sample-starter
traceforge analyze-batch --input /path/to/my_batch
traceforge analyze-batch --input /path/to/my_batch.zip
```

## `traceforge overview`

Purpose:
- show family counts, cluster counts, and top recurring artifacts for a batch

Example:

```bash
traceforge overview --batch sample-starter
```

## `traceforge run`

Purpose:
- inspect one failed run, including its likely critical step

Example:

```bash
traceforge run --batch sample-starter --run invalid_patch
```

## `traceforge cluster`

Purpose:
- inspect one recurring cluster and its medoid run

Example:

```bash
traceforge cluster --cluster sample-starter:invalid_patch:0
```

## `traceforge pack`

Purpose:
- emit the `raw` or `structured` evidence pack for one failed run

Examples:

```bash
traceforge pack --batch sample-starter --run invalid_patch --mode raw
traceforge pack --batch sample-starter --run invalid_patch --mode structured
traceforge pack --batch sample-starter --run invalid_patch --mode structured --save
traceforge pack --batch sample-starter --run invalid_patch --mode structured --output exports/packs/custom.md
```

## `traceforge compare`

Purpose:
- compare raw versus structured analysis on the same run

Examples:

```bash
traceforge compare --batch sample-starter --run invalid_patch
traceforge compare --batch sample-starter --run invalid_patch --strict-provider
traceforge compare --batch sample-starter --run invalid_patch --save
```

Notes:
- without a live provider, compare falls back to deterministic proxy and now says so explicitly
- `--strict-provider` prevents silent fallback

## `traceforge demo`

Purpose:
- generate the full sample demo bundle in one command

Example:

```bash
traceforge demo --batch sample-starter --run invalid_patch
traceforge demo --batch sample-starter --run invalid_patch --strict-provider
```

## `traceforge export-report`

Purpose:
- export the markdown batch report used as a fallback demo artifact

Example:

```bash
traceforge export-report --batch sample-starter
```

## `traceforge export-eval`

Purpose:
- export blind or rigorous evaluation artifacts

Examples:

```bash
traceforge export-eval --batch sample-starter --kind blind
traceforge export-eval --batch sample-starter --kind rigorous --provider openai --strict-provider
```

## Recommended order for a live session

1. `traceforge doctor`
2. `traceforge analyze-batch --batch sample-starter`
3. `traceforge run --batch sample-starter --run invalid_patch`
4. `traceforge pack --batch sample-starter --run invalid_patch --mode raw`
5. `traceforge pack --batch sample-starter --run invalid_patch --mode structured`
6. `traceforge compare --batch sample-starter --run invalid_patch --strict-provider`

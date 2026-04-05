# TraceForge CLI Quickstart

TraceForge is designed to be run from the terminal, usually from inside Codex CLI or Claude Code.

## Primary workflow

From a fresh clone:

```bash
git clone https://github.com/Dhravidk/TraceForge.git
cd TraceForge
./scripts/bootstrap
source .venv/bin/activate
```

Then run everything from the repo root:

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode raw
traceforge pack --batch sample-starter --run premature_completion --mode structured
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

Or generate the full sample demo bundle in one command:

```bash
traceforge demo --batch sample-starter --run premature_completion
```

If you prefer not to install the package entrypoint yet, the repo-local wrapper still works:

```bash
python3 scripts/traceforge doctor
```

## Why this workflow matters

The key product loop is:

1. inspect one failed run
2. generate the `raw` evidence pack
3. generate the `structured` TraceForge evidence pack
4. give those packs to Codex or Claude Code
5. compare the quality of the resulting analysis

The thesis is:

> same failed run, same outer model, better evidence pack

## Provider notes

Use `doctor` first:

```bash
traceforge doctor
```

If no provider is pinned, TraceForge prefers:

1. a saved provider from `traceforge auth use`
2. logged-in Codex CLI
3. configured OpenAI or Anthropic API providers

So on a Codex-logged-in machine, `traceforge compare ...` and `traceforge demo ...` now default to live Codex automatically.

If you want to force a provider-backed compare:

```bash
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

If strict mode cannot use the requested provider, the command exits with an error instead of silently falling back.

## Use your own trajectories

If you already have a folder or zip archive of mini-SWE-agent `*.traj.json` files:

```bash
traceforge analyze-batch --input /path/to/my_batch
traceforge analyze-batch --input /path/to/my_batch.zip
```

Then inspect one run and generate packs the same way:

```bash
traceforge run --batch upload-my_batch --run my_run_id
traceforge pack --batch upload-my_batch --run my_run_id --mode structured
```

To save a pack as a reusable artifact:

```bash
traceforge pack --batch upload-my_batch --run my_run_id --mode structured --save
```

## JSON mode

For automation from a coding agent:

```bash
traceforge run --batch sample-starter --run invalid_patch --json
traceforge pack --batch sample-starter --run invalid_patch --mode structured --json
traceforge compare --batch sample-starter --run invalid_patch --provider openai --json
```

## Exported artifacts

For a markdown backup artifact:

```bash
traceforge export-report --batch sample-starter
```

# TraceForge Provider Setup

TraceForge works in two modes:

- `pack-first` mode, which does not require any provider
- `provider-backed` mode, which uses Codex CLI, OpenAI, or Anthropic for live compare

For demos, the safest path is:

1. use `pack` commands as the primary story
2. use provider-backed compare only when `doctor` says the provider is healthy
3. use `--strict-provider` in judge-facing live sessions so fallback is never ambiguous

## Check readiness

```bash
traceforge doctor
traceforge auth status
```

Automatic resolution order is:

1. explicit `--provider`
2. saved preference from `traceforge auth use`
3. logged-in Codex CLI
4. configured OpenAI or Anthropic API provider

That means `traceforge compare ...` and `traceforge demo ...` will automatically use live Codex on a machine that is already logged in, unless you pin a different provider.

## Codex CLI

If Codex CLI is already installed and logged in:

```bash
traceforge auth use codex --model gpt-5.4
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

Use strict mode during demos so provider failures do not silently degrade into deterministic fallback.

If strict mode fails, the right fallback is:

```bash
traceforge pack --batch sample-starter --run premature_completion --mode raw --save
traceforge pack --batch sample-starter --run premature_completion --mode structured --save
traceforge export-report --batch sample-starter
```

That still supports the core thesis:

> same failed run, same outer model, better evidence pack

## OpenAI

```bash
traceforge auth use openai --model gpt-5.4 --openai-api-key "$OPENAI_API_KEY"
traceforge compare --batch sample-starter --run invalid_patch --provider openai --strict-provider
```

## Anthropic / Claude

```bash
traceforge auth use anthropic --model claude-sonnet-4-20250514 --anthropic-api-key "$ANTHROPIC_API_KEY"
traceforge compare --batch sample-starter --run invalid_patch --provider anthropic --strict-provider
```

## Reset saved provider state

```bash
traceforge auth clear
```

## Recommendation

For judge-facing usage:

- start with `pack` output
- use strict provider compare only if `doctor` shows the provider is available
- otherwise fall back to precomputed artifacts and keep the story focused on evidence quality

# TraceForge CLI Troubleshooting

This guide covers the failure modes most likely to matter during onboarding or a live demo.

## `traceforge doctor` first

Before debugging anything else, run:

```bash
traceforge doctor
```

That tells you:

- whether `jac` is available
- whether Codex CLI is installed
- whether Codex CLI is logged in
- whether OpenAI or Anthropic keys are present
- which demo mode is currently recommended

## Strict compare failed

If this command fails:

```bash
traceforge compare --batch sample-starter --run invalid_patch --strict-provider
```

It usually means one of these:

1. Codex CLI is installed but not logged in.
2. Codex CLI is logged in but out of quota.
3. The requested provider was not configured.
4. The provider path failed and strict mode correctly refused to fall back.

The correct fallback is:

```bash
traceforge pack --batch sample-starter --run invalid_patch --mode raw --save
traceforge pack --batch sample-starter --run invalid_patch --mode structured --save
traceforge export-report --batch sample-starter
```

That still supports the main demo thesis:

> same failed run, same outer model, better evidence pack

## Compare ran but says `deterministic_proxy`

That means the comparison completed without a live provider-backed verdict.

Common reasons:

- no provider was requested
- the provider was unavailable
- the provider failed and non-strict mode allowed fallback

Use:

```bash
traceforge doctor
```

Then decide whether to:

- retry with a healthy provider and `--strict-provider`
- or keep the product story centered on the pack difference

## `traceforge` command not found

Bootstrap and activate the environment:

```bash
./scripts/bootstrap
source .venv/bin/activate
```

Then confirm:

```bash
traceforge doctor
```

If you do not want to install the package entrypoint yet, the repo-local wrapper also works:

```bash
python3 scripts/traceforge doctor
```

## My own batch did not behave the way I expected

Use the input path directly:

```bash
traceforge analyze-batch --input /path/to/my_batch
```

or:

```bash
traceforge analyze-batch --input /path/to/my_batch.zip
```

Then inspect the batch ID returned by the command and use that in later commands:

```bash
traceforge overview --batch upload-my_batch
traceforge run --batch upload-my_batch --run my_run_id
```

## I need machine-readable output

Most public commands support:

```bash
--json
```

Use `--save` on `pack` or `compare` if you want a durable artifact file for another coding agent to consume.

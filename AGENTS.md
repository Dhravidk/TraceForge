# TraceForge Agent Instructions

TraceForge should be used as a **CLI-first tool**.

Do not start with the UI unless the user explicitly asks for it.
Do not start by exploring random implementation files if the user is trying to run the product.
The primary operator interface is the `traceforge` command.

## First steps after cloning

From the repo root:

```bash
./scripts/bootstrap
source .venv/bin/activate
traceforge doctor
```

If the package entrypoint is not installed yet, the repo-local wrapper also works:

```bash
python3 scripts/traceforge doctor
```

## Preferred sample workflow

Use this exact sequence first:

```bash
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode raw
traceforge pack --batch sample-starter --run premature_completion --mode structured
```

If the user wants the entire sample demo bundle prepared in one step:

```bash
traceforge demo --batch sample-starter --run premature_completion
```

The key product thesis is:

> same failed run, same outer model, better evidence pack

## Preferred real-user workflow

If the user already has local mini-SWE-agent trajectory files:

```bash
traceforge analyze-batch --input /path/to/my_batch
traceforge overview --batch upload-my_batch
traceforge run --batch upload-my_batch --run my_run_id
traceforge pack --batch upload-my_batch --run my_run_id --mode structured
```

## Provider-backed compare

Always check readiness first:

```bash
traceforge doctor
traceforge auth status
```

Use strict mode for judge-facing or user-facing live compares:

```bash
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

If strict compare is unavailable, do not pretend the result is live-provider-backed.
Fall back to saved artifacts instead:

```bash
traceforge pack --batch sample-starter --run invalid_patch --mode raw --save
traceforge pack --batch sample-starter --run invalid_patch --mode structured --save
traceforge compare --batch sample-starter --run invalid_patch --save
traceforge export-report --batch sample-starter
```

## When operating this repo

- Prefer the docs under `docs/cli/` over older planning docs.
- Treat `README.md` and `docs/cli/quickstart.md` as the primary operator docs.
- Treat historical plan docs as architecture context, not as the primary runbook.
- Prefer `--json` when another agent needs machine-readable output.
- Prefer `--save` when another agent should consume an artifact file instead of terminal output.

## Recommended docs

- `README.md`
- `docs/cli/quickstart.md`
- `docs/cli/provider_setup.md`
- `docs/cli/agent_workflows.md`
- `docs/cli/command_reference.md`
- `docs/cli/demo_playbook.md`
- `docs/cli/repo_handoff_prompts.md`
- `docs/cli/troubleshooting.md`

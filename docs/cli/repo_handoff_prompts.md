# TraceForge Repo Handoff Prompts

These are copy-paste prompts a user can give to Codex CLI or Claude Code so the agent can operate TraceForge from the GitHub URL alone.

## Prompt: install and run the sample workflow

```text
Clone https://github.com/Dhravidk/TraceForge, bootstrap the project, activate the environment, run TraceForge on the sample batch, and show me the structured evidence pack for one failed run. Use the repo docs instead of exploring random files.
```

## Prompt: compare raw versus structured packs

```text
Clone https://github.com/Dhravidk/TraceForge, install it, run the sample batch, generate both the raw and structured evidence packs for the run invalid_patch, and explain why the structured pack gives a more grounded diagnosis.
```

## Prompt: provider-backed compare

```text
Clone https://github.com/Dhravidk/TraceForge, install it, run `traceforge doctor`, and if Codex provider mode is healthy run a strict compare for invalid_patch. If strict compare is not available, fall back to showing the raw and structured packs plus the exported markdown artifact.
```

## Prompt: generate the whole demo bundle

```text
Clone https://github.com/Dhravidk/TraceForge, install it, and run the TraceForge demo bundle command for the sample batch so I can inspect the saved raw pack, structured pack, comparison artifact, and report artifact.
```

## Prompt: analyze my own trajectories

```text
Clone https://github.com/Dhravidk/TraceForge, install it, point TraceForge at my local folder of mini-SWE-agent trajectory JSON files, analyze the batch, and show me the most informative failed run with both raw and structured evidence packs.
```

## Prompt: automation-friendly JSON workflow

```text
Clone https://github.com/Dhravidk/TraceForge, bootstrap it, and use the `traceforge` CLI in JSON mode to analyze the sample batch, inspect invalid_patch, generate the structured pack, and show me the exported evaluation artifact paths.
```

## Notes

- The best default path is pack-first, not provider-first.
- The key product thesis is:

> same failed run, same outer model, better evidence pack

- `traceforge doctor` should always be the first command in a live session.

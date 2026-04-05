# Judging Notes

## JacHacks emphasis

The public JacHacks guide highlights:

- technical depth,
- meaningful Jac integration,
- real-world impact,
- and presentation quality.

## How this repo should align

- Keep Jac central in schema, walkers, orchestration, and typed LLM flows.
- Prefer a sharp working demo over a broad unfinished platform.
- Keep the explanation simple enough for a 3-minute pitch.
- Make the graph story visible in the CLI product surface itself.

## Current alignment status

- Jac is the primary implementation language for schema, parsing, graph build, walkers, and report export.
- The product story is now terminal-first: analyze a run, emit a raw pack, emit a structured pack, and show why the better evidence pack improves analysis.
- The repo includes backup markdown artifacts so the demo can still be shown if a live provider path fails.
- The UI still exists, but it is intentionally secondary to the CLI product.

## Guardrail

If a feature is hard to explain in the demo or weakens the CLI-first Jac story, it is lower priority than a cleaner MVP.

## Suggested demo emphasis

- Start with `traceforge doctor` and one failed run, not the UI.
- Use raw versus structured packs to explain why structure matters more than model choice.
- Treat provider-backed compare as optional proof, not the core product.
- Treat the exported markdown report as the fallback artifact, not as a side feature.

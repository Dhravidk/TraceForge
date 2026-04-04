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
- Make the graph story visible in both code and UI.

## Current alignment status

- Jac is the primary implementation language for schema, parsing, graph build, walkers, report export, and UI.
- The demo now follows the judging-friendly sequence: batch overview, cluster explorer, run forensics, and baseline comparison.
- The repo includes a backup markdown report export so the demo can still be shown if the UI path fails.
- The app now also surfaces cluster diagnosis and report export directly in the UI, which makes the Jac story visible during the demo itself.

## Guardrail

If a feature is hard to explain in the demo or weakens the Jac-first story, it is lower priority than a cleaner MVP.

## Suggested demo emphasis

- Show the graph-backed grouping before showing any single trajectory.
- Use the baseline comparison to explain why structure matters more than model choice.
- Treat the exported markdown report as the fallback artifact, not as a side feature.

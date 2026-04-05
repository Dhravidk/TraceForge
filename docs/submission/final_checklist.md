# Final Checklist

## Product

- `traceforge doctor` works from the terminal.
- Sample batch analysis works from the CLI.
- Folder upload ingestion works.
- Zip upload ingestion works.
- `traceforge run` shows a localized critical-step window.
- `traceforge pack --mode raw` works.
- `traceforge pack --mode structured` works.
- saved pack artifacts work.
- `traceforge compare` clearly reports provider-backed or deterministic mode.
- strict Codex compare works when `doctor` recommends `codex_cli_live_compare`.
- saved compare artifacts work.
- `AGENTS.md` patch generation works.
- Markdown batch report export works.

## Verification

- `./scripts/bootstrap`
- `traceforge doctor`
- `traceforge analyze-batch --batch sample-starter`
- `traceforge run --batch sample-starter --run premature_completion`
- `traceforge pack --batch sample-starter --run premature_completion --mode structured`
- `traceforge compare --batch sample-starter --run premature_completion --strict-provider`
- `traceforge export-report --batch sample-starter`

## Demo order

1. Run `traceforge doctor`.
2. Run `traceforge analyze-batch --batch sample-starter`.
3. Run `traceforge run --batch sample-starter --run premature_completion`.
4. Show the raw pack.
5. Show the structured pack.
6. Optionally run strict compare.
7. Fall back to saved artifacts if needed.
8. Export the markdown batch report.

## Fallbacks

- If live compare fails, use the raw and structured pack outputs directly and explain the evidence difference.
- If `doctor` reports `pack_first_with_export_fallback`, do not attempt the live compare in front of judges.
- Even when live compare works, use the saved batch eval artifacts for the numeric uplift claim because single-run verdicts are noisy.
- If provider credentials are unavailable, keep deterministic mode visible and explain that the evidence packs are still bounded and useful.
- If the UI path fails, ignore it and stay in the CLI.
- If upload ingestion is unstable, use the starter sample batch.

## Remaining optional polish

- Final copy edits for Devpost.
- Final 3-minute terminal demo recording.
- Optional stronger strict-provider handling and artifact polish.

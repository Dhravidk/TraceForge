# Final Checklist

## Product

- Batch catalog works for sample and local upload batches.
- Folder upload ingestion works.
- Zip upload ingestion works.
- Batch overview shows failure families and top recurring artifacts.
- Cluster explorer shows recurring signals and representative runs.
- Run detail shows a localized critical-step window.
- Baseline comparison shows blind spots versus structured support points.
- Cluster diagnosis is visible in the UI.
- `AGENTS.md` patch generation works.
- Markdown batch report export works.

## Verification

- `jac check main.jac`
- `jac test tests/smoke.jac`
- `jac enter main.jac GetBatchCatalog`
- `jac enter main.jac AnalyzeBatch sample-starter`
- `jac enter main.jac ExportBatchReport sample-starter`

## Demo order

1. Open the starter batch.
2. Show failure families and cluster counts.
3. Open the first cluster and show the generated patch.
4. Open the medoid run and point to the critical-step evidence window.
5. Show the raw baseline versus structured comparison.
6. Export the markdown batch report.

## Fallbacks

- If the UI path fails, use the exported markdown report in `exports/`.
- If typed `by llm()` credentials are unavailable, keep the deterministic fallback visible and explain that the evidence packs are still typed and bounded.
- If upload ingestion is unstable, use the starter sample batch.

## Remaining optional polish

- Final copy edits for Devpost.
- Final 3-minute demo recording.
- Optional stronger typed `by llm()` synthesis if credentials are present.

# TraceForge CLI Demo Playbook

This is the terminal-first JacHacks demo path.

## Primary demo

Use this path when `traceforge doctor` reports `recommended_demo_mode: codex_cli_live_compare`.

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode raw
traceforge pack --batch sample-starter --run premature_completion --mode structured
traceforge compare --batch sample-starter --run premature_completion --strict-provider
```

This path has been validated on the current repo setup: strict Codex compare completed successfully and returned `comparison_mode: codex_same_model_blinded`.
For the sample batch, `premature_completion` is the strongest current live demo case.

## One-command artifact bundle

If you want the terminal session and all artifacts prepared in one step:

```bash
traceforge demo --batch sample-starter --run premature_completion
```

This is best treated as an artifact-prep command, not the default live-demo path. It can take noticeably longer than the stepped workflow because it analyzes the batch, writes both packs, runs compare, and copies the report in one shot.

For a live-provider demo bundle when Codex is healthy:

```bash
traceforge demo --batch sample-starter --run premature_completion --strict-provider
```

## What to say

1. `doctor`
   Explain that TraceForge is designed to run inside Codex CLI or Claude Code workflows, and this command shows whether live provider-backed compare is safe.

2. `run`
   Explain that TraceForge has already compiled the trajectory into a Jac graph and localized the likely first irreversible step.

3. `pack --mode raw`
   Explain that this is the baseline context a coding agent would normally get from compressed raw trajectory text.

4. `pack --mode structured`
   Explain that TraceForge adds critical-step candidates, exact evidence windows, top files, tests, errors, and cluster context.

5. `compare`
   Explain that the point is not a stronger model. The point is the same outer model with a better evidence pack.
   Treat a single live compare as a qualitative illustration, not as the full quantitative proof.

## Fallback demo

If strict provider compare is unavailable or `doctor` recommends `pack_first_with_export_fallback`:

```bash
traceforge doctor
traceforge run --batch sample-starter --run premature_completion
traceforge pack --batch sample-starter --run premature_completion --mode raw --save
traceforge pack --batch sample-starter --run premature_completion --mode structured --save
traceforge compare --batch sample-starter --run premature_completion --save
traceforge export-report --batch sample-starter
```

End by showing the saved pack artifacts, the saved compare artifact, or the exported markdown report.

## Demo thesis

> same failed run, same outer model, better evidence pack

## Quantitative proof

Use the live compare to show the mechanism.
Use the saved gold-scored batch evaluation artifacts to support the actual uplift claim.

The key point for judges is:

- single-run live compares can be noisy
- the batch-level gold-scored evaluation is the real evidence for uplift

# TraceForge CLI Output Schema

TraceForge CLI commands support human-readable output by default and machine-readable JSON with `--json`.

## Shared fields

The public JSON interface should use these fields where applicable:

- `command`
- `status`
- `batch_id`
- `run_id`
- `cluster_id`
- `mode`
- `provider`
- `provider_available`
- `strict_provider`
- `comparison_mode`
- `artifact_paths`
- `message`
- `warning`

## `doctor`

Key fields:

- `command`
- `preferred_provider`
- `resolved_provider`
- `resolved_available`
- `providers`
- `recommended_demo_mode`

## `run`

Key fields:

- `command`
- `task_title`
- `summary`
- `primary_failure`
- `critical_step_idx`
- `artifacts`

## `pack`

Key fields:

- `command`
- `mode`
- `prompt_mode`
- `text`
- `token_estimate`
- `primary_failure`
- `critical_step_idx`
- `cluster_ids`
- `artifact_paths.pack_path` when `--save` or `--output` is used

## `compare`

Key fields:

- `command`
- `baseline`
- `structured`
- `verifier`
- `comparison_mode`
- `warning`
- `artifact_paths.comparison_path` when `--save` or `--output` is used

## `export-report`

Key fields:

- `command`
- `path`
- `batch_id`
- `cluster_count`
- `artifact_paths`

## `export-eval`

For blind exports:

- `command`
- `blind_sheet_path`
- `blind_key_path`
- `summary_json_path`
- `artifact_paths`
- `warning`

For rigorous exports:

- `command`
- `summary_markdown_path`
- `summary_json_path`
- `gold_score_path`
- `artifact_paths`
- `warning`

## `demo`

Key fields:

- `command`
- `batch_id`
- `run_id`
- `comparison_mode`
- `warning`
- `artifact_paths.raw_pack`
- `artifact_paths.structured_pack`
- `artifact_paths.comparison`
- `artifact_paths.report`
- `analyze`
- `run`

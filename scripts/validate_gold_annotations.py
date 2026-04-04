#!/usr/bin/env python3
import argparse
import json
from collections import Counter
from pathlib import Path

ALLOWED_FAILURE_CLASSES = {
    "PREMATURE_COMPLETION",
    "INVALID_PATCH",
    "WRONG_FILE_FOCUS",
    "OSCILLATION_LOOP",
    "TOOL_MISUSE",
    "STALE_CONTEXT_OR_BAD_PLAN",
    "REQUIREMENT_DRIFT",
    "UNKNOWN",
}


def _render_markdown(payload: dict) -> str:
    annotations = payload.get("annotations", [])
    substantive = sum(1 for item in annotations if item.get("group") == "substantive")
    startup = sum(1 for item in annotations if item.get("group") == "startup")
    lines = [
        "# TraceForge Gold Annotation Worksheet",
        "",
        f"- Batch ID: `{payload.get('batch_id', '')}`",
        f"- Substantive runs: {substantive}",
        f"- Startup runs: {startup}",
        "",
        "Annotate each run from the raw trajectory only.",
        "",
    ]
    for item in annotations:
        lines.append(f"## Run `{item.get('run_id', '')}`")
        lines.append("")
        lines.append(f"- Group: {item.get('group', '')}")
        lines.append(f"- Task title: {item.get('task_title', '')}")
        lines.append(f"- Source path: `{item.get('source_path', '')}`")
        lines.append(f"- Step count: {item.get('step_count', 0)}")
        lines.append(f"- Gold failure class: {item.get('gold_failure_class', '')}")
        lines.append(f"- Gold critical step idx: {item.get('gold_critical_step_idx', -1)}")
        lines.append(f"- Gold supporting steps: {item.get('gold_supporting_steps', [])}")
        lines.append(f"- Gold short rationale: {item.get('gold_short_rationale', '')}")
        lines.append(f"- Gold memory rule useful (yes/no): {item.get('gold_memory_rule_useful', '')}")
        lines.append("")
    return "\n".join(lines).strip() + "\n"


def validate_payload(payload: dict) -> list[str]:
    errors: list[str] = []
    annotations = payload.get("annotations")
    if not isinstance(annotations, list):
        return ["Payload must contain an 'annotations' list."]

    for item in annotations:
        run_id = str(item.get("run_id") or "<missing-run-id>")
        failure_class = str(item.get("gold_failure_class") or "")
        memory_rule = str(item.get("gold_memory_rule_useful") or "").lower()
        rationale = str(item.get("gold_short_rationale") or "").strip()
        step_count = int(item.get("step_count") or 0)
        critical_step_idx = int(item.get("gold_critical_step_idx", -1))
        supporting_steps = item.get("gold_supporting_steps") or []

        if failure_class not in ALLOWED_FAILURE_CLASSES:
            errors.append(f"{run_id}: invalid gold_failure_class '{failure_class}'.")
        if memory_rule not in {"yes", "no"}:
            errors.append(f"{run_id}: gold_memory_rule_useful must be 'yes' or 'no'.")
        if not rationale:
            errors.append(f"{run_id}: gold_short_rationale is empty.")
        if not isinstance(supporting_steps, list):
            errors.append(f"{run_id}: gold_supporting_steps must be a list.")
            supporting_steps = []
        for step_idx in supporting_steps:
            if int(step_idx) < 0 or int(step_idx) >= step_count:
                errors.append(f"{run_id}: supporting step {step_idx} is outside 0..{max(step_count - 1, 0)}.")
        if critical_step_idx == -1:
            if step_count > 0 and failure_class != "UNKNOWN":
                errors.append(f"{run_id}: non-UNKNOWN failure class requires a concrete gold_critical_step_idx.")
            if supporting_steps:
                errors.append(f"{run_id}: supporting steps must be empty when gold_critical_step_idx is -1.")
        else:
            if critical_step_idx < 0 or critical_step_idx >= step_count:
                errors.append(f"{run_id}: gold_critical_step_idx {critical_step_idx} is outside 0..{max(step_count - 1, 0)}.")
            if not supporting_steps:
                errors.append(f"{run_id}: gold_supporting_steps must contain at least one step when a critical step is set.")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate and optionally refresh a TraceForge gold annotation worksheet.")
    parser.add_argument("annotation_path", help="Path to the gold annotation JSON file.")
    parser.add_argument("--rewrite-markdown", action="store_true", help="Rewrite the sibling markdown worksheet from the JSON payload.")
    args = parser.parse_args()

    annotation_path = Path(args.annotation_path)
    payload = json.loads(annotation_path.read_text(encoding="utf-8"))
    errors = validate_payload(payload)
    if errors:
        print("Validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    annotations = payload.get("annotations", [])
    counts = Counter(str(item.get("gold_failure_class") or "") for item in annotations)
    print(f"Validated {len(annotations)} annotations from {annotation_path}.")
    for label, count in sorted(counts.items()):
        print(f"- {label}: {count}")

    if args.rewrite_markdown:
        markdown_path = annotation_path.with_suffix(".md")
        markdown_path.write_text(_render_markdown(payload), encoding="utf-8")
        print(f"Rewrote {markdown_path}.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

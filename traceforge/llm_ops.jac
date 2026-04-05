import from traceforge.analysis { cluster_view_summary, run_view_summary }
import from traceforge.graph_build {
    ensure_batch_graph,
    failure_class_name,
    find_cluster_node,
    upsert_cluster_patch
}
import from traceforge.parser { truncate_text }
import from traceforge.provider_llm { provider_llm_status, run_provider_json }

def llm_runtime_status() -> dict[str, any] {
    return provider_llm_status();
}

def llm_enabled() -> bool {
    return bool(llm_runtime_status()["llm_ready"]);
}

def _merge_runtime_status(payload: dict[str, any], runtime: dict[str, any]) -> dict[str, any] {
    payload["resolved_provider"] = str(runtime.get("resolved_provider") or "");
    payload["resolved_model"] = str(runtime.get("resolved_model") or "");
    payload["provider_available"] = bool(runtime.get("provider_available"));
    payload["llm_status"] = str(runtime.get("status") or "");
    payload["llm_note"] = str(runtime.get("message") or "");
    return payload;
}

def _normalize_failure_class_name(name: str) -> str {
    allowed = {
        "PREMATURE_COMPLETION",
        "INVALID_PATCH",
        "WRONG_FILE_FOCUS",
        "OSCILLATION_LOOP",
        "TOOL_MISUSE",
        "STALE_CONTEXT_OR_BAD_PLAN",
        "REQUIREMENT_DRIFT",
        "UNKNOWN",
    };
    upper_name = str(name or "UNKNOWN").upper();
    return upper_name if upper_name in allowed else "UNKNOWN";
}

def _run_diagnosis_instruction() -> str {
    return "\n".join(
        [
            "You are diagnosing a coding-agent trajectory.",
            "Return JSON only.",
            "Use only the provided evidence.",
            "Do not invent missing steps, files, tests, or outcomes.",
            "Choose the earliest plausible irreversible mistake.",
            "When the pack shows canonical decision steps, use those 0-based step_idx values in critical_step_idx and evidence_refs.",
        ]
    );
}

def _run_diagnosis_schema() -> dict[str, any] {
    return {
        "type": "object",
        "properties": {
            "failure_class": {
                "type": "string",
                "enum": [
                    "PREMATURE_COMPLETION",
                    "INVALID_PATCH",
                    "WRONG_FILE_FOCUS",
                    "OSCILLATION_LOOP",
                    "TOOL_MISUSE",
                    "STALE_CONTEXT_OR_BAD_PLAN",
                    "REQUIREMENT_DRIFT",
                    "UNKNOWN",
                ],
            },
            "critical_step_idx": {"type": "integer"},
            "evidence_refs": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "step_idx": {"type": "integer"},
                        "artifact": {"type": "string"},
                        "quote": {"type": "string"},
                    },
                    "required": ["step_idx", "artifact", "quote"],
                    "additionalProperties": False,
                },
            },
            "irreversible_because": {"type": "string"},
            "memory_rule": {"type": "string"},
            "confidence": {"type": "number"},
        },
        "required": [
            "failure_class",
            "critical_step_idx",
            "evidence_refs",
            "irreversible_because",
            "memory_rule",
            "confidence",
        ],
        "additionalProperties": False,
    };
}

def _cluster_label_instruction() -> str {
    return "\n".join(
        [
            "You are labeling a recurring coding-agent failure cluster.",
            "Return JSON only.",
            "Use only the cluster evidence provided.",
            "Prefer a short, concrete label and a one- or two-sentence summary.",
        ]
    );
}

def _cluster_label_schema() -> dict[str, any] {
    return {
        "type": "object",
        "properties": {
            "label": {"type": "string"},
            "summary": {"type": "string"},
            "confidence": {"type": "number"},
        },
        "required": ["label", "summary", "confidence"],
        "additionalProperties": False,
    };
}

def _memory_patch_instruction() -> str {
    return "\n".join(
        [
            "You are synthesizing an AGENTS.md-compatible memory patch from repeated trajectory evidence.",
            "Return JSON only.",
            "Derive rules from repeated evidence across runs before generalizing.",
            "Every rule must be operational, concise, and grounded in the supplied evidence.",
            "Do not invent new files, tests, or failure modes.",
        ]
    );
}

def _memory_patch_schema() -> dict[str, any] {
    return {
        "type": "object",
        "properties": {
            "scope": {"type": "string"},
            "cluster_label": {"type": "string"},
            "summary": {"type": "string"},
            "rules": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "rationale": {"type": "string"},
                        "rule_text": {"type": "string"},
                        "supported_by_steps": {
                            "type": "array",
                            "items": {"type": "integer"},
                        },
                        "confidence": {"type": "number"},
                    },
                    "required": ["title", "rationale", "rule_text", "supported_by_steps", "confidence"],
                    "additionalProperties": False,
                },
            },
            "diff_text": {"type": "string"},
        },
        "required": ["scope", "cluster_label", "summary", "rules", "diff_text"],
        "additionalProperties": False,
    };
}

def _provider_run_diagnosis(prompt_pack: str, run_id: str) -> dict[str, any] {
    response = run_provider_json(
        _run_diagnosis_instruction(),
        prompt_pack,
        _run_diagnosis_schema(),
    );
    parsed = response["parsed"];
    evidence = [];
    raw_evidence = parsed.get("evidence_refs") or [];
    if isinstance(raw_evidence, list) {
        for item in raw_evidence {
            if not isinstance(item, dict) {
                continue;
            }
            evidence.append(
                {
                    "step_idx": int(item.get("step_idx") or -1),
                    "artifact": str(item.get("artifact") or ""),
                    "quote": str(item.get("quote") or ""),
                }
            );
        }
    }
    return {
        "run_id": run_id,
        "failure_class": _normalize_failure_class_name(str(parsed.get("failure_class") or "UNKNOWN")),
        "critical_step_idx": int(parsed.get("critical_step_idx") or -1),
        "irreversible_because": str(parsed.get("irreversible_because") or ""),
        "evidence": evidence,
        "confidence": float(parsed.get("confidence") or 0.0),
        "memory_rule": str(parsed.get("memory_rule") or ""),
        "provider": str(response["provider"]),
        "model": str(response["model"]),
        "latency_ms": float(response["latency_ms"]),
        "usage": response["usage"],
        "raw_model_text": str(response["raw_model_text"]),
    };
}

def _provider_cluster_label(prompt_pack: str) -> dict[str, any] {
    response = run_provider_json(
        _cluster_label_instruction(),
        prompt_pack,
        _cluster_label_schema(),
    );
    parsed = response["parsed"];
    return {
        "label": str(parsed.get("label") or ""),
        "summary": str(parsed.get("summary") or ""),
        "confidence": float(parsed.get("confidence") or 0.0),
        "provider": str(response["provider"]),
        "model": str(response["model"]),
        "latency_ms": float(response["latency_ms"]),
        "usage": response["usage"],
        "raw_model_text": str(response["raw_model_text"]),
    };
}

def _provider_memory_patch(prompt_pack: str) -> dict[str, any] {
    response = run_provider_json(
        _memory_patch_instruction(),
        prompt_pack,
        _memory_patch_schema(),
    );
    parsed = response["parsed"];
    output_rules = [];
    raw_rules = parsed.get("rules") or [];
    if isinstance(raw_rules, list) {
        for item in raw_rules {
            if not isinstance(item, dict) {
                continue;
            }
            step_refs: list[int] = [];
            raw_steps = item.get("supported_by_steps") or [];
            if isinstance(raw_steps, list) {
                for step_idx in raw_steps {
                    step_refs.append(int(step_idx));
                }
            }
            output_rules.append(
                {
                    "title": str(item.get("title") or ""),
                    "rationale": str(item.get("rationale") or ""),
                    "rule_text": str(item.get("rule_text") or ""),
                    "supported_by_steps": step_refs,
                    "confidence": float(item.get("confidence") or 0.0),
                    "provenance": "provider_synthesis",
                }
            );
        }
    }
    return {
        "scope": str(parsed.get("scope") or "cluster"),
        "cluster_label": str(parsed.get("cluster_label") or ""),
        "summary": str(parsed.get("summary") or ""),
        "rules": output_rules,
        "diff_text": str(parsed.get("diff_text") or ""),
        "provider": str(response["provider"]),
        "model": str(response["model"]),
        "latency_ms": float(response["latency_ms"]),
        "usage": response["usage"],
        "raw_model_text": str(response["raw_model_text"]),
    };
}

def diagnosis_reason(failure_class: str) -> str {
    reasons = {
        "PREMATURE_COMPLETION": "the run moved to submission before validating that the failing state had recovered",
        "INVALID_PATCH": "the patch introduced or preserved a syntax-level failure that the run never repaired",
        "WRONG_FILE_FOCUS": "the run spent effort on files that did not reduce the target failure",
        "OSCILLATION_LOOP": "the run repeated the same search or file-touch pattern without creating recovery evidence",
        "TOOL_MISUSE": "tool interactions kept returning failure signals and the run never corrected the workflow",
        "STALE_CONTEXT_OR_BAD_PLAN": "the run stayed in planning or inspection too long without decisive repo interaction",
        "REQUIREMENT_DRIFT": "the run drifted away from the issue target and never came back to a validating path",
        "UNKNOWN": "the failure pattern is not yet classified strongly enough for a tighter explanation",
    };
    return reasons.get(failure_class, reasons["UNKNOWN"]);
}

def cluster_rule_lines(failure_class: str) -> list[str] {
    if failure_class == "PREMATURE_COMPLETION" {
        return [
            "Before submitting, rerun at least one targeted failing test if any test failed earlier.",
            "Do not submit if the latest visible state lacks post-patch validation.",
        ];
    }
    if failure_class == "INVALID_PATCH" {
        return [
            "After applying a patch, run the targeted test before submitting.",
            "Do not submit when the latest output still shows syntax, import, or traceback failures.",
        ];
    }
    if failure_class == "OSCILLATION_LOOP" {
        return [
            "After two repeated search or same-file inspection cycles with no new evidence, change strategy.",
            "If the same file has been touched repeatedly without recovery, re-rank candidate files from failing tests and errors.",
        ];
    }
    if failure_class == "WRONG_FILE_FOCUS" {
        return [
            "Prioritize files named in failing tests, stack traces, or direct issue context before editing secondary files.",
            "If edits do not reduce the original failure signal, stop and re-rank the target files.",
        ];
    }
    if failure_class == "TOOL_MISUSE" {
        return [
            "Treat repeated non-zero tool outcomes as a strategy failure and adjust before continuing.",
            "Do not keep issuing malformed or irrelevant commands after the same failure repeats.",
        ];
    }
    if failure_class == "STALE_CONTEXT_OR_BAD_PLAN" {
        return [
            "Limit consecutive planning or search-only turns without touching the repo or validating a hypothesis.",
            "After prolonged inspection, commit to one concrete file-level hypothesis and test it.",
        ];
    }
    if failure_class == "REQUIREMENT_DRIFT" {
        return [
            "Keep edits anchored to the failing test, stack trace, or issue target.",
            "If later steps stop mentioning the original failure context, pause and re-establish the target before editing again.",
        ];
    }
    return [
        "Prefer targeted validation before submission.",
        "Escalate to a new strategy when repeated steps stop producing new evidence.",
    ];
}

def _fallback_rule_records(cluster_view: dict[str, any], support_records: list[dict[str, any]]) -> list[dict[str, any]] {
    failure_class = str(cluster_view["failure_class"]);
    base_rules = cluster_rule_lines(failure_class);
    step_refs = _supported_steps(support_records);
    evidence_anchor = _join_tokens(
        [
            str(record["run_id"]) + "@" + str(record["critical_step_idx"])
            for record in support_records
        ],
        3,
    );
    evidence_quote = _join_tokens([str(record["quote"]) for record in support_records], 2);
    records: list[dict[str, any]] = [];
    for (index, rule_text) in enumerate(base_rules) {
        records.append(
            {
                "title": str(cluster_view["label"]) + " fallback rule " + str(index + 1),
                "rationale": "Fallback rule rendered from failure family. Supported by " + evidence_anchor + ". Evidence: " + evidence_quote,
                "rule_text": rule_text,
                "supported_by_steps": step_refs,
                "confidence": 0.52 if len(step_refs) >= 2 else 0.46,
                "provenance": "fallback_template",
            }
        );
    }
    return records;
}

def _join_tokens(items: list[any], limit: int = 3) -> str {
    chosen: list[str] = [];
    for item in items {
        if len(chosen) >= limit {
            break;
        }
        chosen.append(str(item));
    }
    return ", ".join(chosen);
}

def _quote_hit_count(records: list[dict[str, any]], tokens: list[str]) -> int {
    hits = 0;
    for record in records {
        quote_lower = str(record.get("quote") or "").lower();
        if any(token in quote_lower for token in tokens) {
            hits += 1;
        }
    }
    return hits;
}

def _rule_confidence(support_records: list[dict[str, any]], base: float = 0.62, bonus_per_record: float = 0.04) -> float {
    return min(0.82, round(base + (len(support_records) * bonus_per_record), 2));
}

def _build_rule_record(
    title: str,
    rationale: str,
    rule_text: str,
    step_refs: list[int],
    confidence: float,
    provenance: str,
) -> dict[str, any] {
    return {
        "title": title,
        "rationale": rationale,
        "rule_text": rule_text,
        "supported_by_steps": step_refs,
        "confidence": confidence,
        "provenance": provenance,
    };
}

def _critical_quote(run_view: dict[str, any]) -> str {
    for step in run_view["critical_evidence_window"] {
        if int(step["idx"]) == int(run_view["critical_step_idx"]) {
            return str(step["excerpt"]);
        }
    }
    if len(run_view["critical_evidence_window"]) > 0 {
        return str(run_view["critical_evidence_window"][0]["excerpt"]);
    }
    return str(run_view["summary"]);
}

def _cluster_support_records(root_node: any, cluster_view: dict[str, any]) -> list[dict[str, any]] {
    batch_id = str(cluster_view.get("batch_id") or str(cluster_view["cluster_id"]).split(":")[0]);
    support_records: list[dict[str, any]] = [];
    for run_item in cluster_view["representative_runs"] {
        if len(support_records) >= 3 {
            break;
        }
        run_view = run_view_summary(root_node, str(run_item["run_id"]), batch_id);
        if run_view["status"] == "stub" {
            continue;
        }
        support_records.append(
            {
                "run_id": run_view["run_id"],
                "batch_id": run_view["batch_id"],
                "critical_step_idx": run_view["critical_step_idx"],
                "quote": _critical_quote(run_view),
                "top_files": run_view["artifacts"]["fingerprint"].get("top_files", []),
                "top_tests": run_view["artifacts"]["fingerprint"].get("top_test_names", []),
                "top_errors": run_view["artifacts"]["fingerprint"].get("top_error_keywords", []),
            }
        );
    }
    return support_records;
}

def _supported_steps(records: list[dict[str, any]]) -> list[int] {
    steps: list[int] = [];
    for record in records {
        step_idx = int(record["critical_step_idx"]);
        if step_idx >= 0 and step_idx not in steps {
            steps.append(step_idx);
        }
    }
    return steps;
}

def _evidence_lines(cluster_view: dict[str, any], support_records: list[dict[str, any]]) -> list[str] {
    lines: list[str] = [];
    for record in support_records {
        lines.append(
            str(record["run_id"])
            + "@"
            + str(record["critical_step_idx"])
            + ": "
            + str(record["quote"])
        );
    }
    if cluster_view["recurring_tests"] {
        lines.append(
            "Recurring tests: "
            + _join_tokens([item[0] for item in cluster_view["recurring_tests"]], 3)
        );
    }
    if cluster_view["recurring_errors"] {
        lines.append(
            "Recurring errors: "
            + _join_tokens([item[0] for item in cluster_view["recurring_errors"]], 3)
        );
    }
    if cluster_view["recurring_files"] {
        lines.append(
            "Recurring files: "
            + _join_tokens([item[0] for item in cluster_view["recurring_files"]], 3)
        );
    }
    return lines;
}

def _evidence_grounded_rule_records(cluster_view: dict[str, any], support_records: list[dict[str, any]]) -> list[dict[str, any]] {
    recurring_tests = [item[0] for item in cluster_view["recurring_tests"]];
    recurring_errors = [item[0] for item in cluster_view["recurring_errors"]];
    recurring_files = [item[0] for item in cluster_view["recurring_files"]];
    step_refs = _supported_steps(support_records);
    support_refs = _join_tokens(
        [
            str(record["run_id"]) + "@" + str(record["critical_step_idx"])
            for record in support_records
        ],
        3,
    );
    quote_preview = _join_tokens([str(record["quote"]) for record in support_records], 2);
    records: list[dict[str, any]] = [];
    submit_hits = _quote_hit_count(support_records, ["submit", "final"]);
    inspect_hits = _quote_hit_count(support_records, ["grep ", "ls ", "find ", "read ", "inspect", "rg ", "cat ", "sed "]);
    patch_hits = _quote_hit_count(support_records, ["patch", "diff", "apply_patch"]);
    error_hits = _quote_hit_count(support_records, ["traceback", "error", "exception", "failed", "syntaxerror", "importerror"]);

    if recurring_tests {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " validation rule",
                "Derived from recurring tests (" + _join_tokens(recurring_tests, 2) + ") and support records " + support_refs + ". Evidence: " + quote_preview,
                "Before submitting, rerun at least one targeted failing test such as " + _join_tokens(recurring_tests, 2) + ".",
                step_refs,
                _rule_confidence(support_records, 0.64),
                "cluster_evidence:recurring_tests",
            )
        );
    }

    if recurring_errors {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " error gate",
                "Derived from recurring error signatures (" + _join_tokens(recurring_errors, 2) + ") anchored by " + support_refs + ". Evidence: " + quote_preview,
                "Do not keep editing or submit while failure signals like " + _join_tokens(recurring_errors, 2) + " are still visible in the latest output.",
                step_refs,
                _rule_confidence(support_records, 0.66),
                "cluster_evidence:recurring_errors",
            )
        );
    }

    if recurring_files {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " file focus rule",
                "Derived from recurring file concentration (" + _join_tokens(recurring_files, 2) + ") across " + support_refs + ". Evidence: " + quote_preview,
                "Keep investigation anchored to files like " + _join_tokens(recurring_files, 2) + " before branching into secondary files.",
                step_refs,
                _rule_confidence(support_records, 0.62),
                "cluster_evidence:recurring_files",
            )
        );
    }

    if inspect_hits >= 2 and recurring_files {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " inspection loop guard",
                "Derived from repeated inspection-heavy support records around " + _join_tokens(recurring_files, 2) + ". Evidence: " + quote_preview,
                "After repeated inspection-only cycles on " + _join_tokens(recurring_files, 2) + ", commit to one file-level hypothesis and validate it instead of continuing to search.",
                step_refs,
                _rule_confidence(support_records, 0.65),
                "cluster_evidence:repeated_inspection",
            )
        );
    }

    if patch_hits > 0 and recurring_tests {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " patch validation order",
                "Derived from repeated patch-followed-by-validation patterns in " + support_refs + ". Evidence: " + quote_preview,
                "After each patch touching " + _join_tokens(recurring_files, 2) + ", immediately rerun a targeted test such as " + _join_tokens(recurring_tests, 2) + " before making another edit.",
                step_refs,
                _rule_confidence(support_records, 0.67),
                "cluster_evidence:patch_then_test",
            )
        );
    }

    if submit_hits > 0 and (len(recurring_tests) > 0 or len(recurring_errors) > 0) {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " submit gate",
                "Derived from support records that include early submission behavior: " + support_refs + ". Evidence: " + quote_preview,
                "Block submission until the latest state no longer shows " + _join_tokens(recurring_errors, 2) + " and at least one targeted validation has been rerun.",
                step_refs,
                _rule_confidence(support_records, 0.68),
                "cluster_evidence:premature_submit",
            )
        );
    }

    if error_hits > 0 and len(recurring_errors) > 0 and len(recurring_tests) == 0 {
        records.append(
            _build_rule_record(
                str(cluster_view["label"]) + " recovery requirement",
                "Derived from persistent failure evidence with no recurring validation steps. Evidence: " + quote_preview,
                "When errors like " + _join_tokens(recurring_errors, 2) + " appear, add a focused validation step before continuing so the run can detect recovery instead of drifting.",
                step_refs,
                _rule_confidence(support_records, 0.63),
                "cluster_evidence:persistent_failures",
            )
        );
    }

    deduped: list[dict[str, any]] = [];
    seen_rules: set[str] = set();
    for record in records {
        rule_text = str(record["rule_text"]);
        if rule_text in seen_rules {
            continue;
        }
        seen_rules.add(rule_text);
        deduped.append(record);
    }
    if deduped {
        return deduped[:4];
    }
    return _fallback_rule_records(cluster_view, support_records);
}

def _run_evidence_pack(run_view: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge run evidence pack");
    lines.append("Run ID: " + str(run_view["run_id"]));
    lines.append("Task: " + str(run_view["task_title"]));
    lines.append("Primary failure candidate: " + str(run_view["primary_failure"]));
    lines.append("Critical step candidate: " + str(run_view["critical_step_idx"]));
    lines.append("Summary: " + str(run_view["summary"]));
    lines.append("Fingerprint:");
    lines.append(str(run_view["artifacts"]["fingerprint"]));
    lines.append("Critical evidence window:");
    for step in run_view["critical_evidence_window"] {
        lines.append(
            "Step "
            + str(step["idx"])
            + " ["
            + str(step["phase"])
            + "]: "
            + str(step["excerpt"])
        );
    }
    return truncate_text("\n".join(lines), 2200);
}

def _cluster_evidence_pack(cluster_view: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge cluster evidence pack");
    lines.append("Cluster ID: " + str(cluster_view["cluster_id"]));
    lines.append("Cluster label candidate: " + str(cluster_view["label"]));
    lines.append("Failure class: " + str(cluster_view["failure_class"]));
    lines.append("Cluster size: " + str(cluster_view["size"]));
    lines.append("Summary: " + str(cluster_view["summary"]));
    lines.append("Recurring signals:");
    for signal in cluster_view["recurring_signals"] {
        lines.append("- " + str(signal));
    }
    lines.append("Representative runs:");
    for run_item in cluster_view["representative_runs"] {
        lines.append(
            "- "
            + str(run_item["run_id"])
            + ": "
            + str(run_item["summary"])
        );
    }
    return truncate_text("\n".join(lines), 2000);
}

def _deterministic_diagnosis(run_view: dict[str, any]) -> dict[str, any] {
    evidence = [];
    for step in run_view["critical_evidence_window"] {
        evidence.append(
            {
                "step_idx": step["idx"],
                "artifact": step["phase"],
                "quote": step["excerpt"],
            }
        );
    }
    failure_class = str(run_view.get("primary_failure") or "UNKNOWN");
    return {
        "run_id": run_view["run_id"],
        "failure_class": failure_class,
        "critical_step_idx": run_view["critical_step_idx"],
        "irreversible_because": diagnosis_reason(failure_class),
        "evidence": evidence,
        "confidence": 0.68 if run_view["critical_step_idx"] >= 0 else 0.2,
        "status": "deterministic_diagnosis",
        "llm_used": False,
        "evidence_pack": _run_evidence_pack(run_view),
    };
}

def _deterministic_cluster_label(cluster_view: dict[str, any]) -> dict[str, any] {
    return {
        "cluster_id": cluster_view["cluster_id"],
        "label": cluster_view["label"],
        "summary": cluster_view["summary"],
        "failure_class": cluster_view["failure_class"],
        "confidence": 0.7,
        "status": "deterministic_cluster_label",
        "llm_used": False,
        "evidence_pack": _cluster_evidence_pack(cluster_view),
    };
}

def _deterministic_patch(root_node: any, cluster_view: dict[str, any]) -> dict[str, any] {
    support_records = _cluster_support_records(root_node, cluster_view);
    rules = _evidence_grounded_rule_records(cluster_view, support_records);
    evidence_lines = _evidence_lines(cluster_view, support_records);
    derivation_mode = "cluster_evidence";
    if any(str(rule.get("provenance") or "") == "fallback_template" for rule in rules) {
        derivation_mode = "fallback_template";
    }
    diff_lines = [
        "--- AGENTS.md",
        "+++ AGENTS.md",
        "@@",
        "+## " + str(cluster_view["label"]),
        "+### Evidence Anchors",
    ];
    if evidence_lines {
        for line in evidence_lines {
            diff_lines.append("+- " + line);
        }
    } else {
        diff_lines.append("+- No representative evidence was available; using recurring cluster signals only.");
    }
    diff_lines.append("+### Rules");
    for rule in rules {
        diff_lines.append("+- " + str(rule["rule_text"]));
    }
    return {
        "cluster_id": cluster_view["cluster_id"],
        "scope": "cluster",
        "cluster_label": cluster_view["label"],
        "summary": "Operational memory patch synthesized from representative runs, critical-step evidence, and recurring cluster signals.",
        "rules": rules,
        "derivation_mode": derivation_mode,
        "supporting_runs": [str(record["run_id"]) for record in support_records],
        "diff_text": "\n".join(diff_lines),
        "confidence": 0.66 if len(rules) > 0 else 0.5,
        "status": "deterministic_patch",
        "llm_used": False,
        "evidence_pack": _cluster_evidence_pack(cluster_view) + "\nEvidence anchors:\n" + "\n".join(evidence_lines),
    };
}

def _store_patch_response(root_node: any, cluster_id: str, response: dict[str, any]) -> dict[str, any] {
    batch_id = cluster_id.split(":")[0];
    compiled = ensure_batch_graph(root_node, batch_id);
    if compiled["batch"] is not None {
        cluster_node = find_cluster_node(compiled["batch"], cluster_id);
        if cluster_node is not None {
            stored = upsert_cluster_patch(
                cluster_node,
                {
                    "patch_id": cluster_id + ":memory_patch",
                    "scope": str(response["scope"]),
                    "title": str(response["cluster_label"]) + " memory patch",
                    "diff_text": str(response["diff_text"]),
                    "confidence": float(response["confidence"]),
                },
            );
            response["stored_patch_id"] = stored["patch_id"];
            response["stored_in_graph"] = True;
            response["stored_patch_created"] = stored["created"];
            return response;
        }
    }
    response["stored_in_graph"] = False;
    return response;
}

def diagnose_run_summary(root_node: any, run_id: str, batch_id: str = "") -> dict[str, any] {
    run_view = run_view_summary(root_node, run_id, batch_id);
    if run_view["status"] == "stub" {
        return {
            "run_id": run_id,
            "status": "missing",
            "message": "Run was not found.",
        };
    }

    fallback = _deterministic_diagnosis(run_view);
    runtime = llm_runtime_status();
    if not runtime["llm_ready"] {
        return _merge_runtime_status(fallback, runtime);
    }

    try {
        predicted = _provider_run_diagnosis(fallback["evidence_pack"], fallback["run_id"]);
        predicted_name = _normalize_failure_class_name(str(predicted["failure_class"]));
        return _merge_runtime_status({
            "run_id": fallback["run_id"],
            "failure_class": predicted_name,
            "critical_step_idx": int(predicted["critical_step_idx"]),
            "irreversible_because": str(predicted["irreversible_because"] or diagnosis_reason(predicted_name)),
            "evidence": list(predicted["evidence"]),
            "evidence_refs": list(predicted["evidence"]),
            "confidence": float(predicted["confidence"]),
            "memory_rule": str(predicted["memory_rule"]),
            "status": "provider_api_diagnosis",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
            "provider": str(predicted["provider"]),
            "model": str(predicted["model"]),
            "latency_ms": float(predicted["latency_ms"]),
            "usage": predicted["usage"],
            "raw_model_text": str(predicted["raw_model_text"]),
        }, runtime);
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return _merge_runtime_status(fallback, runtime);
    }
}

def diagnose_cluster_summary(root_node: any, cluster_id: str) -> dict[str, any] {
    cluster_view = cluster_view_summary(root_node, cluster_id);
    if cluster_view["status"] == "missing" {
        return {
            "cluster_id": cluster_id,
            "status": "missing",
            "message": "Cluster was not found.",
        };
    }

    fallback = _deterministic_cluster_label(cluster_view);
    runtime = llm_runtime_status();
    if not runtime["llm_ready"] {
        return _merge_runtime_status(fallback, runtime);
    }

    try {
        labeled = _provider_cluster_label(fallback["evidence_pack"]);
        return _merge_runtime_status({
            "cluster_id": cluster_id,
            "label": str(labeled["label"]),
            "summary": str(labeled["summary"]),
            "failure_class": cluster_view["failure_class"],
            "confidence": float(labeled["confidence"]),
            "status": "provider_api_cluster_label",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
            "provider": str(labeled["provider"]),
            "model": str(labeled["model"]),
            "latency_ms": float(labeled["latency_ms"]),
            "usage": labeled["usage"],
            "raw_model_text": str(labeled["raw_model_text"]),
        }, runtime);
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return _merge_runtime_status(fallback, runtime);
    }
}

def compile_memory_patch_summary(root_node: any, cluster_id: str) -> dict[str, any] {
    cluster_view = cluster_view_summary(root_node, cluster_id);
    if cluster_view["status"] == "missing" {
        return {
            "cluster_id": cluster_id,
            "status": "missing",
            "message": "Cluster was not found.",
        };
    }

    fallback = _deterministic_patch(root_node, cluster_view);
    runtime = llm_runtime_status();
    if not runtime["llm_ready"] {
        return _store_patch_response(root_node, cluster_id, _merge_runtime_status(fallback, runtime));
    }

    try {
        proposal = _provider_memory_patch(fallback["evidence_pack"]);
        output_rules = list(proposal["rules"]);
        max_confidence = 0.64;
        for rule in output_rules {
            rule_confidence = float(rule.get("confidence") or 0.0);
            if rule_confidence > max_confidence {
                max_confidence = rule_confidence;
            }
        }

        chosen_diff_text = str(proposal["diff_text"]);
        if not chosen_diff_text {
            chosen_diff_text = fallback["diff_text"];
        }
        chosen_cluster_label = str(proposal["cluster_label"]);
        if not chosen_cluster_label {
            chosen_cluster_label = cluster_view["label"];
        }

        llm_response = _merge_runtime_status({
            "cluster_id": cluster_id,
            "scope": str(proposal["scope"] or "cluster"),
            "cluster_label": chosen_cluster_label,
            "summary": str(proposal["summary"]),
            "rules": output_rules if output_rules else fallback["rules"],
            "diff_text": chosen_diff_text,
            "confidence": max_confidence,
            "status": "provider_api_patch",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
            "derivation_mode": "provider_synthesis",
            "supporting_runs": list(fallback.get("supporting_runs") or []),
            "provider": str(proposal["provider"]),
            "model": str(proposal["model"]),
            "latency_ms": float(proposal["latency_ms"]),
            "usage": proposal["usage"],
            "raw_model_text": str(proposal["raw_model_text"]),
        }, runtime);
        return _store_patch_response(root_node, cluster_id, llm_response);
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return _store_patch_response(root_node, cluster_id, _merge_runtime_status(fallback, runtime));
    }
}

import from os { getenv }
import from traceforge.analysis { cluster_view_summary, run_view_summary }
import from traceforge.graph_build {
    ensure_batch_graph,
    failure_class_name,
    find_cluster_node,
    upsert_cluster_patch
}
import from traceforge.parser { truncate_text }
import from traceforge.schema { ClusterLabel, ComparisonVerdict, FailureClass, MemoryPatchProposal, RunDiagnosis }

def choose_failure_class(text: str) -> FailureClass by llm();

def draft_cluster_label(text: str) -> ClusterLabel by llm();

def draft_memory_patch(text: str) -> MemoryPatchProposal by llm();

def propose_run_diagnosis(text: str) -> RunDiagnosis by llm();

def compare_run_diagnoses(text: str) -> ComparisonVerdict by llm();

def llm_enabled() -> bool {
    return str(getenv("OPENAI_API_KEY") or "") != "";
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

def _deterministic_patch(cluster_view: dict[str, any]) -> dict[str, any] {
    rules = cluster_rule_lines(str(cluster_view["failure_class"]));
    diff_lines = [
        "--- AGENTS.md",
        "+++ AGENTS.md",
        "@@",
        "+## " + str(cluster_view["label"]),
    ];
    for rule in rules {
        diff_lines.append("+- " + rule);
    }
    return {
        "cluster_id": cluster_view["cluster_id"],
        "scope": "cluster",
        "cluster_label": cluster_view["label"],
        "summary": "Operational memory patch synthesized from the current cluster motif.",
        "rules": [
            {
                "title": str(cluster_view["label"]) + " rule " + str(index + 1),
                "rationale": diagnosis_reason(str(cluster_view["failure_class"])),
                "rule_text": rule,
                "supported_by_steps": [],
                "confidence": 0.64,
            }
            for (index, rule) in enumerate(rules)
        ],
        "diff_text": "\n".join(diff_lines),
        "confidence": 0.64,
        "status": "deterministic_patch",
        "llm_used": False,
        "evidence_pack": _cluster_evidence_pack(cluster_view),
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
    if not llm_enabled() {
        return fallback;
    }

    try {
        predicted = choose_failure_class(fallback["evidence_pack"]);
        predicted_name = failure_class_name(predicted);
        return {
            "run_id": fallback["run_id"],
            "failure_class": predicted_name,
            "critical_step_idx": fallback["critical_step_idx"],
            "irreversible_because": diagnosis_reason(predicted_name),
            "evidence": fallback["evidence"],
            "confidence": 0.8 if fallback["critical_step_idx"] >= 0 else 0.35,
            "status": "llm_validated_diagnosis",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
        };
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return fallback;
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
    if not llm_enabled() {
        return fallback;
    }

    try {
        labeled = draft_cluster_label(fallback["evidence_pack"]);
        return {
            "cluster_id": cluster_id,
            "label": labeled.label,
            "summary": labeled.summary,
            "failure_class": cluster_view["failure_class"],
            "confidence": labeled.confidence,
            "status": "llm_cluster_label",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
        };
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return fallback;
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

    fallback = _deterministic_patch(cluster_view);
    if not llm_enabled() {
        return _store_patch_response(root_node, cluster_id, fallback);
    }

    try {
        proposal = draft_memory_patch(fallback["evidence_pack"]);
        output_rules = [];
        max_confidence = 0.64;
        for rule in proposal.rules {
            rule_confidence = float(rule.confidence);
            if rule_confidence > max_confidence {
                max_confidence = rule_confidence;
            }
            output_rules.append(
                {
                    "title": rule.title,
                    "rationale": rule.rationale,
                    "rule_text": rule.rule_text,
                    "supported_by_steps": rule.supported_by_steps,
                    "confidence": rule.confidence,
                }
            );
        }

        chosen_diff_text = proposal.diff_text;
        if not chosen_diff_text {
            chosen_diff_text = fallback["diff_text"];
        }
        chosen_cluster_label = proposal.cluster_label;
        if not chosen_cluster_label {
            chosen_cluster_label = cluster_view["label"];
        }

        llm_response = {
            "cluster_id": cluster_id,
            "scope": proposal.scope or "cluster",
            "cluster_label": chosen_cluster_label,
            "summary": proposal.summary,
            "rules": output_rules if output_rules else fallback["rules"],
            "diff_text": chosen_diff_text,
            "confidence": max_confidence,
            "status": "llm_patch",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
        };
        return _store_patch_response(root_node, cluster_id, llm_response);
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return _store_patch_response(root_node, cluster_id, fallback);
    }
}

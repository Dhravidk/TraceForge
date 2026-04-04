import json;
import from pathlib { Path }
import from traceforge.analysis { batch_overview_summary, run_view_summary }
import from traceforge.critical { localize_critical_step }
import from traceforge.features { compute_run_fingerprint, dominant_failure_label }
import from traceforge.graph_build { failure_class_name }
import from traceforge.llm_ops {
    cluster_rule_lines,
    compare_run_diagnoses,
    diagnosis_reason,
    llm_enabled,
    propose_run_diagnosis
}
import from traceforge.parser { hash_text, parse_run, step_text, truncate_text }

def _pack_token_estimate(text: str) -> int {
    if not text {
        return 0;
    }
    return max(len(text) // 4, 1);
}

def _specificity_label(evidence_count: int, critical_step_idx: int, pack_mode: str) -> str {
    if critical_step_idx < 0 and evidence_count <= 1 {
        return "low";
    }
    if pack_mode == "traceforge_retrieval_prompt" and evidence_count >= 2 and critical_step_idx >= 0 {
        return "high";
    }
    return "medium";
}

def _normalize_failure_class(name: str) -> str {
    if not name {
        return "UNKNOWN";
    }
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
    if name in allowed {
        return name;
    }
    upper_name = name.upper();
    if upper_name in allowed {
        return upper_name;
    }
    return "UNKNOWN";
}

def _raw_turn_lines(parsed_run: any, max_turns: int = 120) -> list[str] {
    lines: list[str] = [];
    shown_turns = parsed_run.turns[: max_turns];
    for turn in shown_turns {
        if not turn.content and not turn.role {
            continue;
        }
        lines.append(
            "Turn "
            + str(turn.index)
            + " ["
            + str(turn.role).upper()
            + "]\n"
            + str(turn.content),
        );
    }
    if len(parsed_run.turns) > len(shown_turns) {
        lines.append(
            "... "
            + str(len(parsed_run.turns) - len(shown_turns))
            + " additional turns omitted from this raw prompt pack."
        );
    }
    return lines;
}

def _step_window_lines(parsed_run: any, center_idx: int, radius: int = 1) -> list[str] {
    if center_idx < 0 or center_idx >= len(parsed_run.steps) {
        return [];
    }
    lines: list[str] = [];
    start = max(center_idx - radius, 0);
    stop = min(center_idx + radius, len(parsed_run.steps) - 1);
    for index=start to index<=stop by index+=1 {
        lines.append(
            "Step "
            + str(index)
            + " ["
            + str(parsed_run.steps[index].phase)
            + "]\n"
            + step_text(parsed_run.steps[index]),
        );
    }
    return lines;
}

def _exact_evidence_refs(parsed_run: any, critical_step_idx: int, limit: int = 3) -> list[dict[str, any]] {
    evidence: list[dict[str, any]] = [];
    if critical_step_idx < 0 {
        return evidence;
    }
    start = max(critical_step_idx - 1, 0);
    stop = min(critical_step_idx + 1, len(parsed_run.steps) - 1);
    for index=start to index<=stop by index+=1 {
        if len(evidence) >= limit {
            break;
        }
        evidence.append(
            {
                "step_idx": index,
                "artifact": str(parsed_run.steps[index].phase),
                "quote": truncate_text(step_text(parsed_run.steps[index]), 500),
            }
        );
    }
    return evidence;
}

def _first_interesting_step(parsed_run: any) -> int {
    for (index, step) in enumerate(parsed_run.steps) {
        lower = step_text(step).lower();
        if "traceback" in lower or "error" in lower or "exception" in lower or "failed" in lower {
            return index;
        }
    }
    for (index, step) in enumerate(parsed_run.steps) {
        lower = step_text(step).lower();
        if "submit" in lower or "final" in lower {
            return index;
        }
    }
    if len(parsed_run.steps) > 0 {
        return 0;
    }
    return -1;
}

def _raw_baseline_pack(parsed_run: any, run_view: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge raw trajectory baseline pack");
    lines.append("Task: Review this coding-agent run directly from the raw trajectory without external summaries.");
    lines.append("Return a typed RunDiagnosis using only the transcript below.");
    lines.append("If the run never really started, return UNKNOWN and critical_step_idx = -1.");
    lines.append("Run ID: " + str(run_view["run_id"]));
    lines.append("Source path: " + str(run_view["source_path"]));
    lines.append("Transcript:");
    lines.extend(_raw_turn_lines(parsed_run));
    return truncate_text("\n\n".join(lines), 14000);
}

def _structured_retrieval_pack(parsed_run: any, run_view: dict[str, any]) -> str {
    fingerprint = compute_run_fingerprint(parsed_run);
    critical = localize_critical_step(parsed_run, fingerprint);
    candidate_scores = sorted(
        critical["candidate_scores"],
        key=lambda item: any -> any : (-float(item["score"]), int(item["step_idx"])),
    );

    lines: list[str] = [];
    lines.append("TraceForge structured retrieval pack");
    lines.append("Task: Diagnose the run using retrieved exact evidence spans plus graph context.");
    lines.append("Return a typed RunDiagnosis using only the evidence in this pack.");
    lines.append("Run ID: " + str(run_view["run_id"]));
    lines.append("Task title: " + str(run_view["task_title"]));
    lines.append("Primary deterministic family: " + str(run_view["primary_failure"]));
    lines.append("Graph-linked clusters: " + str(run_view["artifacts"]["cluster_ids"]));
    lines.append("Top files: " + str(run_view["artifacts"]["fingerprint"].get("top_files", [])));
    lines.append("Top errors: " + str(run_view["artifacts"]["fingerprint"].get("top_error_keywords", [])));
    lines.append("Top tests: " + str(run_view["artifacts"]["fingerprint"].get("top_test_names", [])));
    lines.append("Retrieved evidence windows:");

    shown_candidates = candidate_scores[:3];
    for candidate in shown_candidates {
        lines.append(
            "Candidate step "
            + str(candidate["step_idx"])
            + " score "
            + str(candidate["score"])
        );
        for window_line in _step_window_lines(parsed_run, int(candidate["step_idx"])) {
            lines.append(window_line);
        }
    }

    if len(shown_candidates) == 0 and len(parsed_run.steps) > 0 {
        for window_line in _step_window_lines(parsed_run, 0) {
            lines.append(window_line);
        }
    }

    lines.append("Exact final-step context:");
    if len(parsed_run.steps) > 0 {
        for window_line in _step_window_lines(parsed_run, len(parsed_run.steps) - 1, 0) {
            lines.append(window_line);
        }
    } else {
        lines.append("No agent decision steps were recorded.");
    }

    return truncate_text("\n\n".join(lines), 12000);
}

def _diagnosis_to_dict(
    run_id: str,
    diagnosis: any,
    pack_mode: str,
    prompt_pack: str,
    llm_used: bool,
    status: str,
) -> dict[str, any] {
    failure_class = _normalize_failure_class(failure_class_name(diagnosis.failure_class));
    evidence = [];
    for item in diagnosis.evidence {
        evidence.append(
            {
                "step_idx": int(item.step_idx),
                "artifact": str(item.artifact),
                "quote": str(item.quote),
            }
        );
    }
    rule_lines = cluster_rule_lines(failure_class);
    chosen_rule = "";
    if len(rule_lines) > 0 {
        chosen_rule = rule_lines[0];
    }
    return {
        "run_id": run_id,
        "mode": pack_mode,
        "failure_class": failure_class,
        "critical_step_idx": int(diagnosis.critical_step_idx),
        "irreversible_because": str(diagnosis.irreversible_because),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": float(diagnosis.confidence),
        "memory_rule": chosen_rule,
        "llm_used": llm_used,
        "status": status,
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), int(diagnosis.critical_step_idx), pack_mode),
    };
}

def _fallback_raw_diagnosis(run_view: dict[str, any], parsed_run: any, prompt_pack: str) -> dict[str, any] {
    raw_step = _first_interesting_step(parsed_run);
    failure_class = _normalize_failure_class(str(run_view.get("primary_failure") or "UNKNOWN"));
    if len(parsed_run.steps) == 0 {
        failure_class = "UNKNOWN";
        raw_step = -1;
    }
    evidence = [];
    if raw_step >= 0 {
        evidence.append(
            {
                "step_idx": raw_step,
                "artifact": str(parsed_run.steps[raw_step].phase),
                "quote": truncate_text(step_text(parsed_run.steps[raw_step]), 500),
            }
        );
    } else {
        evidence.append(
            {
                "step_idx": -1,
                "artifact": "run_status",
                "quote": str(run_view["summary"]),
            }
        );
    }
    rule_lines = cluster_rule_lines(failure_class);
    chosen_rule = "";
    if len(rule_lines) > 0 {
        chosen_rule = rule_lines[0];
    }
    return {
        "run_id": run_view["run_id"],
        "mode": "raw_transcript_prompt",
        "failure_class": failure_class,
        "critical_step_idx": raw_step,
        "irreversible_because": diagnosis_reason(failure_class),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": 0.42 if raw_step >= 0 else 0.18,
        "memory_rule": chosen_rule,
        "llm_used": False,
        "status": "deterministic_raw_diagnosis",
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), raw_step, "raw_transcript_prompt"),
    };
}

def _fallback_structured_diagnosis(run_view: dict[str, any], parsed_run: any, prompt_pack: str) -> dict[str, any] {
    failure_class = _normalize_failure_class(str(run_view.get("primary_failure") or dominant_failure_label(run_view["artifacts"]["fingerprint"])));
    critical_step_idx = int(run_view["critical_step_idx"]);
    evidence = _exact_evidence_refs(parsed_run, critical_step_idx);
    if len(evidence) == 0 {
        evidence.append(
            {
                "step_idx": critical_step_idx,
                "artifact": "summary",
                "quote": str(run_view["summary"]),
            }
        );
    }
    rule_lines = cluster_rule_lines(failure_class);
    chosen_rule = "";
    if len(rule_lines) > 0 {
        chosen_rule = rule_lines[0];
    }
    return {
        "run_id": run_view["run_id"],
        "mode": "traceforge_retrieval_prompt",
        "failure_class": failure_class,
        "critical_step_idx": critical_step_idx,
        "irreversible_because": diagnosis_reason(failure_class),
        "evidence": evidence,
        "evidence_refs": evidence,
        "confidence": 0.7 if critical_step_idx >= 0 else 0.25,
        "memory_rule": chosen_rule,
        "llm_used": False,
        "status": "deterministic_structured_diagnosis",
        "prompt_pack": prompt_pack,
        "pack_token_estimate": _pack_token_estimate(prompt_pack),
        "specificity": _specificity_label(len(evidence), critical_step_idx, "traceforge_retrieval_prompt"),
    };
}

def _llm_diagnosis(prompt_pack: str, run_view: dict[str, any], pack_mode: str) -> dict[str, any] {
    diagnosis = propose_run_diagnosis(prompt_pack);
    return _diagnosis_to_dict(
        str(run_view["run_id"]),
        diagnosis,
        pack_mode,
        prompt_pack,
        True,
        "llm_run_diagnosis",
    );
}

def _blind_assignment(run_id: str, batch_id: str) -> dict[str, str] {
    digest = hash_text(batch_id + ":" + run_id);
    even = int(digest[0], 16) % 2 == 0;
    if even {
        return {
            "A": "baseline",
            "B": "structured",
        };
    }
    return {
        "A": "structured",
        "B": "baseline",
    };
}

def _blinded_arms(baseline: dict[str, any], structured: dict[str, any], assignment: dict[str, str]) -> dict[str, any] {
    arm_a = baseline;
    arm_b = structured;
    if assignment["A"] == "structured" {
        arm_a = structured;
        arm_b = baseline;
    }
    return {
        "assignment": assignment,
        "arm_a": {
            "failure_class": arm_a["failure_class"],
            "critical_step_idx": arm_a["critical_step_idx"],
            "irreversible_because": arm_a["irreversible_because"],
            "evidence_refs": arm_a["evidence_refs"],
            "memory_rule": arm_a["memory_rule"],
            "confidence": arm_a["confidence"],
        },
        "arm_b": {
            "failure_class": arm_b["failure_class"],
            "critical_step_idx": arm_b["critical_step_idx"],
            "irreversible_because": arm_b["irreversible_because"],
            "evidence_refs": arm_b["evidence_refs"],
            "memory_rule": arm_b["memory_rule"],
            "confidence": arm_b["confidence"],
        },
    };
}

def _deterministic_verdict(
    run_view: dict[str, any],
    baseline: dict[str, any],
    structured: dict[str, any],
    assignment: dict[str, str],
) -> dict[str, any] {
    raw_score = 0.0;
    structured_score = 0.0;

    if baseline["critical_step_idx"] >= 0 {
        raw_score += 1.0;
    }
    if structured["critical_step_idx"] >= 0 {
        structured_score += 1.0;
    }
    raw_score += min(len(baseline["evidence_refs"]) * 0.2, 0.6);
    structured_score += min(len(structured["evidence_refs"]) * 0.2, 0.6);
    if baseline["failure_class"] != "UNKNOWN" {
        raw_score += 0.4;
    }
    if structured["failure_class"] != "UNKNOWN" {
        structured_score += 0.4;
    }
    if len(run_view["artifacts"]["cluster_ids"]) > 0 {
        structured_score += 0.3;
    }

    winner = "tie";
    if structured_score > raw_score {
        winner = "structured";
    } elif raw_score > structured_score {
        winner = "baseline";
    }

    blinded_winner = "tie";
    if winner == "baseline" {
        blinded_winner = "A" if assignment["A"] == "baseline" else "B";
    } elif winner == "structured" {
        blinded_winner = "A" if assignment["A"] == "structured" else "B";
    }

    return {
        "winner": winner,
        "blinded_winner": blinded_winner,
        "raw_score": round(raw_score, 4),
        "structured_score": round(structured_score, 4),
        "evidence_validity_winner": "structured" if len(structured["evidence_refs"]) >= len(baseline["evidence_refs"]) else "baseline",
        "pivot_quality_winner": "structured" if structured["critical_step_idx"] >= baseline["critical_step_idx"] else "baseline",
        "specificity_winner": "structured" if structured["specificity"] != baseline["specificity"] else "tie",
        "actionability_winner": "structured" if structured["memory_rule"] else ("baseline" if baseline["memory_rule"] else "tie"),
        "hallucination_winner": "structured" if baseline["critical_step_idx"] < 0 and structured["critical_step_idx"] >= 0 else "tie",
        "rationale": "Deterministic proxy verdict prefers the arm with stronger evidence refs, a localized pivot step, and cluster-grounded context.",
        "llm_used": False,
        "status": "deterministic_proxy_verdict",
    };
}

def _verifier_pack(run_view: dict[str, any], blinded: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge blinded comparison verifier pack");
    lines.append("Judge which arm is better on evidence validity, pivot quality, specificity, actionability, and hallucination avoidance.");
    lines.append("Return a typed ComparisonVerdict. Winner must be A, B, or tie.");
    lines.append("Run summary: " + str(run_view["summary"]));
    lines.append("Arm A:");
    lines.append(json.dumps(blinded["arm_a"]));
    lines.append("Arm B:");
    lines.append(json.dumps(blinded["arm_b"]));
    return truncate_text("\n".join(lines), 12000);
}

def _llm_verdict(run_view: dict[str, any], blinded: dict[str, any], assignment: dict[str, str]) -> dict[str, any] {
    verifier_pack = _verifier_pack(run_view, blinded);
    verdict = compare_run_diagnoses(verifier_pack);
    winner = str(verdict.winner or "tie").lower();
    if winner == "a" {
        winner = assignment["A"];
    } elif winner == "b" {
        winner = assignment["B"];
    } elif winner not in {"baseline", "structured", "tie"} {
        winner = "tie";
    }
    blinded_winner = "tie";
    if winner == "baseline" {
        blinded_winner = "A" if assignment["A"] == "baseline" else "B";
    } elif winner == "structured" {
        blinded_winner = "A" if assignment["A"] == "structured" else "B";
    }
    return {
        "winner": winner,
        "blinded_winner": blinded_winner,
        "raw_score": float(verdict.raw_score),
        "structured_score": float(verdict.structured_score),
        "evidence_validity_winner": str(verdict.evidence_validity_winner),
        "pivot_quality_winner": str(verdict.pivot_quality_winner),
        "specificity_winner": str(verdict.specificity_winner),
        "actionability_winner": str(verdict.actionability_winner),
        "hallucination_winner": str(verdict.hallucination_winner),
        "rationale": str(verdict.rationale),
        "llm_used": True,
        "status": "llm_blinded_verdict",
        "verifier_pack": verifier_pack,
    };
}

def _baseline_blind_spots(baseline: dict[str, any]) -> list[str] {
    blind_spots = [
        "The baseline sees raw trajectory text only and gets no graph cluster context.",
        "The baseline does not get pre-ranked critical-step candidates.",
    ];
    if baseline["critical_step_idx"] < 0 {
        blind_spots.append("The baseline did not localize a concrete pivot step.");
    }
    return blind_spots;
}

def _structured_support_points(run_view: dict[str, any], structured: dict[str, any]) -> list[str] {
    points: list[str] = [];
    points.append("Retrieved exact evidence refs: " + str(len(structured["evidence_refs"])) + ".");
    if structured["critical_step_idx"] >= 0 {
        points.append("Critical step localized at step " + str(structured["critical_step_idx"]) + ".");
    }
    if run_view["artifacts"]["fingerprint"].get("top_files", []) {
        points.append("Top files: " + str(run_view["artifacts"]["fingerprint"].get("top_files", [])[:3]) + ".");
    }
    if len(run_view["artifacts"]["cluster_ids"]) > 0 {
        points.append("Cluster context: " + str(run_view["artifacts"]["cluster_ids"][:2]) + ".");
    }
    if structured["memory_rule"] {
        points.append("Operational memory rule synthesized: " + structured["memory_rule"]);
    }
    return points;
}

def compare_run_harness_summary(root_node: any, run_id: str, batch_id: str = "") -> dict[str, any] {
    run_view = run_view_summary(root_node, run_id, batch_id);
    if run_view["status"] == "stub" {
        return {
            "run_id": run_id,
            "status": "missing",
            "message": "Run was not found.",
        };
    }

    target_batch_id = batch_id;
    if not target_batch_id and len(run_view["artifacts"]["cluster_ids"]) > 0 {
        target_batch_id = str(run_view["artifacts"]["cluster_ids"][0]).split(":")[0];
    }
    parsed_run = parse_run(run_view["source_path"], run_id);
    raw_pack = _raw_baseline_pack(parsed_run, run_view);
    structured_pack = _structured_retrieval_pack(parsed_run, run_view);

    baseline = _fallback_raw_diagnosis(run_view, parsed_run, raw_pack);
    structured = _fallback_structured_diagnosis(run_view, parsed_run, structured_pack);

    if llm_enabled() {
        try {
            baseline = _llm_diagnosis(raw_pack, run_view, "raw_transcript_prompt");
        } except Exception as err {
            baseline["llm_error"] = str(err);
        }
        try {
            structured = _llm_diagnosis(structured_pack, run_view, "traceforge_retrieval_prompt");
        } except Exception as err {
            structured["llm_error"] = str(err);
        }
    }

    assignment = _blind_assignment(run_id, target_batch_id or run_id);
    blinded = _blinded_arms(baseline, structured, assignment);

    verdict = _deterministic_verdict(run_view, baseline, structured, assignment);
    comparison_mode = "deterministic_proxy";
    if llm_enabled() {
        try {
            verdict = _llm_verdict(run_view, blinded, assignment);
            comparison_mode = "same_model_blinded";
        } except Exception as err {
            verdict["llm_error"] = str(err);
        }
    }

    why_better = "Structured retrieval narrows the search to exact evidence spans, adds cluster context, and still returns the same diagnosis schema as the raw baseline.";
    if verdict["winner"] == "baseline" {
        why_better = "The raw transcript arm won this case under the current verifier rubric.";
    } elif verdict["winner"] == "tie" {
        why_better = "Neither arm separated clearly under the current verifier rubric.";
    }

    return {
        "run_id": run_id,
        "batch_id": target_batch_id,
        "comparison_mode": comparison_mode,
        "baseline": {
            "mode": baseline["mode"],
            "diagnosis": baseline["irreversible_because"],
            "compressed_trajectory": raw_pack,
            "raw_packet": raw_pack,
            "failure_class": baseline["failure_class"],
            "critical_step_idx": baseline["critical_step_idx"],
            "evidence_refs": baseline["evidence_refs"],
            "memory_rule": baseline["memory_rule"],
            "specificity": baseline["specificity"],
            "blind_spots": _baseline_blind_spots(baseline),
            "pack_token_estimate": baseline["pack_token_estimate"],
            "llm_used": baseline["llm_used"],
            "status": baseline["status"],
        },
        "structured": {
            "mode": structured["mode"],
            "failure_class": structured["failure_class"],
            "critical_step_idx": structured["critical_step_idx"],
            "diagnosis": structured["irreversible_because"],
            "evidence_window": run_view["critical_evidence_window"],
            "evidence_refs": structured["evidence_refs"],
            "memory_rule": structured["memory_rule"],
            "support_points": _structured_support_points(run_view, structured),
            "specificity": structured["specificity"],
            "pack_token_estimate": structured["pack_token_estimate"],
            "why_better": why_better,
            "llm_used": structured["llm_used"],
            "status": structured["status"],
            "prompt_pack": structured_pack,
        },
        "verifier": verdict,
        "blinded": blinded,
        "delta": {
            "critical_step_localized": structured["critical_step_idx"] >= 0,
            "cluster_context_added": len(run_view["artifacts"]["cluster_ids"]) > 0,
            "artifact_context_added": len(run_view["artifacts"]["fingerprint"].get("top_files", [])) > 0,
            "baseline_pack_token_estimate": baseline["pack_token_estimate"],
            "structured_pack_token_estimate": structured["pack_token_estimate"],
        },
        "status": "comparison_ready",
    };
}

def export_blinded_eval_summary(
    root_node: any,
    batch_id: str,
    limit: int = 10,
    substantive_only: bool = True,
) -> dict[str, any] {
    overview = batch_overview_summary(root_node, batch_id);
    if overview["status"] == "missing" {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }

    selected_runs: list[str] = [];
    for run_item in overview["runs"] {
        if substantive_only and int(run_item["step_count"]) <= 0 {
            continue;
        }
        selected_runs.append(str(run_item["run_id"]));
        if len(selected_runs) >= limit {
            break;
        }
    }
    if len(selected_runs) == 0 {
        selected_runs = [str(run_item["run_id"]) for run_item in overview["runs"][: max(limit, 0)]];
    }

    comparisons: list[dict[str, any]] = [];
    blind_key: dict[str, any] = {};
    blinded_lines: list[str] = [
        "# TraceForge Blinded Evaluation Sheet",
        "",
        "- Batch ID: `" + batch_id + "`",
        "- Comparison mode: same-model blinded when API key is present, deterministic proxy otherwise",
        "- Selected runs: " + str(len(selected_runs)),
        "",
        "Score each case on evidence validity, pivot quality, specificity, actionability, and hallucination avoidance.",
        "",
    ];

    for run_id in selected_runs {
        comparison = compare_run_harness_summary(root_node, run_id, batch_id);
        comparisons.append(comparison);
        blind_key[run_id] = comparison["blinded"]["assignment"];

        blinded_lines.append("## Run `" + run_id + "`");
        blinded_lines.append("");
        blinded_lines.append("### Arm A");
        blinded_lines.append("");
        blinded_lines.append("```json");
        blinded_lines.append(json.dumps(comparison["blinded"]["arm_a"], indent=2));
        blinded_lines.append("```");
        blinded_lines.append("");
        blinded_lines.append("### Arm B");
        blinded_lines.append("");
        blinded_lines.append("```json");
        blinded_lines.append(json.dumps(comparison["blinded"]["arm_b"], indent=2));
        blinded_lines.append("```");
        blinded_lines.append("");
        blinded_lines.append("### Rubric");
        blinded_lines.append("- Evidence validity winner: ____");
        blinded_lines.append("- Pivot quality winner: ____");
        blinded_lines.append("- Specificity winner: ____");
        blinded_lines.append("- Actionability winner: ____");
        blinded_lines.append("- Hallucination winner: ____");
        blinded_lines.append("- Overall winner: ____");
        blinded_lines.append("");
    }

    export_dir = Path("exports/evals");
    export_dir.mkdir(parents=True, exist_ok=True);
    blind_md_path = export_dir.joinpath(batch_id + "_blind.md");
    blind_key_path = export_dir.joinpath(batch_id + "_blind_key.json");
    summary_json_path = export_dir.joinpath(batch_id + "_comparison.json");

    blind_md_text = "\n".join(blinded_lines).strip() + "\n";
    blind_md_path.write_text(blind_md_text, encoding="utf-8");
    blind_key_path.write_text(json.dumps(blind_key, indent=2) + "\n", encoding="utf-8");
    summary_json_path.write_text(json.dumps(comparisons, indent=2) + "\n", encoding="utf-8");

    return {
        "batch_id": batch_id,
        "status": "exported",
        "selected_run_count": len(selected_runs),
        "comparison_mode": comparisons[0]["comparison_mode"] if len(comparisons) > 0 else "deterministic_proxy",
        "blind_sheet_path": str(blind_md_path),
        "blind_key_path": str(blind_key_path),
        "summary_json_path": str(summary_json_path),
        "preview": truncate_text(blind_md_text, 1200),
    };
}

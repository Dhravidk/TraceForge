import from traceforge.ingest {
    batch_files,
    batch_id_for_run,
    run_source_path
}
import from traceforge.schema { Batch, Cluster, Run, Step }
import from traceforge.features { summarize_counts }
import from traceforge.graph_build {
    ensure_batch_graph,
    failure_class_name,
    find_batch_for_run,
    find_batch_node,
    find_cluster_node,
    find_run_node,
    list_batch_clusters,
    list_cluster_patches,
    list_batch_runs,
    list_run_clusters,
    list_run_hypotheses,
    list_run_steps,
    list_step_errors,
    list_step_files,
    list_step_patches,
    list_step_tests,
    remembered_cluster_patch_ids,
    run_graph_stats,
    step_kind_name
}

def _run_exists_in_batch(batch_id: str, run_id: str) -> bool {
    for path in batch_files(batch_id) {
        if path.endswith("/" + run_id + ".traj.json") or path.endswith("\\" + run_id + ".traj.json") or path.endswith(run_id + ".traj.json") {
            return True;
        }
    }
    return False;
}

def _ensure_graph_for_run(root_node: any, run_id: str, batch_id: str = "") -> any {
    if batch_id {
        batch_node = find_batch_node(root_node, batch_id);
        if batch_node is not None {
            for scoped_run in list_batch_runs(batch_node) {
                if scoped_run.run_id == run_id {
                    return scoped_run;
                }
            }
        }
        if _run_exists_in_batch(batch_id, run_id) {
            ensure_batch_graph(root_node, batch_id);
            batch_node = find_batch_node(root_node, batch_id);
            if batch_node is not None {
                for scoped_run in list_batch_runs(batch_node) {
                    if scoped_run.run_id == run_id {
                        return scoped_run;
                    }
                }
            }
        }
    }

    run_node = find_run_node(root_node, run_id);
    if run_node is not None {
        return run_node;
    }
    batch_id = batch_id_for_run(run_id);
    if batch_id and run_source_path(run_id) {
        ensure_batch_graph(root_node, batch_id);
        return find_run_node(root_node, run_id);
    }
    return None;
}

def _timeline_from_run(run_node: Run) -> list[dict[str, any]] {
    timeline: list[dict[str, any]] = [];
    for step_node in list_run_steps(run_node) {
        timeline.append(
            {
                "idx": step_node.idx,
                "kind": step_kind_name(step_node.kind),
                "phase": step_node.phase,
                "excerpt": step_node.excerpt,
                "touched_files": [file_node.path for file_node in list_step_files(step_node)],
                "has_patch": len(list_step_patches(step_node)) > 0,
                "has_test": len(list_step_tests(step_node)) > 0,
                "has_error": len(list_step_errors(step_node)) > 0,
                "repeated": step_node.repeated,
            }
        );
    }
    return timeline;
}

def _critical_window(timeline: list[dict[str, any]], critical_step_idx: int, radius: int = 1) -> list[dict[str, any]] {
    if critical_step_idx < 0 {
        return [];
    }
    start = max(critical_step_idx - radius, 0);
    stop = min(critical_step_idx + radius, len(timeline) - 1);
    window: list[dict[str, any]] = [];
    for index=start to index<=stop by index+=1 {
        window.append(timeline[index]);
    }
    return window;
}

def _hypothesis_list(run_node: Run) -> list[dict[str, any]] {
    output: list[dict[str, any]] = [];
    for hypothesis in list_run_hypotheses(run_node) {
        output.append(
            {
                "label": failure_class_name(hypothesis.label),
                "score": hypothesis.score,
                "rationale": hypothesis.rationale,
            }
        );
    }
    return sorted(output, key=lambda item: any -> any : (-item["score"], item["label"]));
}

def _run_summary_from_node(run_node: Run) -> dict[str, any] {
    timeline = _timeline_from_run(run_node);
    primary_failure = failure_class_name(run_node.primary_failure);
    return {
        "run_id": run_node.run_id,
        "task_title": run_node.task_title,
        "source_path": run_node.raw_path,
        "summary": run_node.summary,
        "primary_failure": primary_failure,
        "critical_step_idx": run_node.critical_step_idx,
        "critical_evidence_window": _critical_window(timeline, run_node.critical_step_idx),
        "timeline": timeline,
        "artifacts": {
            "turn_count": len(timeline),
            "metadata": run_node.metadata,
            "fingerprint": run_node.fingerprint,
            "graph_preview": run_graph_stats(run_node),
            "failure_hypotheses": _hypothesis_list(run_node),
            "cluster_ids": [cluster_node.cluster_id for cluster_node in list_run_clusters(run_node)],
        },
        "status": "graph_backed",
    };
}

def _cluster_run_nodes(batch: Batch, cluster_id: str) -> list[Run] {
    return sorted(
        [run_node for run_node in list_batch_runs(batch) if run_node.cluster_id == cluster_id],
        key=lambda item: any -> any : item.run_id,
    );
}

def _cluster_summary_from_node(batch: Batch, cluster_node: Cluster) -> dict[str, any] {
    cluster_runs = _cluster_run_nodes(batch, cluster_node.cluster_id);
    stored_patches = list_cluster_patches(cluster_node);
    stored_patch_ids = remembered_cluster_patch_ids(cluster_node.cluster_id);
    if not stored_patch_ids {
        stored_patch_ids = [patch_node.patch_id for patch_node in stored_patches];
    }
    recurring_files_raw: list[str] = [];
    recurring_errors_raw: list[str] = [];
    recurring_tests_raw: list[str] = [];
    representative_runs: list[dict[str, any]] = [];
    medoid = {};
    for run_node in cluster_runs {
        recurring_files_raw.extend(run_node.fingerprint.get("top_files", []));
        recurring_errors_raw.extend(run_node.fingerprint.get("top_error_keywords", []));
        recurring_tests_raw.extend(run_node.fingerprint.get("top_test_names", []));
        run_card = {
            "run_id": run_node.run_id,
            "task_title": run_node.task_title,
            "summary": run_node.summary,
            "critical_step_idx": run_node.critical_step_idx,
        };
        representative_runs.append(run_card);
        if run_node.run_id == cluster_node.medoid_run_id {
            medoid = run_card;
        }
    }

    recurring_signals: list[str] = [];
    failure_label = failure_class_name(cluster_node.failure_class);
    if failure_label != "UNKNOWN" {
        recurring_signals.append("Primary motif: " + failure_label.replace("_", " ").title());
    }
    recurring_files = summarize_counts(recurring_files_raw, 5);
    recurring_errors = summarize_counts(recurring_errors_raw, 5);
    recurring_tests = summarize_counts(recurring_tests_raw, 5);
    if recurring_files {
        recurring_signals.append("Recurring files: " + ", ".join([item[0] for item in recurring_files[:3]]));
    }
    if recurring_errors {
        recurring_signals.append("Recurring errors: " + ", ".join([item[0] for item in recurring_errors[:3]]));
    }
    if recurring_tests {
        recurring_signals.append("Recurring tests: " + ", ".join([item[0] for item in recurring_tests[:3]]));
    }

    return {
        "cluster_id": cluster_node.cluster_id,
        "label": cluster_node.label,
        "failure_class": failure_label,
        "size": cluster_node.size,
        "medoid_run_id": cluster_node.medoid_run_id,
        "medoid": medoid,
        "representative_runs": representative_runs,
        "recurring_signals": recurring_signals,
        "recurring_files": recurring_files,
        "recurring_errors": recurring_errors,
        "recurring_tests": recurring_tests,
        "summary": cluster_node.summary,
        "patch_ready": failure_label != "UNKNOWN",
        "stored_patch_count": len(stored_patch_ids),
        "stored_patch_ids": stored_patch_ids,
        "status": "cluster_ready",
    };
}

def batch_overview_summary(root_node: any, batch_id: str) -> dict[str, any] {
    compiled = ensure_batch_graph(root_node, batch_id);
    batch = compiled["batch"];
    if batch is None {
        return {
            "batch_id": batch_id,
            "family_counts": {},
            "clusters": [],
            "top_files": [],
            "top_errors": [],
            "top_tests": [],
            "status": "missing",
        };
    }

    family_counts: dict[str, int] = {};
    top_files_raw: list[str] = [];
    top_errors_raw: list[str] = [];
    top_tests_raw: list[str] = [];
    run_summaries: list[dict[str, any]] = [];

    runs = list_batch_runs(batch);
    for run_node in runs {
        failure_label = failure_class_name(run_node.primary_failure);
        family_counts[failure_label] = family_counts.get(failure_label, 0) + 1;
        top_files_raw.extend(run_node.fingerprint.get("top_files", []));
        top_errors_raw.extend(run_node.fingerprint.get("top_error_keywords", []));
        top_tests_raw.extend(run_node.fingerprint.get("top_test_names", []));
        run_summaries.append(
            {
                "run_id": run_node.run_id,
                "task_title": run_node.task_title,
                "step_count": run_node.step_count,
                "primary_failure": failure_label,
                "critical_step_idx": run_node.critical_step_idx,
                "summary": run_node.summary,
            }
        );
    }

    cluster_summaries = [];
    for cluster_node in list_batch_clusters(batch) {
        cluster_summary = _cluster_summary_from_node(batch, cluster_node);
        cluster_summaries.append(
            {
                "cluster_id": cluster_summary["cluster_id"],
                "label": cluster_summary["label"],
                "failure_class": cluster_summary["failure_class"],
                "size": cluster_summary["size"],
                "medoid_run_id": cluster_summary["medoid_run_id"],
                "summary": cluster_summary["summary"],
            }
        );
    }

    return {
        "batch_id": batch_id,
        "family_counts": family_counts,
        "clusters": cluster_summaries,
        "top_files": summarize_counts(top_files_raw, 5),
        "top_errors": summarize_counts(top_errors_raw, 5),
        "top_tests": summarize_counts(top_tests_raw, 5),
        "run_count": batch.run_count,
        "run_ids": [run_node.run_id for run_node in runs],
        "runs": run_summaries,
        "cluster_count": len(cluster_summaries),
        "status": "graph_backed",
    };
}

def analyze_batch_summary(root_node: any, batch_id: str) -> dict[str, any] {
    compiled = ensure_batch_graph(root_node, batch_id);
    batch = compiled["batch"];
    if batch is None {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }
    overview = batch_overview_summary(root_node, batch_id);
    return {
        "batch_id": batch_id,
        "status": "graph_compiled" if compiled["created"] else "graph_reused",
        "message": "Batch graph is ready for analysis and UI reads.",
        "run_count": overview["run_count"],
        "family_counts": overview["family_counts"],
        "cluster_count": overview["cluster_count"],
    };
}

def cluster_view_summary(root_node: any, cluster_id: str) -> dict[str, any] {
    batch_id = cluster_id.split(":")[0];
    compiled = ensure_batch_graph(root_node, batch_id);
    batch = compiled["batch"];
    if batch is None {
        return {
            "cluster_id": cluster_id,
            "label": "Unlabeled cluster",
            "failure_class": "UNKNOWN",
            "size": 0,
            "medoid_run_id": "",
            "recurring_signals": [],
            "patch_ready": False,
            "status": "missing",
        };
    }
    cluster_node = find_cluster_node(batch, cluster_id);
    if cluster_node is None {
        return {
            "cluster_id": cluster_id,
            "label": "Unlabeled cluster",
            "failure_class": "UNKNOWN",
            "size": 0,
            "medoid_run_id": "",
            "recurring_signals": [],
            "patch_ready": False,
            "status": "missing",
        };
    }
    return _cluster_summary_from_node(batch, cluster_node);
}

def run_view_summary(root_node: any, run_id: str, batch_id: str = "") -> dict[str, any] {
    run_node = _ensure_graph_for_run(root_node, run_id, batch_id);
    if run_node is None {
        return {
            "run_id": run_id,
            "summary": "Run view stub",
            "critical_step_idx": -1,
            "timeline": [],
            "artifacts": [],
            "status": "stub",
        };
    }
    return _run_summary_from_node(run_node);
}

def _baseline_summary_for_failure(failure_class: str) -> str {
    if failure_class == "INVALID_PATCH" {
        return "The run appears to have introduced a bad patch and then failed a targeted test before still submitting.";
    }
    if failure_class == "OSCILLATION_LOOP" {
        return "The run appears to repeat search or file-inspection behavior without making progress before submitting.";
    }
    if failure_class == "PREMATURE_COMPLETION" {
        return "The run appears to submit too early after seeing an earlier failure and without a final validation pass.";
    }
    if failure_class == "WRONG_FILE_FOCUS" {
        return "The run appears to spend effort on secondary files without reducing the original failure signal.";
    }
    if failure_class == "TOOL_MISUSE" {
        return "The run appears to keep using tools in a failing way and never recovers the workflow.";
    }
    if failure_class == "STALE_CONTEXT_OR_BAD_PLAN" {
        return "The run appears to remain in inspection or planning mode too long without committing to a validating change.";
    }
    if failure_class == "REQUIREMENT_DRIFT" {
        return "The run appears to drift away from the main issue target before submitting.";
    }
    return "The run failed after a short edit cycle and ended in submission without reliable recovery evidence.";
}

def _pack_token_estimate(text: str) -> int {
    if not text {
        return 0;
    }
    return max(len(text) // 4, 1);
}

def _limited_join(items: list[any], limit: int = 3) -> str {
    chosen: list[str] = [];
    count = 0;
    for item in items {
        if count >= limit {
            break;
        }
        chosen.append(str(item));
        count += 1;
    }
    return ", ".join(chosen);
}

def _baseline_blind_spots(run_view: dict[str, any]) -> list[str] {
    blind_spots = [
        "No explicit critical-step candidate is surfaced from the raw compressed trajectory.",
        "No cluster context is included, so repeated failure motifs across runs stay hidden.",
        "No artifact summary is provided, so recurring files, tests, and error keywords are easy to miss.",
    ];
    if run_view["critical_step_idx"] < 0 {
        blind_spots.append("The run has no localized pivot step, so the baseline cannot point to an irreversible mistake.");
    }
    return blind_spots;
}

def _structured_support_points(run_view: dict[str, any]) -> list[str] {
    points: list[str] = [];
    fingerprint = run_view["artifacts"]["fingerprint"];
    cluster_ids = run_view["artifacts"]["cluster_ids"];
    hypotheses = run_view["artifacts"]["failure_hypotheses"];

    points.append("Critical step localized at step " + str(run_view["critical_step_idx"]) + ".");
    if fingerprint.get("top_files", []) {
        points.append("Top files: " + _limited_join(fingerprint.get("top_files", []), 3) + ".");
    }
    if fingerprint.get("top_error_keywords", []) {
        points.append("Error keywords: " + _limited_join(fingerprint.get("top_error_keywords", []), 3) + ".");
    }
    if len(cluster_ids) > 0 {
        points.append("Cluster context: " + _limited_join(cluster_ids, 2) + ".");
    }
    if len(hypotheses) > 0 {
        top_hypothesis = hypotheses[0];
        points.append(
            "Top deterministic hypothesis: "
            + str(top_hypothesis["label"])
            + " @ "
            + str(top_hypothesis["score"])
            + "."
        );
    }
    if len(run_view["critical_evidence_window"]) > 0 {
        points.append("Evidence window includes " + str(len(run_view["critical_evidence_window"])) + " nearby steps around the pivot.");
    }
    return points;
}

def compare_baseline_summary(root_node: any, run_id: str, batch_id: str = "") -> dict[str, any] {
    run_view = run_view_summary(root_node, run_id, batch_id);
    if run_view["status"] == "stub" {
        return {
            "run_id": run_id,
            "baseline": "Pending implementation",
            "structured": "Pending implementation",
            "status": "missing",
        };
    }
    raw_steps: list[str] = [];
    for item in run_view["timeline"] {
        raw_steps.append(
            "Step "
            + str(item["idx"])
            + " ["
            + item["phase"]
            + "]: "
            + item["excerpt"]
        );
    }
    raw_pack = "\n".join(raw_steps);
    baseline_pack = raw_pack[:1200];
    structured_pack = {
        "summary": run_view["summary"],
        "critical_step_idx": run_view["critical_step_idx"],
        "failure_hypotheses": run_view["artifacts"]["failure_hypotheses"],
        "cluster_ids": run_view["artifacts"]["cluster_ids"],
        "top_files": run_view["artifacts"]["fingerprint"].get("top_files", []),
        "top_errors": run_view["artifacts"]["fingerprint"].get("top_error_keywords", []),
        "critical_window": run_view["critical_evidence_window"],
    };
    structured_support = _structured_support_points(run_view);

    structured = {
        "failure_class": run_view["primary_failure"],
        "critical_step_idx": run_view["critical_step_idx"],
        "evidence_window": run_view["critical_evidence_window"],
        "support_points": structured_support,
        "specificity": "high",
        "pack_token_estimate": _pack_token_estimate(str(structured_pack)),
        "why_better": "Structured analysis identifies a concrete pivot step, adds artifact and cluster context, and cites graph-backed evidence windows.",
    };
    return {
        "run_id": run_id,
        "baseline": {
            "mode": "raw_compressed",
            "compressed_trajectory": baseline_pack,
            "diagnosis": _baseline_summary_for_failure(run_view["primary_failure"]),
            "specificity": "low",
            "blind_spots": _baseline_blind_spots(run_view),
            "pack_token_estimate": _pack_token_estimate(baseline_pack),
        },
        "structured": structured,
        "delta": {
            "critical_step_localized": run_view["critical_step_idx"] >= 0,
            "cluster_context_added": len(run_view["artifacts"]["cluster_ids"]) > 0,
            "artifact_context_added": len(run_view["artifacts"]["fingerprint"].get("top_files", [])) > 0,
            "baseline_pack_token_estimate": _pack_token_estimate(baseline_pack),
            "structured_pack_token_estimate": _pack_token_estimate(str(structured_pack)),
        },
        "status": "comparison_ready",
    };
}

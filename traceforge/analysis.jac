import from traceforge.ingest {
    sample_batch_files,
    sample_batch_summary,
    sample_file_run_id
}
import from py.parser { parse_run }
import from py.features { compute_run_fingerprint, fingerprint_to_dict }
import from py.utils { summarize_counts }

def primary_failure_label(fingerprint: dict[str, any]) -> str {
    best_label = "UNKNOWN";
    best_score = 0.0;
    scores = fingerprint["failure_class_scores"];
    for label in scores {
        score = scores[label];
        if score > best_score {
            best_score = score;
            best_label = label;
        }
    }
    return best_label;
}

def sample_run_path(run_id: str, sample_name: str = "starter") -> str {
    for path in sample_batch_files(sample_name) {
        if sample_file_run_id(path) == run_id {
            return path;
        }
    }
    return "";
}

def batch_overview_summary(batch_id: str) -> dict[str, any] {
    starter = sample_batch_summary("starter");
    if batch_id == starter["batch_id"] {
        family_counts: dict[str, int] = {};
        top_files_raw: list[str] = [];
        top_errors_raw: list[str] = [];
        run_summaries = [];
        for path in sample_batch_files("starter") {
            run = parse_run(path);
            fingerprint = fingerprint_to_dict(compute_run_fingerprint(run));
            failure_label = primary_failure_label(fingerprint);
            family_counts[failure_label] = family_counts.get(failure_label, 0) + 1;
            top_files_raw.extend(fingerprint["top_files"]);
            top_errors_raw.extend(fingerprint["top_error_keywords"]);
            run_summaries.append(
                {
                    "run_id": run.run_id,
                    "step_count": len(run.steps),
                    "primary_failure": failure_label,
                }
            );
        }
        return {
            "batch_id": batch_id,
            "family_counts": family_counts,
            "clusters": [],
            "top_files": summarize_counts(top_files_raw, 5),
            "top_errors": summarize_counts(top_errors_raw, 5),
            "run_count": starter["run_count"],
            "run_ids": starter["run_ids"],
            "runs": run_summaries,
            "status": "starter_data_loaded",
        };
    }
    return {
        "batch_id": batch_id,
        "family_counts": {},
        "clusters": [],
        "top_files": [],
        "top_errors": [],
        "status": "stub",
    };
}

def analyze_batch_summary(batch_id: str) -> dict[str, any] {
    starter = sample_batch_summary("starter");
    if batch_id == starter["batch_id"] {
        overview = batch_overview_summary(batch_id);
        return {
            "batch_id": batch_id,
            "status": "starter_analysis_ready",
            "message": "Starter sample batch was parsed and summarized.",
            "run_count": overview["run_count"],
            "family_counts": overview["family_counts"],
        };
    }
    return {
        "batch_id": batch_id,
        "status": "queued",
        "message": "Analysis pipeline scaffolded. Feature extraction and clustering are pending.",
    };
}

def cluster_view_summary(cluster_id: str) -> dict[str, any] {
    return {
        "cluster_id": cluster_id,
        "label": "Unlabeled cluster",
        "failure_class": "UNKNOWN",
        "size": 0,
        "medoid_run_id": "",
        "recurring_signals": [],
        "patch_ready": False,
    };
}

def run_view_summary(run_id: str) -> dict[str, any] {
    path = sample_run_path(run_id);
    if path {
        run = parse_run(path);
        fingerprint = compute_run_fingerprint(run);
        return {
            "run_id": run.run_id,
            "source_path": run.source_path,
            "summary": f"Parsed {len(run.steps)} decision steps from starter data.",
            "critical_step_idx": -1,
            "timeline": [
                {
                    "idx": step.index,
                    "kind": step.kind,
                    "phase": step.phase,
                    "excerpt": step.excerpt,
                }
                for step in run.steps
            ],
            "artifacts": {
                "turn_count": len(run.turns),
                "metadata": run.metadata,
                "fingerprint": fingerprint_to_dict(fingerprint),
            },
            "status": "parsed_from_sample",
        };
    }
    return {
        "run_id": run_id,
        "summary": "Run view stub",
        "critical_step_idx": -1,
        "timeline": [],
        "artifacts": [],
        "status": "stub",
    };
}

def compare_baseline_summary(run_id: str) -> dict[str, any] {
    return {
        "run_id": run_id,
        "baseline": "Pending implementation",
        "structured": "Pending implementation",
        "status": "stub",
    };
}

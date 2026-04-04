def choose_failure_class(text: str) -> FailureClass by llm();

def draft_cluster_label(text: str) -> ClusterLabel by llm();

def draft_memory_patch(text: str) -> MemoryPatchProposal by llm();

def diagnose_run_summary(run_id: str) -> dict[str, any] {
    return {
        "run_id": run_id,
        "status": "not_implemented",
        "message": "Typed run diagnosis will be added once evidence packs exist.",
    };
}

def diagnose_cluster_summary(cluster_id: str) -> dict[str, any] {
    return {
        "cluster_id": cluster_id,
        "status": "not_implemented",
        "message": "Cluster diagnosis depends on clustering and medoid selection.",
    };
}

def compile_memory_patch_summary(cluster_id: str) -> dict[str, any] {
    return {
        "cluster_id": cluster_id,
        "status": "not_implemented",
        "message": "Memory patch synthesis requires repeated evidence across runs.",
    };
}

def export_report_summary(batch_id: str) -> dict[str, any] {
    return {
        "batch_id": batch_id,
        "status": "not_implemented",
        "message": "Markdown export will be added after the batch overview stabilizes.",
    };
}


import from pathlib { Path }
import from traceforge.analysis { batch_overview_summary, cluster_view_summary }

def export_report_summary(root_node: any, batch_id: str) -> dict[str, any] {
    overview = batch_overview_summary(root_node, batch_id);
    if overview["status"] == "missing" {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }

    lines: list[str] = [
        "# TraceForge Batch Report",
        "",
        f"- Batch ID: `{batch_id}`",
        f"- Run count: {overview['run_count']}",
        f"- Cluster count: {overview['cluster_count']}",
        "",
        "## Failure Families",
    ];

    for family in sorted(overview["family_counts"]) {
        lines.append(f"- {family}: {overview['family_counts'][family]}");
    }

    lines.extend([
        "",
        "## Clusters",
    ]);

    for cluster in overview["clusters"] {
        detail = cluster_view_summary(root_node, cluster["cluster_id"]);
        lines.append(f"### {detail['label']}");
        lines.append("");
        lines.append(f"- Cluster ID: `{detail['cluster_id']}`");
        lines.append(f"- Failure class: {detail['failure_class']}");
        lines.append(f"- Size: {detail['size']}");
        lines.append(f"- Medoid run: `{detail['medoid_run_id']}`");
        if detail["recurring_signals"] {
            lines.append("- Recurring signals:");
            for signal in detail["recurring_signals"] {
                lines.append(f"  - {signal}");
            }
        }
        lines.append("");
    }

    lines.extend([
        "## Runs",
        "",
    ]);

    for run_item in overview["runs"] {
        lines.append(f"### {run_item['run_id']}");
        lines.append("");
        lines.append(f"- Task: {run_item['task_title']}");
        lines.append(f"- Primary failure: {run_item['primary_failure']}");
        lines.append(f"- Critical step: {run_item['critical_step_idx']}");
        lines.append(f"- Summary: {run_item['summary']}");
        lines.append("");
    }

    export_dir = Path("exports");
    export_dir.mkdir(exist_ok=True);
    export_path = export_dir.joinpath(batch_id + ".md");
    export_text = "\n".join(lines).strip() + "\n";
    export_path.write_text(export_text, encoding="utf-8");
    return {
        "batch_id": batch_id,
        "status": "exported",
        "path": str(export_path),
        "cluster_count": overview["cluster_count"],
        "run_count": overview["run_count"],
        "preview": export_text[:500],
    };
}

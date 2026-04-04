import from traceforge.__init__ { project_identity }
import from traceforge.ingest {
    parse_batch_summary,
    sample_batch_summary,
    upload_batch_summary
}
import from traceforge.analysis {
    analyze_batch_summary,
    batch_overview_summary,
    cluster_view_summary,
    compare_baseline_summary,
    run_view_summary
}
import from traceforge.llm_ops {
    compile_memory_patch_summary,
    diagnose_cluster_summary,
    diagnose_run_summary
}
import from traceforge.reporting { export_report_summary }

walker :pub GetStatus {
    can get with Root entry {
        report {
            "project": project_identity(),
            "phase": "phase_2_graph_backed_demo",
            "message": "TraceForge now compiles the starter batch into a Jac graph and serves graph-backed run, cluster, patch, report, and comparison views.",
        };
    }
}

walker :pub UploadBatch {
    has filename: str = "";

    can run with Root entry {
        report upload_batch_summary(self.filename);
    }
}

walker :pub LoadSampleBatch {
    has sample_name: str = "starter";

    can run with Root entry {
        report sample_batch_summary(self.sample_name);
    }
}

walker :pub ParseBatch {
    has batch_id: str;

    can run with Root entry {
        report parse_batch_summary(self.batch_id);
    }
}

walker :pub AnalyzeBatch {
    has batch_id: str;

    can run with Root entry {
        report analyze_batch_summary(root, self.batch_id);
    }
}

walker :pub GetBatchOverview {
    has batch_id: str;

    can run with Root entry {
        report batch_overview_summary(root, self.batch_id);
    }
}

walker :pub GetClusterView {
    has cluster_id: str;

    can run with Root entry {
        report cluster_view_summary(root, self.cluster_id);
    }
}

walker :pub GetRunView {
    has run_id: str;

    can run with Root entry {
        report run_view_summary(root, self.run_id);
    }
}

walker :pub DiagnoseRun {
    has run_id: str;

    can run with Root entry {
        report diagnose_run_summary(root, self.run_id);
    }
}

walker :pub DiagnoseCluster {
    has cluster_id: str;

    can run with Root entry {
        report diagnose_cluster_summary(root, self.cluster_id);
    }
}

walker :pub CompileMemoryPatch {
    has cluster_id: str;

    can run with Root entry {
        report compile_memory_patch_summary(root, self.cluster_id);
    }
}

walker :pub ExportBatchReport {
    has batch_id: str;

    can run with Root entry {
        report export_report_summary(root, self.batch_id);
    }
}

walker :pub CompareBaseline {
    has run_id: str;

    can run with Root entry {
        report compare_baseline_summary(root, self.run_id);
    }
}

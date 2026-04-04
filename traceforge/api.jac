import from traceforge.__init__ { project_identity }
import from traceforge.ingest {
    batch_catalog_summary,
    parse_batch_summary,
    sample_batch_summary,
    upload_batch_summary
}
import from traceforge.analysis {
    analyze_batch_summary,
    batch_overview_summary,
    cluster_view_summary,
    run_view_summary
}
import from traceforge.graph_build { invalidate_batch_graph }
import from traceforge.eval {
    compare_run_harness_summary,
    export_blinded_eval_summary
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
            "phase": "phase_7_fair_comparison_ready",
            "message": "TraceForge now ships a Jac-only graph-backed demo with fair same-schema comparison, blinded eval export, cluster diagnosis, and markdown report export.",
        };
    }
}

walker :pub UploadBatch {
    has filename: str = "";

    can run with Root entry {
        report upload_batch_summary(self.filename);
    }
}

walker :pub GetBatchCatalog {
    can run with Root entry {
        report batch_catalog_summary();
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
    has force_rebuild: bool = False;

    can run with Root entry {
        report analyze_batch_summary(root, self.batch_id, self.force_rebuild);
    }
}

walker :pub InvalidateBatchGraph {
    has batch_id: str;

    can run with Root entry {
        report invalidate_batch_graph(root, self.batch_id);
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
    has batch_id: str = "";

    can run with Root entry {
        report run_view_summary(root, self.run_id, self.batch_id);
    }
}

walker :pub DiagnoseRun {
    has run_id: str;
    has batch_id: str = "";

    can run with Root entry {
        report diagnose_run_summary(root, self.run_id, self.batch_id);
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

walker :pub ExportBlindedEvaluation {
    has batch_id: str;
    has limit: int = 10;
    has substantive_only: bool = True;

    can run with Root entry {
        report export_blinded_eval_summary(root, self.batch_id, self.limit, self.substantive_only);
    }
}

walker :pub CompareBaseline {
    has run_id: str;
    has batch_id: str = "";

    can run with Root entry {
        report compare_run_harness_summary(root, self.run_id, self.batch_id);
    }
}

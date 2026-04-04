include traceforge.__init__;
include traceforge.schema;
include traceforge.ingest;
include traceforge.parser;
include traceforge.features;
include traceforge.clustering;
include traceforge.critical;
include traceforge.graph_build;
include traceforge.analysis;
include traceforge.llm_ops;
include traceforge.reporting;
include traceforge.api;

test {
    result = root spawn AnalyzeBatch(batch_id="sample-starter");
    data = result.reports[0];
    assert data["run_count"] == 4;
    assert data["cluster_count"] == 4;
}

test {
    result = root spawn GetRunView(run_id="premature_completion");
    data = result.reports[0];
    assert data["status"] == "graph_backed";
    assert data["primary_failure"] == "PREMATURE_COMPLETION";
    assert data["critical_step_idx"] == 1;
}

test {
    result = root spawn CompileMemoryPatch(cluster_id="sample-starter:premature_completion:0");
    data = result.reports[0];
    assert data["status"] == "deterministic_patch";
    assert "rerun at least one targeted failing test" in data["diff_text"];
}

test {
    result = root spawn ExportBatchReport(batch_id="sample-starter");
    data = result.reports[0];
    assert data["status"] == "exported";
    assert data["cluster_count"] == 4;
}

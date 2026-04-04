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
    upload_result = root spawn UploadBatch(filename="local_demo_batch");
    upload_data = upload_result.reports[0];
    assert upload_data["batch_id"] == "upload-local_demo";
    assert upload_data["status"] == "ready";
    assert upload_data["run_count"] == 2;

    parse_result = root spawn ParseBatch(batch_id="upload-local_demo");
    parse_data = parse_result.reports[0];
    assert parse_data["status"] == "parsed";
    assert parse_data["run_count"] == 2;

    analyze_result = root spawn AnalyzeBatch(batch_id="upload-local_demo");
    analyze_data = analyze_result.reports[0];
    assert analyze_data["run_count"] == 2;
    assert analyze_data["cluster_count"] >= 1;
}

test {
    result = root spawn GetRunView(run_id="premature_completion");
    data = result.reports[0];
    assert data["status"] == "graph_backed";
    assert data["primary_failure"] == "PREMATURE_COMPLETION";
    assert data["critical_step_idx"] == 1;
}

test {
    result = root spawn DiagnoseRun(run_id="premature_completion");
    data = result.reports[0];
    assert data["status"] == "deterministic_diagnosis";
    assert data["failure_class"] == "PREMATURE_COMPLETION";
    assert data["critical_step_idx"] == 1;
}

test {
    result = root spawn CompileMemoryPatch(cluster_id="sample-starter:premature_completion:0");
    data = result.reports[0];
    assert data["status"] == "deterministic_patch";
    assert "rerun at least one targeted failing test" in data["diff_text"];
    assert data["stored_in_graph"] == True;

    cluster_result = root spawn GetClusterView(cluster_id="sample-starter:premature_completion:0");
    cluster_data = cluster_result.reports[0];
    assert cluster_data["stored_patch_count"] >= 1;
}

test {
    result = root spawn CompareBaseline(run_id="premature_completion");
    data = result.reports[0];
    assert data["status"] == "comparison_ready";
    assert data["structured"]["critical_step_idx"] == 1;
    assert data["structured"]["failure_class"] == "PREMATURE_COMPLETION";
}

test {
    result = root spawn ExportBatchReport(batch_id="sample-starter");
    data = result.reports[0];
    assert data["status"] == "exported";
    assert data["cluster_count"] == 4;
}

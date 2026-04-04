import from pathlib { Path }
import from zipfile { ZIP_DEFLATED, ZipFile }

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
include traceforge.eval;
include traceforge.reporting;
include traceforge.api;

test {
    status_result = root spawn GetStatus();
    status_data = status_result.reports[0];
    assert status_data["phase"] == "phase_7_fair_comparison_ready";
    assert status_data["project"]["status"] == "fair_comparison_ready";
}

test {
    result = root spawn AnalyzeBatch(batch_id="sample-starter");
    data = result.reports[0];
    assert data["run_count"] == 4;
    assert data["cluster_count"] == 4;
}

test {
    catalog_result = root spawn GetBatchCatalog();
    catalog_data = catalog_result.reports[0];
    assert catalog_data["status"] == "ready";
    assert catalog_data["batch_count"] >= 2;

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

    upload_run_result = root spawn GetRunView(run_id="premature_completion", batch_id="upload-local_demo");
    upload_run_data = upload_run_result.reports[0];
    assert "uploads/local_demo_batch" in upload_run_data["source_path"];
}

test {
    archive_path = Path("uploads/local_zip_demo.zip");
    bundle = ZipFile(str(archive_path), "w", compression=ZIP_DEFLATED);
    bundle.write("uploads/local_demo_batch/invalid_patch.traj.json", arcname="invalid_patch.traj.json");
    bundle.write("uploads/local_demo_batch/premature_completion.traj.json", arcname="nested/premature_completion.traj.json");
    bundle.close();

    zip_upload_result = root spawn UploadBatch(filename="local_zip_demo.zip");
    zip_upload_data = zip_upload_result.reports[0];
    assert zip_upload_data["batch_id"] == "upload-local_zip_demo";
    assert zip_upload_data["status"] == "ready";
    assert zip_upload_data["ingest_mode"] == "zip";
    assert "local_zip_demo.zip" in zip_upload_data["resolved_archive"];
    assert zip_upload_data["run_count"] == 2;

    zip_parse_result = root spawn ParseBatch(batch_id="upload-local_zip_demo");
    zip_parse_data = zip_parse_result.reports[0];
    assert zip_parse_data["status"] == "parsed";
    assert zip_parse_data["run_count"] == 2;

    zip_analyze_result = root spawn AnalyzeBatch(batch_id="upload-local_zip_demo");
    zip_analyze_data = zip_analyze_result.reports[0];
    assert zip_analyze_data["run_count"] == 2;

    zip_run_result = root spawn GetRunView(run_id="premature_completion", batch_id="upload-local_zip_demo");
    zip_run_data = zip_run_result.reports[0];
    assert "uploads/local_zip_demo" in zip_run_data["source_path"];
}

test {
    external_dir = Path("exports/external_eval_batch");
    external_dir.mkdir(parents=True, exist_ok=True);
    invalid_text = Path("uploads/local_demo_batch/invalid_patch.traj.json").read_text(encoding="utf-8");
    premature_text = Path("uploads/local_demo_batch/premature_completion.traj.json").read_text(encoding="utf-8");
    external_dir.joinpath("invalid_patch.traj.json").write_text(invalid_text, encoding="utf-8");
    nested_dir = external_dir.joinpath("nested");
    nested_dir.mkdir(parents=True, exist_ok=True);
    nested_dir.joinpath("premature_completion.traj.json").write_text(premature_text, encoding="utf-8");

    external_upload_result = root spawn UploadBatch(filename="exports/external_eval_batch");
    external_upload_data = external_upload_result.reports[0];
    assert external_upload_data["batch_id"] == "upload-external_eval";
    assert external_upload_data["status"] == "ready";
    assert external_upload_data["run_count"] == 2;
    assert external_upload_data["managed_alias_created"] == True;
    assert "exports/external_eval_batch" in external_upload_data["source_path"];
    assert "uploads/external_eval" in external_upload_data["managed_alias"];

    external_parse_result = root spawn ParseBatch(batch_id="upload-external_eval");
    external_parse_data = external_parse_result.reports[0];
    assert external_parse_data["status"] == "parsed";
    assert external_parse_data["run_count"] == 2;

    external_run_result = root spawn GetRunView(run_id="premature_completion", batch_id="upload-external_eval");
    external_run_data = external_run_result.reports[0];
    assert "uploads/external_eval" in external_run_data["source_path"];
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
    assert data["llm_used"] == False;
    assert "TraceForge run evidence pack" in data["evidence_pack"];
}

test {
    result = root spawn CompileMemoryPatch(cluster_id="sample-starter:premature_completion:0");
    data = result.reports[0];
    assert data["status"] == "deterministic_patch";
    assert "rerun at least one targeted failing test" in data["diff_text"];
    assert data["stored_in_graph"] == True;
    assert data["llm_used"] == False;
    assert "TraceForge cluster evidence pack" in data["evidence_pack"];

    cluster_result = root spawn GetClusterView(cluster_id="sample-starter:premature_completion:0");
    cluster_data = cluster_result.reports[0];
    assert cluster_data["stored_patch_count"] >= 1;
}

test {
    result = root spawn DiagnoseCluster(cluster_id="sample-starter:premature_completion:0");
    data = result.reports[0];
    assert data["status"] == "deterministic_cluster_label";
    assert data["label"] == "Premature completion";
    assert data["llm_used"] == False;
    assert "TraceForge cluster evidence pack" in data["evidence_pack"];
}

test {
    result = root spawn CompareBaseline(run_id="premature_completion");
    data = result.reports[0];
    assert data["status"] == "comparison_ready";
    assert data["comparison_mode"] == "deterministic_proxy";
    assert data["baseline"]["mode"] == "raw_transcript_prompt";
    assert data["structured"]["mode"] == "traceforge_retrieval_prompt";
    assert data["structured"]["critical_step_idx"] == 1;
    assert data["structured"]["failure_class"] == "PREMATURE_COMPLETION";
    assert data["baseline"]["specificity"] == "medium";
    assert data["structured"]["specificity"] == "high";
    assert data["delta"]["critical_step_localized"] == True;
    assert len(data["baseline"]["blind_spots"]) >= 2;
    assert len(data["structured"]["support_points"]) >= 3;
    assert data["verifier"]["status"] == "deterministic_proxy_verdict";
    assert data["verifier"]["winner"] == "structured";
    assert data["blinded"]["assignment"]["A"] != data["blinded"]["assignment"]["B"];
}

test {
    result = root spawn ExportBlindedEvaluation(batch_id="sample-starter", limit=2);
    data = result.reports[0];
    assert data["status"] == "exported";
    assert data["selected_run_count"] == 2;
    assert "exports/evals/sample-starter_blind.md" in data["blind_sheet_path"];
    assert "exports/evals/sample-starter_blind_key.json" in data["blind_key_path"];
    assert "exports/evals/sample-starter_comparison.json" in data["summary_json_path"];
    blind_sheet = Path(data["blind_sheet_path"]).read_text(encoding="utf-8");
    assert "## Run `invalid_patch`" in blind_sheet or "## Run `premature_completion`" in blind_sheet;
    assert "### Arm A" in blind_sheet;
    assert "### Rubric" in blind_sheet;
}

test {
    result = root spawn ExportBatchReport(batch_id="sample-starter");
    data = result.reports[0];
    assert data["status"] == "exported";
    assert data["cluster_count"] == 4;
    report_text = Path(data["path"]).read_text(encoding="utf-8");
    assert "## Demo Highlights" in report_text;
    assert "#### AGENTS.md Patch" in report_text;
    assert "## Baseline Comparison Snapshot" in report_text;
}

sv import from traceforge.api {
    AnalyzeBatch,
    CompareBaseline,
    CompileMemoryPatch,
    DiagnoseCluster,
    DiagnoseRun,
    ExportBatchReport,
    GetBatchCatalog,
    GetBatchOverview,
    GetClusterView,
    GetRunView
}

cl {
    def:pub app() -> JsxElement {
        has status: str = "Booting TraceForge...";
        has loading: bool = True;
        has loadingBatch: bool = False;
        has loadingRun: bool = False;
        has loadingCluster: bool = False;
        has loadingReport: bool = False;
        has selectedBatchId: str = "";
        has selectedRunId: str = "";
        has selectedClusterId: str = "";
        has batchCatalog: any = {
            "batches": [],
            "batch_count": 0,
        };
        has overview: any = {
            "family_counts": {},
            "clusters": [],
            "top_files": [],
            "top_errors": [],
            "top_tests": [],
            "runs": [],
            "run_count": 0,
            "cluster_count": 0,
        };
        has runDetail: any = {
            "summary": "",
            "primary_failure": "UNKNOWN",
            "critical_step_idx": -1,
            "critical_evidence_window": [],
            "timeline": [],
            "artifacts": {
                "fingerprint": {},
                "cluster_ids": [],
            },
        };
        has clusterDetail: any = {
            "label": "",
            "summary": "",
            "failure_class": "UNKNOWN",
            "size": 0,
            "stored_patch_count": 0,
            "recurring_signals": [],
            "representative_runs": [],
        };
        has patchDetail: any = {
            "summary": "",
            "rules": [],
            "diff_text": "",
            "stored_in_graph": False,
            "stored_patch_id": "",
        };
        has clusterDiagnosis: any = {
            "label": "",
            "summary": "",
            "confidence": 0.0,
            "llm_used": False,
            "evidence_pack": "",
        };
        has comparison: any = {
            "baseline": {
                "diagnosis": "",
                "compressed_trajectory": "",
                "specificity": "",
            },
            "structured": {
                "failure_class": "UNKNOWN",
                "critical_step_idx": -1,
                "evidence_window": [],
                "why_better": "",
            },
        };
        has diagnosis: any = {
            "irreversible_because": "",
            "evidence": [],
            "confidence": 0.0,
        };
        has reportDetail: any = {
            "status": "idle",
            "path": "",
            "preview": "",
            "run_count": 0,
            "cluster_count": 0,
        };

        async def load_run(runId: str, batchId: str = "") -> None {
            if not runId {
                return;
            }
            selectedRunId = runId;
            loadingRun = True;
            status = "Loading run " + runId + "...";

            run_result = root spawn GetRunView(run_id=runId, batch_id=batchId);
            if run_result.reports {
                runDetail = run_result.reports[0];
            }

            diagnosis_result = root spawn DiagnoseRun(run_id=runId, batch_id=batchId);
            if diagnosis_result.reports {
                diagnosis = diagnosis_result.reports[0];
            }

            compare_result = root spawn CompareBaseline(run_id=runId, batch_id=batchId);
            if compare_result.reports {
                comparison = compare_result.reports[0];
            }

            status = "Showing run " + runId + ".";
            loadingRun = False;
        }

        async def load_cluster(clusterId: str) -> None {
            if not clusterId {
                return;
            }
            selectedClusterId = clusterId;
            loadingCluster = True;
            status = "Loading cluster " + clusterId + "...";

            cluster_result = root spawn GetClusterView(cluster_id=clusterId);
            if cluster_result.reports {
                clusterDetail = cluster_result.reports[0];
            }

            cluster_diagnosis_result = root spawn DiagnoseCluster(cluster_id=clusterId);
            if cluster_diagnosis_result.reports {
                clusterDiagnosis = cluster_diagnosis_result.reports[0];
            }

            patch_result = root spawn CompileMemoryPatch(cluster_id=clusterId);
            if patch_result.reports {
                patchDetail = patch_result.reports[0];
            }

            status = "Showing cluster " + clusterId + ".";
            loadingCluster = False;
        }

        async def export_batch_report(batchId: str) -> None {
            if not batchId {
                return;
            }
            loadingReport = True;
            status = "Exporting report for " + batchId + "...";

            report_result = root spawn ExportBatchReport(batch_id=batchId);
            if report_result.reports {
                reportDetail = report_result.reports[0];
            }

            status = "Exported report for " + batchId + ".";
            loadingReport = False;
        }

        async def load_batch(batchId: str) -> None {
            if not batchId {
                return;
            }
            selectedBatchId = batchId;
            selectedRunId = "";
            selectedClusterId = "";
            loadingBatch = True;
            reportDetail = {
                "status": "idle",
                "path": "",
                "preview": "",
                "run_count": 0,
                "cluster_count": 0,
            };
            status = "Loading batch " + batchId + "...";

            analyze = root spawn AnalyzeBatch(batch_id=batchId);
            if analyze.reports {
                status = String(analyze.reports[0]["message"]);
            }

            overview_result = root spawn GetBatchOverview(batch_id=batchId);
            if overview_result.reports {
                overview = overview_result.reports[0];
            }

            if overview["runs"].length > 0 {
                first_run_id = String(overview["runs"][0]["run_id"]);
                load_run(first_run_id, batchId);
            }

            if overview["clusters"].length > 0 {
                first_cluster_id = String(overview["clusters"][0]["cluster_id"]);
                load_cluster(first_cluster_id);
            }

            status = "Showing batch " + batchId + ".";
            loadingBatch = False;
        }

        async can with entry {
            catalog_result = root spawn GetBatchCatalog();
            if catalog_result.reports {
                batchCatalog = catalog_result.reports[0];
            }

            if batchCatalog["batches"].length > 0 {
                first_batch_id = String(batchCatalog["batches"][0]["batch_id"]);
                load_batch(first_batch_id);
            }

            status = "Batch catalog loaded through graph-backed walkers.";
            loading = False;
        }

        catalogEntries = batchCatalog["batches"] || [];
        familyRows = Object.entries(overview["family_counts"]);
        topFiles = overview["top_files"];
        topErrors = overview["top_errors"];
        topTests = overview["top_tests"];
        clusters = overview["clusters"];
        runs = overview["runs"];
        diagnosisEvidence = diagnosis["evidence"] || [];
        criticalWindow = runDetail["critical_evidence_window"] || [];
        timeline = runDetail["timeline"] || [];
        representativeRuns = clusterDetail["representative_runs"] || [];
        recurringSignals = clusterDetail["recurring_signals"] || [];
        recurringFiles = clusterDetail["recurring_files"] || [];
        recurringErrors = clusterDetail["recurring_errors"] || [];
        recurringTests = clusterDetail["recurring_tests"] || [];
        patchRules = patchDetail["rules"] || [];
        structuredWindow = comparison["structured"]["evidence_window"] || [];
        baselineBlindSpots = comparison["baseline"]["blind_spots"] || [];
        structuredSupportPoints = comparison["structured"]["support_points"] || [];
        clusterDiagnosisMode = "Deterministic fallback";
        if clusterDiagnosis["llm_used"] {
            clusterDiagnosisMode = "Typed by llm()";
        }
        activeBatch = {};
        for batch in catalogEntries {
            if String(batch["batch_id"]) == String(selectedBatchId) {
                activeBatch = batch;
            }
        }
        leadingFamily = "UNKNOWN";
        leadingFamilyCount = "0";
        if familyRows.length > 0 {
            sortedFamilies = familyRows.sort(lambda left: any, right: any -> any : Number(right[1]) - Number(left[1]));
            leadingFamily = String(sortedFamilies[0][0]);
            leadingFamilyCount = String(sortedFamilies[0][1]);
        }
        diagnosisMode = "Deterministic fallback";
        if diagnosis["llm_used"] {
            diagnosisMode = "Typed by llm()";
        }
        patchMode = "Deterministic fallback";
        if patchDetail["llm_used"] {
            patchMode = "Typed by llm()";
        }
        activeBatchName = String(activeBatch["name"] || selectedBatchId || "none");
        activeBatchKind = String(activeBatch["kind"] || "unknown");
        runStatusText = "Run details ready.";
        clusterStatusText = "Cluster details ready.";
        if loadingRun {
            runStatusText = "Refreshing run details...";
        }
        if loadingCluster {
            clusterStatusText = "Refreshing cluster details...";
        }
        batchStatusText = "Batch overview ready.";
        if loadingBatch {
            batchStatusText = "Refreshing batch overview...";
        }
        reportStatusText = "Report export idle.";
        if loadingReport {
            reportStatusText = "Exporting report...";
        } elif reportDetail["status"] == "exported" {
            reportStatusText = "Report ready at " + String(reportDetail["path"]);
        }

        if loading {
            return <main className="shell">
                <section className="hero">
                    <p className="eyebrow">JacHacks 2026</p>
                    <h1>TraceForge</h1>
                    <p className="tagline">Batch failure compiler for coding-agent trajectories.</p>
                    <p className="status">{status}</p>
                    <p className="status">Preparing the Jac-native batch catalog, graph compilation, and demo views.</p>
                </section>
            </main>;
        }

        return <main className="shell">
            <section className="hero">
                <p className="eyebrow">JacHacks 2026</p>
                <h1>TraceForge</h1>
                <p className="tagline">Batch failure compiler for coding-agent trajectories.</p>
                <p className="status">{status}</p>
                <p className="status">
                    Active batch: {activeBatchName} ({activeBatchKind}) | Batch size: {String(overview["run_count"])} | Cluster count: {String(overview["cluster_count"])}
                </p>
                <p className="status">
                    Leading motif: {leadingFamily} ({leadingFamilyCount}) | Selected run: {String(selectedRunId || "none")} | Selected cluster: {String(selectedClusterId || "none")}
                </p>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Submission Snapshot</h2>
                    <ul>
                        <li>Jac-first demo path: graph-backed batch, cluster, run, diagnosis, patch, comparison, and report walkers.</li>
                        <li>Active batch: {activeBatchName} with {String(overview["run_count"])} runs and {String(overview["cluster_count"])} clusters.</li>
                        <li>Run diagnosis mode: {diagnosisMode}.</li>
                        <li>Cluster diagnosis mode: {clusterDiagnosisMode}.</li>
                        <li>Patch synthesis mode: {patchMode}.</li>
                        <li>Stored cluster patches: {String(clusterDetail["stored_patch_count"] || 0)}.</li>
                    </ul>
                </article>

                <article className="panel">
                    <h2>Demo Flow</h2>
                    <ol>
                        <li>Choose a batch and compile its graph-backed overview.</li>
                        <li>Open a recurring failure cluster and inspect the medoid and recurring signals.</li>
                        <li>Open a failed run and highlight the likely first irreversible step.</li>
                        <li>Compare raw compressed analysis against structured evidence-pack reasoning.</li>
                        <li>Export the batch report and keep the markdown artifact as a demo fallback.</li>
                    </ol>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Screen 1: Batch Catalog</h2>
                    <p>{batchStatusText}</p>
                    <ul>
                        {[
                            <li>
                                <button onClick={lambda e: any -> None { load_batch(String(batch["batch_id"])); }}>
                                    Open {String(batch["batch_id"])}
                                </button>
                                <strong>{String(batch["name"])}</strong> | {String(batch["kind"])} | runs {String(batch["run_count"])}
                                <div>{String(batch["path"])}</div>
                            </li>
                            for batch in catalogEntries
                        ]}
                    </ul>
                </article>

                <article className="panel">
                    <h2>Screen 1: Batch Overview</h2>
                    <p>Failure families, recurring files, errors, and tests for the active batch.</p>
                    <ul>
                        {[<li>{String(item[0])}: {String(item[1])}</li> for item in familyRows]}
                    </ul>
                    <h3>Top Files</h3>
                    <ul>
                        {[<li>{String(item[0])} ({String(item[1])})</li> for item in topFiles]}
                    </ul>
                    <h3>Top Errors</h3>
                    <ul>
                        {[<li>{String(item[0])} ({String(item[1])})</li> for item in topErrors]}
                    </ul>
                    <h3>Top Tests</h3>
                    <ul>
                        {[<li>{String(item[0])} ({String(item[1])})</li> for item in topTests]}
                    </ul>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Screen 2: Cluster Explorer</h2>
                    <p>Open one cluster to inspect recurring motifs and synthesize a reusable patch.</p>
                    <ul>
                        {[
                            <li>
                                <button onClick={lambda e: any -> None { load_cluster(String(cluster["cluster_id"])); }}>
                                    Open {String(cluster["label"])}
                                </button>
                                <strong>{String(cluster["label"])}</strong> | {String(cluster["failure_class"])} | size {String(cluster["size"])}
                                <div>Cluster ID: {String(cluster["cluster_id"])}</div>
                                <div>{String(cluster["summary"])}</div>
                            </li>
                            for cluster in clusters
                        ]}
                    </ul>
                </article>

                <article className="panel">
                    <h2>Screen 2: Active Cluster</h2>
                    <p>Selected cluster: {String(selectedClusterId || "none")}</p>
                    <p>{clusterStatusText}</p>
                    <p><strong>{String(clusterDetail["label"] || "")}</strong></p>
                    <p>{String(clusterDetail["summary"] || "")}</p>
                    <p>Failure class: {String(clusterDetail["failure_class"] || "UNKNOWN")}</p>
                    <p>Cluster size: {String(clusterDetail["size"] || 0)}</p>
                    <p>Medoid run: {String(clusterDetail["medoid_run_id"] || "")}</p>
                    <p>Stored patches: {String(clusterDetail["stored_patch_count"] || 0)}</p>
                    <h3>Cluster Diagnosis</h3>
                    <p>{String(clusterDiagnosis["label"] || "")}</p>
                    <p>{String(clusterDiagnosis["summary"] || "")}</p>
                    <p>Confidence: {String(clusterDiagnosis["confidence"] || 0)}</p>
                    <p>Diagnosis mode: {clusterDiagnosisMode}</p>
                    <h3>Recurring Signals</h3>
                    <ul>
                        {[<li>{String(item)}</li> for item in recurringSignals]}
                    </ul>
                    <h3>Recurring Files</h3>
                    <ul>
                        {[<li>{String(item[0])} ({String(item[1])})</li> for item in recurringFiles]}
                    </ul>
                    <h3>Recurring Errors</h3>
                    <ul>
                        {[<li>{String(item[0])} ({String(item[1])})</li> for item in recurringErrors]}
                    </ul>
                    <h3>Recurring Tests</h3>
                    <ul>
                        {[<li>{String(item[0])} ({String(item[1])})</li> for item in recurringTests]}
                    </ul>
                    <h3>Representative Runs</h3>
                    <ul>
                        {[
                            <li>
                                <button onClick={lambda e: any -> None { load_run(String(item["run_id"]), String(selectedBatchId)); }}>
                                    Load run
                                </button>
                                <strong>{String(item["run_id"])}</strong> | critical step {String(item["critical_step_idx"])}
                                <div>{String(item["summary"])}</div>
                            </li>
                            for item in representativeRuns
                        ]}
                    </ul>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Screen 3: Run Browser</h2>
                    <p>Choose a representative failed run from the active batch.</p>
                    <h3>Runs</h3>
                    <ul>
                        {[
                            <li>
                                <button onClick={lambda e: any -> None { load_run(String(run["run_id"]), String(selectedBatchId)); }}>
                                    Open {String(run["run_id"])}
                                </button>
                                <strong>{String(run["run_id"])}</strong> | {String(run["primary_failure"])} | critical step {String(run["critical_step_idx"])}
                                <div>{String(run["summary"])}</div>
                            </li>
                            for run in runs
                        ]}
                    </ul>
                </article>

                <article className="panel">
                    <h2>Screen 3: Run Forensics</h2>
                    <p>Selected run: {String(selectedRunId || "none")}</p>
                    <p>{runStatusText}</p>
                    <p><strong>{String(runDetail["run_id"] || "")}</strong></p>
                    <p>{String(runDetail["summary"] || "")}</p>
                    <p>Primary failure: {String(runDetail["primary_failure"] || "UNKNOWN")}</p>
                    <p>Critical step: {String(runDetail["critical_step_idx"])}</p>
                    <p>Diagnosis mode: {diagnosisMode}</p>
                    <h3>Diagnosis</h3>
                    <p>{String(diagnosis["irreversible_because"] || "")}</p>
                    <p>Confidence: {String(diagnosis["confidence"] || 0)}</p>
                    <ul>
                        {[
                            <li>
                                Step {String(item["step_idx"])} [{String(item["artifact"])}]: {String(item["quote"])}
                            </li>
                            for item in diagnosisEvidence
                        ]}
                    </ul>
                    <details>
                        <summary>Evidence Pack</summary>
                        <pre>{String(diagnosis["evidence_pack"] || "")}</pre>
                    </details>
                    <h3>Critical Window</h3>
                    <ol>
                        {[
                            <li>
                                <strong>Step {String(item["idx"])} [{String(item["phase"])}]</strong>
                                <div>{String(item["excerpt"])}</div>
                            </li>
                            for item in criticalWindow
                        ]}
                    </ol>
                </article>

                <article className="panel">
                    <h2>Screen 3: Run Timeline</h2>
                    <p>Full step sequence for the selected run.</p>
                    <ol>
                        {[
                            <li>
                                <strong>Step {String(item["idx"])} [{String(item["phase"])}]</strong>
                                <div>{String(item["excerpt"])}</div>
                                <div>Files: {String((item["touched_files"] || []).join(", "))}</div>
                            </li>
                            for item in timeline
                        ]}
                    </ol>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Screen 2: Generated AGENTS.md Patch</h2>
                    <p>{String(patchDetail["summary"] || "")}</p>
                    <p>Patch mode: {patchMode}</p>
                    <p>Stored in graph: {String(patchDetail["stored_in_graph"] || False)}</p>
                    <p>Patch ID: {String(patchDetail["stored_patch_id"] || "")}</p>
                    <ul>
                        {[
                            <li>
                                <strong>{String(rule["title"])}</strong>: {String(rule["rule_text"])}
                                <div>Confidence: {String(rule["confidence"] || 0)}</div>
                            </li>
                            for rule in patchRules
                        ]}
                    </ul>
                    <details>
                        <summary>Patch Evidence Pack</summary>
                        <pre>{String(patchDetail["evidence_pack"] || "")}</pre>
                    </details>
                    <pre>{String(patchDetail["diff_text"] || "")}</pre>
                </article>

                <article className="panel">
                    <h2>Submission Artifact: Batch Report</h2>
                    <p>{reportStatusText}</p>
                    <p>Export one markdown report per batch so the demo has a reliable fallback artifact outside the live UI.</p>
                    <button onClick={lambda e: any -> None { export_batch_report(String(selectedBatchId)); }}>
                        Export {String(selectedBatchId || "batch")} report
                    </button>
                    <p>Path: {String(reportDetail["path"] || "")}</p>
                    <p>Runs: {String(reportDetail["run_count"] || 0)} | Clusters: {String(reportDetail["cluster_count"] || 0)}</p>
                    <details>
                        <summary>Report Preview</summary>
                        <pre>{String(reportDetail["preview"] || "")}</pre>
                    </details>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Screen 4: Raw Baseline</h2>
                    <h3>Raw Baseline</h3>
                    <p>{String(comparison["baseline"]["diagnosis"] || "")}</p>
                    <p>Specificity: {String(comparison["baseline"]["specificity"] || "")}</p>
                    <p>Estimated input size: {String(comparison["baseline"]["pack_token_estimate"] || 0)} tokens</p>
                    <h3>Blind Spots</h3>
                    <ul>
                        {[<li>{String(item)}</li> for item in baselineBlindSpots]}
                    </ul>
                    <pre>{String(comparison["baseline"]["compressed_trajectory"] || "")}</pre>
                </article>

                <article className="panel">
                    <h2>Screen 4: Structured Diagnosis</h2>
                    <p>Failure class: {String(comparison["structured"]["failure_class"] || "UNKNOWN")}</p>
                    <p>Critical step: {String(comparison["structured"]["critical_step_idx"] || -1)}</p>
                    <p>Specificity: {String(comparison["structured"]["specificity"] || "")}</p>
                    <p>Estimated input size: {String(comparison["structured"]["pack_token_estimate"] || 0)} tokens</p>
                    <p>{String(comparison["structured"]["why_better"] || "")}</p>
                    <h3>Support Points</h3>
                    <ul>
                        {[<li>{String(item)}</li> for item in structuredSupportPoints]}
                    </ul>
                    <ol>
                        {[
                            <li>
                                <strong>Step {String(item["idx"])} [{String(item["phase"])}]</strong>
                                <div>{String(item["excerpt"])}</div>
                            </li>
                            for item in structuredWindow
                        ]}
                    </ol>
                </article>
            </section>
        </main>;
    }
}

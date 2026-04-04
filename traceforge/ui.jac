sv import from traceforge.api {
    AnalyzeBatch,
    CompareBaseline,
    CompileMemoryPatch,
    DiagnoseRun,
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

            patch_result = root spawn CompileMemoryPatch(cluster_id=clusterId);
            if patch_result.reports {
                patchDetail = patch_result.reports[0];
            }

            status = "Showing cluster " + clusterId + ".";
            loadingCluster = False;
        }

        async def load_batch(batchId: str) -> None {
            if not batchId {
                return;
            }
            selectedBatchId = batchId;
            selectedRunId = "";
            selectedClusterId = "";
            loadingBatch = True;
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
        patchRules = patchDetail["rules"] || [];
        structuredWindow = comparison["structured"]["evidence_window"] || [];
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

        if loading {
            return <main className="shell">
                <section className="hero">
                    <p className="eyebrow">JacHacks 2026</p>
                    <h1>TraceForge</h1>
                    <p className="tagline">Batch failure compiler for coding-agent trajectories.</p>
                    <p className="status">{status}</p>
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
                    Active batch: {String(selectedBatchId || "none")} | Batch size: {String(overview["run_count"])} | Cluster count: {String(overview["cluster_count"])}
                </p>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Batch Catalog</h2>
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
                    <h2>Failure Families</h2>
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

                <article className="panel">
                    <h2>Clusters</h2>
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
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Representative Run</h2>
                    <p>Selected run: {String(selectedRunId || "none")}</p>
                    <p>{runStatusText}</p>
                    <p><strong>{String(runDetail["run_id"] || "")}</strong></p>
                    <p>{String(runDetail["summary"] || "")}</p>
                    <p>Primary failure: {String(runDetail["primary_failure"] || "UNKNOWN")}</p>
                    <p>Critical step: {String(runDetail["critical_step_idx"])}</p>
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
                    <h2>Run Timeline</h2>
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
                    <h2>Representative Cluster</h2>
                    <p>Selected cluster: {String(selectedClusterId || "none")}</p>
                    <p>{clusterStatusText}</p>
                    <p><strong>{String(clusterDetail["label"] || "")}</strong></p>
                    <p>{String(clusterDetail["summary"] || "")}</p>
                    <p>Failure class: {String(clusterDetail["failure_class"] || "UNKNOWN")}</p>
                    <p>Cluster size: {String(clusterDetail["size"] || 0)}</p>
                    <p>Stored patches: {String(clusterDetail["stored_patch_count"] || 0)}</p>
                    <h3>Recurring Signals</h3>
                    <ul>
                        {[<li>{String(item)}</li> for item in recurringSignals]}
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

                <article className="panel">
                    <h2>Generated AGENTS.md Patch</h2>
                    <p>{String(patchDetail["summary"] || "")}</p>
                    <p>Stored in graph: {String(patchDetail["stored_in_graph"] || False)}</p>
                    <p>Patch ID: {String(patchDetail["stored_patch_id"] || "")}</p>
                    <ul>
                        {[
                            <li>
                                <strong>{String(rule["title"])}</strong>: {String(rule["rule_text"])}
                            </li>
                            for rule in patchRules
                        ]}
                    </ul>
                    <pre>{String(patchDetail["diff_text"] || "")}</pre>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Baseline Comparison</h2>
                    <h3>Raw Baseline</h3>
                    <p>{String(comparison["baseline"]["diagnosis"] || "")}</p>
                    <p>Specificity: {String(comparison["baseline"]["specificity"] || "")}</p>
                    <pre>{String(comparison["baseline"]["compressed_trajectory"] || "")}</pre>
                </article>

                <article className="panel">
                    <h2>Structured Diagnosis</h2>
                    <p>Failure class: {String(comparison["structured"]["failure_class"] || "UNKNOWN")}</p>
                    <p>Critical step: {String(comparison["structured"]["critical_step_idx"] || -1)}</p>
                    <p>{String(comparison["structured"]["why_better"] || "")}</p>
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

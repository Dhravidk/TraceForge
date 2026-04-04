sv import from traceforge.api {
    AnalyzeBatch,
    CompareBaseline,
    CompileMemoryPatch,
    GetBatchOverview,
    GetClusterView,
    GetRunView
}

cl {
    def:pub app() -> JsxElement {
        has status: str = "Booting TraceForge...";
        has loading: bool = True;
        has overview: any = {};
        has runDetail: any = {};
        has clusterDetail: any = {};
        has patchDetail: any = {};
        has comparison: any = {};

        async can with entry {
            analyze = root spawn AnalyzeBatch(batch_id="sample-starter");
            if analyze.reports {
                status = String(analyze.reports[0]["message"]);
            }

            overview_result = root spawn GetBatchOverview(batch_id="sample-starter");
            if overview_result.reports {
                overview = overview_result.reports[0];
            }

            if overview["runs"] && overview["runs"].length > 0 {
                first_run_id = String(overview["runs"][0]["run_id"]);
                run_result = root spawn GetRunView(run_id=first_run_id);
                if run_result.reports {
                    runDetail = run_result.reports[0];
                }
                compare_result = root spawn CompareBaseline(run_id=first_run_id);
                if compare_result.reports {
                    comparison = compare_result.reports[0];
                }
            }

            if overview["clusters"] && overview["clusters"].length > 0 {
                first_cluster_id = String(overview["clusters"][0]["cluster_id"]);
                cluster_result = root spawn GetClusterView(cluster_id=first_cluster_id);
                if cluster_result.reports {
                    clusterDetail = cluster_result.reports[0];
                }
                patch_result = root spawn CompileMemoryPatch(cluster_id=first_cluster_id);
                if patch_result.reports {
                    patchDetail = patch_result.reports[0];
                }
            }

            status = "Starter batch loaded through graph-backed walkers.";
            loading = False;
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
                    Runs: {String(overview["run_count"] || 0)} | Clusters: {String(overview["cluster_count"] || 0)}
                </p>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Batch Overview</h2>
                    <pre>{JSON.stringify(overview, null, 2)}</pre>
                </article>

                <article className="panel">
                    <h2>Representative Run</h2>
                    <pre>{JSON.stringify(runDetail, null, 2)}</pre>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Representative Cluster</h2>
                    <pre>{JSON.stringify(clusterDetail, null, 2)}</pre>
                </article>

                <article className="panel">
                    <h2>Memory Patch</h2>
                    <pre>{JSON.stringify(patchDetail, null, 2)}</pre>
                </article>
            </section>

            <section className="panels">
                <article className="panel">
                    <h2>Baseline Comparison</h2>
                    <pre>{JSON.stringify(comparison, null, 2)}</pre>
                </article>
            </section>
        </main>;
    }
}

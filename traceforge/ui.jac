sv import from traceforge.api { GetStatus }

cl {
    def:pub app() -> JsxElement {
        has status: str = "Booting TraceForge...";

        async can with entry {
            result = root spawn GetStatus();
            if result.reports {
                status = String(result.reports[0]["message"]);
            }
        }

        return <main className="shell">
            <section className="hero">
                <p className="eyebrow">JacHacks 2026</p>
                <h1>TraceForge</h1>
                <p className="tagline">Batch failure compiler for coding-agent trajectories.</p>
                <p className="status">{status}</p>
            </section>
            <section className="panels">
                <article className="panel">
                    <h2>Current Scope</h2>
                    <ul>
                        <li>Jac-first graph schema</li>
                        <li>Public walker API scaffold</li>
                        <li>Parallel workstream boundaries</li>
                    </ul>
                </article>
                <article className="panel">
                    <h2>Next Milestones</h2>
                    <ul>
                        <li>Load a sample mini-SWE-agent batch</li>
                        <li>Render one run timeline</li>
                        <li>Highlight one critical-step candidate</li>
                    </ul>
                </article>
            </section>
        </main>;
    }
}
